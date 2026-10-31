"""Compara dumps CPS2 de 64 KiB sem alterar as fontes. Python 3.10+, sem pacotes."""
import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

SIZE = 0x10000
BASE = 0xFF0000


def load_dump(path):
    data = Path(path).read_bytes()
    if len(data) != SIZE:
        raise ValueError(f"{path}: esperado {SIZE} bytes, encontrado {len(data)}")
    return data


def source_info(path, data):
    return {"path": str(Path(path).resolve()), "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest()}


def changed_offsets(before, after):
    if len(before) != len(after):
        raise ValueError("Dumps com tamanhos diferentes")
    return [i for i, (a, b) in enumerate(zip(before, after)) if a != b]


def validate_csv(path, before, after, base):
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != ["Endereco", "Antes", "Depois"]:
            raise ValueError(f"{path}: cabeçalho incompatível")
        actual = []
        for row in reader:
            if None in row or any(value is None for value in row.values()):
                raise ValueError(f"{path}: linha CSV com campos ausentes ou excedentes")
            actual.append((int(row["Endereco"], 16), int(row["Antes"], 16), int(row["Depois"], 16)))
    expected = [(base + i, before[i], after[i]) for i in changed_offsets(before, after)]
    if actual != expected:
        raise ValueError(f"{path}: diferenças, ordem ou valores não conferem com os dumps")
    return len(actual)


def write_csv(path, fields, rows):
    with Path(path).open("x", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def comparison(before, after, base=BASE, control=None):
    if base < 0 or len(before) != SIZE or len(after) != SIZE:
        raise ValueError("Base negativa ou dump diferente de 64 KiB")
    if control is not None and len(control) != SIZE:
        raise ValueError("Controle diferente de 64 KiB")
    raw = changed_offsets(before, after)
    control_changes = changed_offsets(before, control) if control is not None else []
    selected = sorted(set(raw) | set(control_changes))
    byte_rows, word_rows, pointer_rows = [], [], []
    for i in selected:
        byte_rows.append({"endereco": f"0x{base+i:06X}", "offset": f"0x{i:04X}",
                          "antes": f"0x{before[i]:02X}", "depois": f"0x{after[i]:02X}",
                          "delta": after[i]-before[i],
                          "controle_depois": "" if control is None else f"0x{control[i]:02X}",
                          "mudou_acao": int(before[i] != after[i]),
                          "mudou_controle": "" if control is None else int(before[i] != control[i]),
                          "difere_do_controle": "" if control is None else int(after[i] != control[i])})
    for i in sorted({offset & ~1 for offset in selected}):
        a, b = (int.from_bytes(buf[i:i+2], "big") for buf in (before, after))
        sa, sb = (int.from_bytes(buf[i:i+2], "big", signed=True) for buf in (before, after))
        word_rows.append({"endereco": f"0x{base+i:06X}", "antes_hex": f"0x{a:04X}",
                          "depois_hex": f"0x{b:04X}", "antes_u16be": a, "depois_u16be": b,
                          "delta_u16be": b-a, "antes_s16be": sa, "depois_s16be": sb,
                          "delta_s16be": sb-sa,
                          "controle_u16be": "" if control is None else int.from_bytes(control[i:i+2], "big"),
                          "difere_do_controle": "" if control is None else int(after[i:i+2] != control[i:i+2])})
    # Ponteiros 68000 podem começar em qualquer endereço par, inclusive par não múltiplo de 4.
    selected_set = set(selected)
    for i in range(0, SIZE-3, 2):
        if not selected_set.intersection(range(i, i+4)):
            continue
        a, b = (int.from_bytes(buf[i:i+4], "big") for buf in (before, after))
        if base <= a < base+SIZE or base <= b < base+SIZE:
            pointer_rows.append({"endereco": f"0x{base+i:06X}", "antes_u32be": f"0x{a:08X}",
                                 "depois_u32be": f"0x{b:08X}", "delta": b-a})
    summary = {"base": f"0x{base:06X}", "bytes_por_dump": SIZE,
               "bytes_alterados_acao": len(raw), "palavras_alteradas_acao": len({i//2 for i in raw}),
               "percentual_alterado_acao": 100*len(raw)/SIZE,
               "paginas_256_bytes": {f"0x{base+p*256:06X}": count
                                      for p, count in sorted(Counter(i//256 for i in raw).items())},
               "zero_para_nao_zero": sum(before[i] == 0 for i in raw),
               "nao_zero_para_zero": sum(after[i] == 0 for i in raw),
               "controle_disponivel": control is not None,
               "bytes_alterados_controle": None if control is None else len(control_changes),
               "bytes_diferentes_do_controle": None if control is None else len(changed_offsets(control, after)),
               "interpretacao": "Diferença entre endpoints; não comprova função de coordenada."}
    return summary, byte_rows, word_rows, pointer_rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("antes", type=Path)
    parser.add_argument("depois", type=Path)
    parser.add_argument("--out", type=Path, required=True, help="Diretório NOVO de resultados")
    parser.add_argument("--base", type=lambda value: int(value, 0), default=BASE)
    parser.add_argument("--validar-csv", type=Path)
    parser.add_argument("--controle-depois", type=Path,
                        help="Endpoint sem entrada, do MESMO estado inicial e mesmo número de quadros")
    args = parser.parse_args()
    try:
        before, after = load_dump(args.antes), load_dump(args.depois)
        control = load_dump(args.controle_depois) if args.controle_depois else None
        summary, bytes_, words, pointers = comparison(before, after, args.base, control)
        summary["fontes"] = [source_info(args.antes, before), source_info(args.depois, after)]
        if control is not None:
            summary["fonte_controle"] = source_info(args.controle_depois, control)
        summary["csv_original_linhas_validadas"] = (
            validate_csv(args.validar_csv, before, after, args.base) if args.validar_csv else None)
        args.out.mkdir(parents=True, exist_ok=False)
        write_csv(args.out/"bytes.csv", ["endereco", "offset", "antes", "depois", "delta", "controle_depois",
                                        "mudou_acao", "mudou_controle", "difere_do_controle"], bytes_)
        write_csv(args.out/"palavras_16be.csv", ["endereco", "antes_hex", "depois_hex", "antes_u16be",
                  "depois_u16be", "delta_u16be", "antes_s16be", "depois_s16be", "delta_s16be",
                  "controle_u16be", "difere_do_controle"], words)
        write_csv(args.out/"ponteiros_candidatos.csv", ["endereco", "antes_u32be", "depois_u32be", "delta"], pointers)
        with (args.out/"resumo.json").open("x", encoding="utf-8") as stream:
            json.dump(summary, stream, ensure_ascii=False, indent=2)
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    except (OSError, ValueError, TypeError, KeyError, csv.Error) as error:
        parser.exit(1, f"Erro: {error}\n")


if __name__ == "__main__":
    main()
