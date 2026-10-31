import json,struct,sys,tempfile,unittest
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from exportar_fidelidade import profiles,rng_samples,valid


class FidelityTests(unittest.TestCase):
    def test_rng_trace_survives_native_line_wrapping(self):
        text='GLOBAL_IN,FF8000,FF8300,57\n85GLOBAL_OUT,FF8000,FF8300,68B'
        self.assertEqual(rng_samples(text),[{'piece':False,'input':0x5785,'expected':0x068b}])

    def test_incomplete_or_reordered_rng_trace_is_rejected(self):
        for text in ['', 'GLOBAL_IN,FF8000,FF8300,1234','GLOBAL_OUT,FF8000,FF8300,1234GLOBAL_IN,FF8000,FF8300,2345']:
            with self.assertRaises(ValueError):rng_samples(text)

    def test_profiles_decode_palette_and_validate_permutations(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)
            (p/'execucao.json').write_text(json.dumps({'fontes_preservadas':True,'lua_concluiu':True,'lua_sem_erros':True}))
            raw=bytearray(0xaf0)
            for i in range(8):raw[i*8:i*8+6]=bytes([0,2,4,6,8,10])
            struct.pack_into('>8H',raw,0x10178-0xff98,0x4000,0x1000,0x2000,0x3000,0x4000,0x1000,0x2000,0x3000)
            for c in range(11):
                struct.pack_into('>H',raw,0x10160-0xff98+c*2,0x0507)
                for r in range(12):struct.pack_into('>6H',raw,0x10188-0xff98+c*192+r*16,1,2,3,4,1,2)
            (p/'attack_tables.bin').write_bytes(raw)
            result=profiles(p)
            self.assertEqual(result['patterns'][10][11],[1,2,3,4,1,2])
            self.assertEqual(result['counter_start'],[5]*11)
            raw[1]=0;(p/'attack_tables.bin').write_bytes(raw)
            with self.assertRaises(ValueError):profiles(p)

    def test_invalid_session_cannot_supply_reference_data(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory);(p/'execucao.json').write_text('{"lua_concluiu":true}')
            with self.assertRaises(ValueError):valid(p)


if __name__=='__main__':unittest.main()
