extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var rodada: RodadaPartida = load("res://cenas/partida.tscn").instantiate()
	rodada.sons_locais_ativos = false
	get_tree().root.add_child(rodada)
	rodada._confirmar_posicao_inicial(Vector2(640, 610))
	rodada.seletor.ativo = false
	rodada.seletor.hide()
	var bola: Bolinha = rodada.jogadores[0].bolinha
	var origem: Vector2 = bola.global_position
	var sucesso: bool = rodada.executar_tacada(Vector2.UP, 0.75)
	var quadros: int = 0
	while rodada.jogada_em_andamento and quadros < 1500:
		await get_tree().physics_frame
		quadros += 1
	var deslocou: bool = bola.global_position.distance_to(origem) > 10
	var terminou: bool = not rodada.jogada_em_andamento
	print("FÍSICA: iniciou=%s deslocou=%s terminou=%s quadros=%d" % [sucesso, deslocou, terminou, quadros])
	rodada.queue_free()
	rodada = null
	bola = null
	await get_tree().create_timer(0.6).timeout
	get_tree().quit(0 if sucesso and deslocou and terminou else 1)
