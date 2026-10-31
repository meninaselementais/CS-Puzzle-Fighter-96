# Projeto no GitHub

Estado importado: apresentação V9 do Phoenix, sobre o protótipo local SAS vs Phoenix.
O README.md principal preserva as instruções históricas da V4; consulte também
README_FIDELIDADE_V5.md e README_ANIMACOES_V8.md para as etapas seguintes.

## Abrir uma cópia clonada

Abra godot/project.godot no Godot 4.7.2 e execute a cena principal.
O projeto usa o renderizador Compatibility. O laboratório visual está em
godot/animation_showcase.tscn; F4 alterna entre ele e a partida.

Os launchers Jogar.cmd e Animation_Showcase.cmd esperam uma instalação local em
ferramentas/godot_4.7.2/. Essa instalação não faz parte do repositório.

## Conteúdo preservado apenas no computador

- Original/: pacote original e possíveis arquivos de terceiros.
- ferramentas/: executáveis e ferramentas locais.
- laboratorio/: capturas, dumps e sessões do MAME.
- revisoes/: backups anteriores ao Git.
- Vídeos, imagens e dumps gerados em relatorios/; os relatórios Markdown e os
  resumos summary.json estão versionados.

As fontes do jogo, sprites utilizados, arte V9, fixtures JSON, scripts e testes
estão versionados. Nenhum desses diretórios locais é apagado pela configuração.
Ensaios que dependem das capturas MAME precisam dos arquivos locais excluídos.

## Verificação

Com Python 3.11 ou superior, na raiz:

```powershell
python -B -m unittest discover -s tests -v
```

Para a bateria Godot existente, coloque o executável console no caminho esperado
em ferramentas/godot_4.7.2/ e execute:

```powershell
python -B scripts/validar_apresentacao.py --render
```
