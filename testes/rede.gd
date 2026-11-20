extends Node

var anfitriao: bool = false
var etapa: int = 0
var tempo: float = 0.0
var etapa_tempo: float = 0.0
var iniciou: bool = false

func _ready() -> void:
	iniciar.call_deferred()

func iniciar() -> void:
	get_tree().current_scene = null # O verificador acompanha a troca para a cena online.
	anfitriao = OS.get_cmdline_user_args().has("host")
	var erro: Error
	if anfitriao:
		erro = RedeSala.criar(17891)
	else:
		erro = RedeSala.entrar("127.0.0.1", 17891)
	if erro != OK:
		push_error("Falha ao iniciar ENet local: %s" % error_string(erro))
		get_tree().quit(1)
	iniciou = true

func _process(delta: float) -> void:
	if not iniciou:
		return
	tempo += delta
	etapa_tempo += delta
	if tempo > 15:
		push_error("Tempo esgotado no teste de rede, etapa %d" % etapa)
		get_tree().quit(1)
		return
	if anfitriao and etapa == 2 and etapa_tempo > 1:
		print("REDE HOST: penalidade e reentrada publicadas")
		get_tree().quit()
		return
	if not RedeSala.partida_em_abertura:
		if RedeSala.participantes.size() == 2 and RedeSala.participantes.has(RedeSala.meu_id()):
			if not RedeSala.participantes[RedeSala.meu_id()]:
				RedeSala.marcar_pronto()
		return
	var online: Node = get_tree().current_scene
	if online == null or not online.is_node_ready() or not online._conectados():
		return
	var rodada: RodadaPartida = online.rodada
	var bola: Bolinha = rodada.jogadores[0].bolinha
	if anfitriao:
		if etapa == 0 and tempo > 2:
			bola.entrar_em_campo(Vector2(640, 360))
			rodada.finalizar_jogada()
			online._atualizar()
			online._publicar(true)
			etapa = 1
			etapa_tempo = 0
		elif etapa == 1 and etapa_tempo > 1:
			bola.entrar_em_campo(Vector2(640, 610))
			rodada.aviso_jogada = ""
			online._totais.assign([12, 7])
			rodada.jogadores[0].adicionar_pontos(8)
			rodada.jogadores[1].adicionar_pontos(11)
			online._atualizar()
			online._publicar(true)
			etapa = 2
			etapa_tempo = 0
		elif etapa == 2 and etapa_tempo > 1:
			print("REDE HOST: penalidade e reentrada publicadas")
			get_tree().quit()
	else:
		if etapa == 0 and not rodada.aviso_jogada.is_empty():
			if bola.em_campo or bola.visible or rodada.indice_jogador_atual != 1:
				push_error("Convidado não recebeu a penalidade corretamente")
				get_tree().quit(1)
			print("REDE CLIENTE: penalidade recebida e bolinha oculta")
			etapa = 1
		elif etapa == 1 and bola.em_campo:
			if not bola.visible or not bola.get_node("Arte").visible or not online.get_node("InterfaceOnline/HUD/Total").text.contains("20  ×  18"):
				push_error("Convidado não recebeu arte/placar na reentrada")
				get_tree().quit(1)
			else:
				print("REDE CLIENTE: arte reaparece e placar geral é 20 x 18")
				get_tree().quit()
