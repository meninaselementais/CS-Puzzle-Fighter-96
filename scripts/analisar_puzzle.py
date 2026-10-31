"""Extrai hipóteses de campos, ponteiros e grades do spf2tu; não escreve no MAME."""
import argparse
import json
from pathlib import Path

from comparar_memoria import BASE, load_dump, source_info, write_csv

BOARDS = (("A", 0xFFAB00), ("B", 0xFFAD00))
# shortcut: mapa inferido dos dumps spf2tu; validar por ação isolada antes de usar em outras versões.
SCALARS = (0xFF8488, 0xFF84F4, 0xFF84F6, 0xFF8542, 0xFF84A6, 0xFF8452, 0xFF8640)
POINTERS = (0xFF8512, 0xFF8516, 0xFF851A, 0xFF851E, 0xFF8522, 0xFF8526)


def number(data, address, size=2, signed=False):
    offset = address-BASE
    if offset < 0 or offset+size > len(data):
        raise ValueError(f"Endereço fora do dump: 0x{address:X}")
    return int.from_bytes(data[offset:offset+size], "big", signed=signed)


def grid(data, base):
    rows = [[number(data, base+row*0x10+slot*2) for slot in range(8)] for row in range(15)]
    valid = all(row[0] == row[7] == 0xFF for row in rows[:14]) and rows[14] == [0xFF]*8
    return rows, valid


def cell_for_pointer(pointer, base):
    offset = pointer-base
    row, remainder = divmod(offset, 0x10)
    if offset < 0 or not 0 <= row < 14 or remainder % 2 or not 2 <= remainder <= 12:
        return None
    return {"linha_hipotetica": row, "coluna_hipotetica": remainder//2-1}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dumps", type=Path, nargs="+")
    parser.add_argument("--out", type=Path, required=True, help="Diretório NOVO de resultados")
    args = parser.parse_args()
    try:
        sources = [(path, load_dump(path)) for path in args.dumps]
        fields, pointers, cells, inventory = [], [], [], []
        text = ["# Grades candidatas — valores brutos", "",
                "Linhas 0–13 e colunas 0–5 são convenções desta hipótese. A/B ainda não confirmam P1/P2.", ""]
        for path, data in sources:
            inventory.append(source_info(path, data))
            text += [f"## {path.name}", ""]
            for group, shift in (("A?", 0), ("B?", 0x400)):
                for address in SCALARS:
                    current = address+shift
                    value = number(data, current)
                    fields.append({"arquivo": str(path.resolve()), "grupo_hipotetico": group,
                                   "endereco": f"0x{current:06X}", "hex": f"0x{value:04X}",
                                   "u16be": value, "s16be": number(data, current, signed=True)})
                for address in POINTERS:
                    current = address+shift
                    value = number(data, current, 4)
                    projection = next(((name, base, cell_for_pointer(value, base)) for name, base in BOARDS
                                       if cell_for_pointer(value, base) is not None), None)
                    pointers.append({"arquivo": str(path.resolve()), "endereco": f"0x{current:06X}",
                                     "u32be": f"0x{value:08X}",
                                     "grade_hipotetica": "" if projection is None else projection[0],
                                     "linha_hipotetica": "" if projection is None else projection[2]["linha_hipotetica"],
                                     "coluna_hipotetica": "" if projection is None else projection[2]["coluna_hipotetica"]})
            for name, base in BOARDS:
                rows, valid = grid(data, base)
                text += [f"Grade {name} @ 0x{base:06X}; bordas/piso válidos: {valid}", "", "```text",
                         "     x0   x1   x2   x3   x4   x5"]
                for row, values in enumerate(rows[:14]):
                    text.append(f"y{row:02d} " + " ".join(f"{value:04X}" for value in values[1:7]))
                    for column, value in enumerate(values[1:7]):
                        address = base+row*0x10+2*(column+1)
                        cells.append({"arquivo": str(path.resolve()), "grade_hipotetica": name,
                                      "bordas_validas": valid, "linha": row, "coluna": column,
                                      "endereco": f"0x{address:06X}", "valor": value})
                text += ["```", ""]
        args.out.mkdir(parents=True, exist_ok=False)
        write_csv(args.out/"campos.csv", ["arquivo", "grupo_hipotetico", "endereco", "hex", "u16be", "s16be"], fields)
        write_csv(args.out/"ponteiros.csv", ["arquivo", "endereco", "u32be", "grade_hipotetica",
                                          "linha_hipotetica", "coluna_hipotetica"], pointers)
        write_csv(args.out/"celulas.csv", ["arquivo", "grade_hipotetica", "bordas_validas", "linha", "coluna", "endereco", "valor"], cells)
        with (args.out/"grades.md").open("x", encoding="utf-8") as stream:
            stream.write("\n".join(text))
        with (args.out/"fontes.json").open("x", encoding="utf-8") as stream:
            json.dump(inventory, stream, ensure_ascii=False, indent=2)
        print(f"{len(sources)} dumps analisados em {args.out}")
    except (OSError, ValueError) as error:
        parser.exit(1, f"Erro: {error}\n")


if __name__ == "__main__":
    main()
