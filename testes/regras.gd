extends Node

var falhas: int = 0
var verificacoes: int = 0
var rodada: RodadaPartida

func conferir(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		push_error(descricao)

func _ready() -> void:
	run.call_deferred()

func nova_rodada(computador: bool = false) -> void:
	if is_instance_valid(rodada):
		get_tree().root.remove_child(rodada)
		rodada.queue_free()
	rodada = load("res://cenas/partida.tscn").instantiate()
	rodada.contra_computador = computador
	rodada.sons_locais_ativos = false
	rodada.efeitos_pontos_locais_ativos = false
	get_tree().root.add_child(rodada)
	rodada.process_mode = Node.PROCESS_MODE_DISABLED

func pontuar(nome: String) -> void:
	rodada.get_node(nome).global_position = Vector2(1000, 360)

func run() -> void:
	nova_rodada()
	var seletor: SeletorPosicao = rodada.seletor
	var area: Rect2 = rodada.arena.obter_area_inicial()
	var centro: Vector2 = rodada.campo.obter_centro_global()
	var vazios: Array[Bolinha] = []
	conferir(seletor.posicao_permitida(Vector2(1040, 360), centro, 12, area, vazios), "Entrada atrás da linha")
	conferir(not seletor.posicao_permitida(Vector2(999, 360), centro, 12, area, vazios), "Recusa à esquerda da linha")
	conferir(not seletor.posicao_permitida(Vector2(1010, 360), centro, 12, area, vazios), "Bolinha inteira deve estar atrás")
	conferir(not seletor.posicao_permitida(Vector2(-1, 600), centro, 12, area, vazios), "Recusa fora da arena")
	conferir(not seletor.posicao_permitida(Vector2(INF, 600), centro, 12, area, vazios), "Recusa coordenada inválida")
	var bola: Bolinha = rodada.jogadores[0].bolinha
	bola.entrar_em_campo(Vector2(1040, 360))
	vazios.append(bola)
	conferir(not seletor.posicao_permitida(Vector2(1040, 360), centro, 12, area, vazios), "Recusa sobreposição")
	bola.aguardar_entrada()
	bola.aguardar_entrada()
	bola.entrar_em_campo(Vector2(1040, 360))
	conferir(bola.collision_layer != 0 and bola.collision_mask != 0, "Reentrada preserva colisões")
	conferir(bola.visible and bola.get_node("Arte").visible, "Arte visível após reentrada")
	# Sem pontos: troca, sem reposicionar quem parou fora.
	bola.global_position = Vector2(900, 360)
	rodada.finalizar_jogada()
	conferir(rodada.indice_jogador_atual == 1, "Sem pontos passa a vez")
	conferir(bola.em_campo and bola.global_position == Vector2(900, 360), "Continua de onde parou fora")
	# Pontuar fora dá uma extra, nunca uma terceira.
	nova_rodada()
	bola = rodada.jogadores[0].bolinha
	bola.entrar_em_campo(Vector2(900, 360))
	pontuar("BolinhaAlvo1")
	rodada.finalizar_jogada()
	conferir(rodada.indice_jogador_atual == 0 and rodada.tacadas_no_turno == 1, "Pontuar fora permite extra")
	pontuar("BolinhaAlvo2")
	rodada.finalizar_jogada()
	conferir(rodada.indice_jogador_atual == 1 and rodada.tacadas_no_turno == 0, "Segunda tacada sempre encerra turno")
	conferir(rodada.jogadores[0].obter_pontos() == 2, "Soma das duas tacadas")
	# Dentro: perde turno mesmo com pontos; só o autor da tacada é penalizado.
	nova_rodada()
	bola = rodada.jogadores[0].bolinha
	bola.entrar_em_campo(centro)
	pontuar("BolinhaAlvo1")
	rodada.finalizar_jogada()
	conferir(rodada.indice_jogador_atual == 1 and not bola.em_campo, "Dentro com ponto encerra e retira bolinha")
	conferir(rodada.jogadores[0].obter_pontos() == 1, "Pontos mantidos na penalidade")
	conferir(not rodada.aviso_jogada.is_empty(), "Penalidade informada")
	rodada.jogadores[1].bolinha.entrar_em_campo(Vector2(900, 360))
	rodada.finalizar_jogada()
	conferir(rodada.indice_jogador_atual == 0 and rodada.seletor.ativo, "Próximo turno exige linha após penalidade")
	conferir(rodada.campo.centro_esta_no_circulo(centro + Vector2(140, 0)), "Centro na borda conta como dentro")
	conferir(not rodada.campo.centro_esta_no_circulo(centro + Vector2(140.1, 0)), "Centro fora não recebe penalidade")
	# IA usa o mesmo validador.
	nova_rodada(true)
	rodada.indice_jogador_atual = 1
	rodada._jogar_computador()
	bola = rodada.jogadores[1].bolinha
	conferir(bola.em_campo and bola.global_position.x >= 1012, "Computador posiciona atrás da linha")
	bola.global_position = centro
	rodada.finalizar_jogada()
	conferir(not bola.em_campo, "Computador também recebe penalidade")
	# HUD acumula e reinicia sem duplicar pontos ao encerrar rodada.
	rodada.queue_free()
	rodada = null
	var confronto: Node = load("res://cenas/confronto.tscn").instantiate()
	get_tree().root.add_child(confronto)
	confronto.process_mode = Node.PROCESS_MODE_DISABLED
	var r: RodadaPartida = confronto._rodada
	r.jogadores[0].adicionar_pontos(12)
	r.jogadores[1].adicionar_pontos(7)
	r.atualizar_placar()
	r.encerrar_partida()
	var placar: Label = r.interface.get_node("HUD/TextoPontuacao")
	conferir(placar.text.contains("12  ×  7"), "Fim da rodada não duplica placar")
	confronto._avancar()
	r = confronto._rodada
	r.jogadores[0].adicionar_pontos(8)
	r.jogadores[1].adicionar_pontos(11)
	r.atualizar_placar()
	placar = r.interface.get_node("HUD/TextoPontuacao")
	conferir(placar.text.contains("20  ×  18"), "Segunda rodada soma à primeira")
	r.encerrar_partida()
	conferir(placar.text.contains("20  ×  18"), "Fim mantém total 20 por 18")
	conferir(confronto._total_jogador1 == 20 and confronto._total_jogador2 == 18, "Total usado pelo histórico preservado")
	confronto._avancar()
	conferir(confronto._rodada.interface.get_node("HUD/TextoPontuacao").text.contains("0  ×  0"), "Revanche zera placar")
	confronto.queue_free()
	# Menus e instruções abrem sem nós faltantes.
	for caminho in ["menu_inicial", "menu_opcoes", "menu_jogar", "instrucoes", "partida_online"]:
		var cena: Node = load("res://cenas/%s.tscn" % caminho).instantiate()
		get_tree().root.add_child(cena)
		cena.queue_free()
	await get_tree().process_frame
	print("VERIFICAÇÕES: %d | FALHAS: %d" % [verificacoes, falhas])
	get_tree().quit(1 if falhas > 0 else 0)
