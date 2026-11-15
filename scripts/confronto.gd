extends Node

@export var contra_computador: bool = false

const CENA_RODADA: PackedScene = preload("res://cenas/partida.tscn")

var _rodada: RodadaPartida
var _numero_rodada: int = 1
var _total_jogador1: int = 0
var _total_jogador2: int = 0

var _aguardando_continuacao: bool = false
var _transicao_pendente: bool = false
var _perfil_treino_id: int = 0
var _identificador_treino: String = ""
var _historico_enviado: bool = false

func _ready() -> void:
	_preparar_registro_treino()
	_criar_rodada()

func _criar_rodada() -> void:
	_aguardando_continuacao = false

	_rodada = CENA_RODADA.instantiate() as RodadaPartida
	_rodada.contra_computador = contra_computador
	_rodada.configurar_rodada(_numero_rodada)

	_rodada.rodada_encerrada.connect(_ao_encerrar_rodada)
	_rodada.continuacao_solicitada.connect(_solicitar_avanco)

	_rodada.menu_solicitado.connect(_solicitar_menu)
	add_child(_rodada)

	_rodada.mostrar_contexto(
		_numero_rodada,
		_total_jogador1,
		_total_jogador2
	)


func _ao_encerrar_rodada(pontos1: int, pontos2: int) -> void:
	if _aguardando_continuacao:
		return

	_total_jogador1 += pontos1
	_total_jogador2 += pontos2
	_aguardando_continuacao = true

	_rodada.mostrar_contexto(
		_numero_rodada,
		_total_jogador1,
		_total_jogador2
	)

	if _numero_rodada == 1:
		_rodada.apresentar_resultado(
			"Rodada 1 encerrada! O jogador 2 começa a próxima.",
			"Próxima rodada"
		)
		return
	_registrar_resultado_treino()
	var resultado: String = "A partida terminou empatada!"

	if _total_jogador1 > _total_jogador2:
		resultado = "Jogador 1 venceu a partida!"
	elif _total_jogador2 > _total_jogador1:
		resultado = "Jogador 2 venceu a partida!"

	_rodada.apresentar_resultado(
		resultado,
		"Jogar novamente",
		true
	)


func _solicitar_avanco() -> void:
	if not _aguardando_continuacao or _transicao_pendente:
		return

	_transicao_pendente = true
	_avancar.call_deferred()


func _avancar() -> void:
	remove_child(_rodada)
	_rodada.queue_free()

	if _numero_rodada == 1:
		_numero_rodada = 2
	else:
		_numero_rodada = 1
		_total_jogador1 = 0
		_total_jogador2 = 0

		_preparar_registro_treino()

	_criar_rodada()
	_transicao_pendente = false

func _solicitar_menu() -> void:
	if not _aguardando_continuacao or _transicao_pendente:
		return

	if _numero_rodada != 2:
		return

	_transicao_pendente = true
	_voltar_ao_menu.call_deferred()


func _voltar_ao_menu() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/menu_inicial.tscn"
	)

	if erro != OK:
		_transicao_pendente = false
		push_error("Falha ao abrir o menu: %s" % error_string(erro))

func _preparar_registro_treino() -> void:
	_perfil_treino_id = 0
	_identificador_treino = ""
	_historico_enviado = false

	if not contra_computador:
		return

	_identificador_treino = HistoricoTreinos.gerar_identificador()

	var configuracao: ConfigFile = ConfigFile.new()
	var erro: Error = configuracao.load("user://perfil.cfg")

	if erro != OK:
		push_warning(
			"Treino sem perfil salvo: o resultado não será enviado."
		)
		return

	_perfil_treino_id = int(
		configuracao.get_value("jogador", "id", 0)
	)


func _registrar_resultado_treino() -> void:
	if not contra_computador or _historico_enviado:
		return

	_historico_enviado = true

	HistoricoTreinos.salvar_treino(
		_identificador_treino,
		_perfil_treino_id,
		_total_jogador1,
		_total_jogador2
	)
