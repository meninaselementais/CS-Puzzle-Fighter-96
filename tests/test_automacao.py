import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
from automatizar_mame import copy_verified, sha256
from avaliar_sessao import pixel_color, state


class AutomationTests(unittest.TestCase):
    def test_copy_preserves_source_and_refuses_divergent_target(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=root/'original';target=root/'copia'
            source.write_bytes(b'original')
            result=copy_verified(source,target)
            self.assertEqual(result['sha256'],sha256(target))
            target.write_bytes(b'alterado')
            with self.assertRaises(ValueError):copy_verified(source,target)
            self.assertEqual(source.read_bytes(),b'original')
            self.assertEqual(target.read_bytes(),b'alterado')

    def test_color_recognition_ignores_gray_and_borders(self):
        for rgb,label in [(0xff0000,'red'),(0xffff00,'yellow'),(0x00ff00,'green'),(0x0000ff,'blue'),(0x888888,None)]:
            pixels=struct.pack('<I',rgb)*20*20
            self.assertEqual(pixel_color(pixels,20,20,10,10),label)
            self.assertIsNone(pixel_color(pixels,20,20,0,0))

    def test_invalid_memory_grid_is_rejected(self):
        with self.assertRaises(ValueError):state(bytes(65536),0)

    def test_runner_refuses_original_directory_as_project(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);lua=root/'empty.lua';lua.write_text('',encoding='utf-8')
            runner=Path(__file__).resolve().parents[1]/'scripts/automatizar_mame.py'
            result=subprocess.run([sys.executable,str(runner),'--project',str(root),'--mame',str(root),
                                   '--lua',str(lua)],capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse((root/'laboratorio').exists())


if __name__=='__main__':unittest.main()
