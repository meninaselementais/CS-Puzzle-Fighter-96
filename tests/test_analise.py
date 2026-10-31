import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"scripts"))
from comparar_memoria import BASE, SIZE, comparison, load_dump, validate_csv
from analisar_puzzle import cell_for_pointer, grid, number


class AnalysisTests(unittest.TestCase):
    def test_endian_signed_and_half_aligned_pointer(self):
        before, after = bytearray(SIZE), bytearray(SIZE)
        before[2:6] = bytes.fromhex("00ffabc4")
        after[2:6] = bytes.fromhex("00ffabcc")
        before[10:12] = bytes.fromhex("fff5")
        after[10:12] = bytes.fromhex("fffb")
        summary, _, words, pointers = comparison(before, after)
        self.assertEqual(summary["bytes_alterados_acao"], 2)
        self.assertEqual(next(w for w in words if w["endereco"] == "0xFF000A")["delta_s16be"], 6)
        self.assertIn({"endereco": "0xFF0002", "antes_u32be": "0x00FFABC4",
                       "depois_u32be": "0x00FFABCC", "delta": 8}, pointers)

    def test_control_compares_endpoints_including_different_value_at_same_address(self):
        before, action, control = bytearray(SIZE), bytearray(SIZE), bytearray(SIZE)
        action[0:3] = bytes([1, 2, 0])
        control[0:3] = bytes([1, 3, 4])
        summary, rows, words, _ = comparison(before, action, control=control)
        self.assertEqual(summary["bytes_alterados_acao"], 2)
        self.assertEqual(summary["bytes_diferentes_do_controle"], 2)
        self.assertEqual([r["difere_do_controle"] for r in rows], [0, 1, 1])
        self.assertEqual(words[0]["difere_do_controle"], 1)

    def test_board_layout_coordinates_and_invalid_border(self):
        data = bytearray(SIZE)
        for row in range(15):
            for slot in range(8):
                if slot in (0, 7) or row == 14:
                    offset=0xAB00+row*16+slot*2
                    data[offset:offset+2] = b"\x00\xff"
        self.assertTrue(grid(data, 0xFFAB00)[1])
        self.assertEqual(cell_for_pointer(0xFFABC4, 0xFFAB00), {"linha_hipotetica": 12, "coluna_hipotetica": 1})
        self.assertEqual(cell_for_pointer(0xFFABCC, 0xFFAB00), {"linha_hipotetica": 12, "coluna_hipotetica": 5})
        for pointer in (0xFFAAFE, 0xFFAB00, 0xFFAB03, 0xFFAB0E, 0xFFABE2):
            self.assertIsNone(cell_for_pointer(pointer, 0xFFAB00))
        data[0xAB01] = 0
        self.assertFalse(grid(data, 0xFFAB00)[1])
        with self.assertRaises(ValueError):
            number(data, BASE-1)

    def test_rejects_bad_size_csv_and_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            small = root/"small.bin"
            small.write_bytes(b"\x00")
            with self.assertRaises(ValueError):
                load_dump(small)
            with self.assertRaises(ValueError):
                comparison(bytes(SIZE), bytes(SIZE-1))
            before, after = bytes(SIZE), bytearray(SIZE)
            after[5] = 8
            csv_path=root/"diff.csv"
            csv_path.write_text('"Endereco","Antes","Depois"\n"0xFF0005","0x00","0x08"\n', encoding="utf-8-sig")
            self.assertEqual(validate_csv(csv_path, before, after, BASE), 1)
            csv_path.write_text('Endereco,Antes,Depois\n0xFF0005,0x00,0x09\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                validate_csv(csv_path, before, after, BASE)
            csv_path.write_text('Endereco,Antes,Depois\n0xFF0005,0x00,0x08,excedente\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                validate_csv(csv_path, before, after, BASE)
            source = root/"source.bin"
            source.write_bytes(before)
            script=Path(__file__).resolve().parents[1]/"scripts"/"comparar_memoria.py"
            result=subprocess.run([sys.executable, str(script), str(source), str(source), "--out", str(root)],
                                  capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(source.read_bytes(), before)
            self.assertFalse((root/"bytes.csv").exists())


if __name__ == "__main__":
    unittest.main()
