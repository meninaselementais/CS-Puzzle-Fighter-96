extends "res://tests/test_match_flow.gd"
## O teste histórico envia Enter 0,1 s após revelar; a cena exige >=0,2 s.
## Aguarda a janela de confirmação real, sem mudar inputs nem código do jogo.
func capture(file_name: String) -> void:
	await super.capture(file_name)
	if file_name.ends_with("_coin_result"):
		await create_timer(0.25).timeout
