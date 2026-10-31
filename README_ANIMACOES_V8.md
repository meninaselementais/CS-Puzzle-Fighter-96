# Animações V8

A V8 melhora a apresentação existente de SAS/Phoenix, mantendo o núcleo e os sprites originais.

- Tiros com recuo, flashes de dois quadros e rajadas progressivas por combo.
- Granadas com preparação, saída na mão, arco parabólico, rotação e fragmentação no impacto.
- Primeiro disparo/arremesso alinhado à destruição visual de cada onda; ataques simultâneos preservados.
- Banners fora das células, tremores curtos e proporções dos personagens preservadas.
- Showcase com ¼×, ½×, 1× e 2×, loop da sequência, catálogo automático, pausa e passo por quadro.

Abra `Jogar.cmd` para jogar ou `Animation_Showcase.cmd` para o laboratório visual. **F4** alterna entre as duas cenas e inicia uma nova partida ao retornar. No Showcase: **Espaço** pausa, **N** avança um quadro, **R** repete, **←/→** selecionam a sequência. Loop repete a sequência; Catálogo avança pelos tópicos.

Validação:

```powershell
python -B scripts\validar_apresentacao.py --render
```

Relatório e evidências: `relatorios/animacoes_v8/RELATORIO.md`, `final/summary.json`, `animacoes_v8.mp4` e `demo_final/`.

A quantidade de desenhos disponíveis continua sendo o limite principal de animação do Phoenix. A sincronização visual da V8 não constitui um porte da cronologia completa CPS-2.
