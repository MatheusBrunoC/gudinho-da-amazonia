extends Node

@export var contra_computador: bool = false

const CENA_RODADA: PackedScene = preload("res://cenas/partida.tscn")

var _rodada: RodadaPartida
var _numero_rodada: int = 1
var _total_jogador1: int = 0
var _total_jogador2: int = 0

var _aguardando_continuacao: bool = false
var _transicao_pendente: bool = false
var _cabecalhos_treino: PackedStringArray = PackedStringArray()
var _identificador_treino: String = ""
var _historico_enviado: bool = false

var _mensagem_historico: String = ""
var _dialogo_desistencia: ConfirmationDialog
var _confirmando_desistencia: bool = false

func _ready() -> void:
	if contra_computador:
		HistoricoTreinos.estado_atualizado.connect(
			_ao_atualizar_estado_historico
		)
		_criar_dialogo_desistencia()

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
	
	_rodada.interface.permitir_desistencia(contra_computador)
	_rodada.interface.mostrar_estado_historico(
		_mensagem_historico
	)

func _ao_encerrar_rodada(pontos1: int, pontos2: int) -> void:
	if _aguardando_continuacao:
		return

	_total_jogador1 += pontos1
	_total_jogador2 += pontos2
	_aguardando_continuacao = true

	# O HUD já soma a rodada atual à base anterior.

	if _numero_rodada == 1:
		_rodada.apresentar_resultado(
			"Rodada 1 encerrada! %s começa a próxima." % _rodada.jogadores[1].nome,
			"Próxima rodada"
		)
		return
	_registrar_resultado_treino()
	var resultado: String = "A partida terminou empatada!"

	if _total_jogador1 > _total_jogador2:
		resultado = "%s venceu a partida!" % _rodada.jogadores[0].nome
	elif _total_jogador2 > _total_jogador1:
		resultado = "%s venceu a partida!" % _rodada.jogadores[1].nome

	_rodada.apresentar_resultado(
		resultado,
		"Jogar novamente",
		true
	)


func _solicitar_avanco() -> void:
	if (
		not _aguardando_continuacao
		or _transicao_pendente
		or _confirmando_desistencia
	):
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
	if _transicao_pendente or _confirmando_desistencia:
		return

	var confronto_concluido: bool = (
		_numero_rodada == 2 and _aguardando_continuacao
	)

	if confronto_concluido:
		_transicao_pendente = true
		_voltar_ao_menu.call_deferred()
		return

	if not contra_computador:
		return

	_confirmando_desistencia = true

	# Cancela uma carga em andamento e bloqueia novas ações.
	_rodada.carregando = false
	_rodada.carga = 0.0
	_rodada.interface.atualizar_forca(0.0)
	_rodada.mira.hide()

	_rodada.set_process(false)
	_rodada.set_process_unhandled_input(false)

	_dialogo_desistencia.popup_centered(Vector2i(480, 180))
	
func _voltar_ao_menu() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/menu_inicial.tscn"
	)

	if erro != OK:
		_transicao_pendente = false
		push_error("Falha ao abrir o menu: %s" % error_string(erro))
		_restaurar_controle_rodada()
		
func _preparar_registro_treino() -> void:
	_mensagem_historico = ""
	_cabecalhos_treino = PackedStringArray()
	_identificador_treino = ""
	_historico_enviado = false

	if not contra_computador:
		return

	_identificador_treino = HistoricoTreinos.gerar_identificador()

	if not SessaoJogador.possui_sessao():
		push_warning(
			"Treino iniciado sem login. "
			+ "Este confronto não será salvo no histórico."
		)
		_mensagem_historico = (
			"Treino sem conta — resultado não será salvo."
		)
		return

	_cabecalhos_treino = (
		SessaoJogador.obter_cabecalhos().duplicate()
	)
	
	var perfil: Dictionary = SessaoJogador.obter_perfil()

	_mensagem_historico = "Histórico vinculado a %s." % str(
		perfil.get("apelido", "jogador")
	)


func _registrar_resultado_treino() -> void:
	if not contra_computador or _historico_enviado:
		return

	_historico_enviado = true

	HistoricoTreinos.salvar_treino(
		_identificador_treino,
		_cabecalhos_treino,
		_total_jogador1,
		_total_jogador2
	)

func _ao_atualizar_estado_historico(
	identificador: String,
	mensagem: String
) -> void:
	if not contra_computador:
		return

	if identificador != _identificador_treino:
		return

	_mensagem_historico = mensagem

	if is_instance_valid(_rodada):
		_rodada.interface.mostrar_estado_historico(mensagem)

func _criar_dialogo_desistencia() -> void:
	_dialogo_desistencia = ConfirmationDialog.new()
	_dialogo_desistencia.title = "Desistir do treino?"
	_dialogo_desistencia.dialog_text = (
		"O confronto será encerrado sem registrar o resultado.\n"
		+ "Deseja voltar ao menu?"
	)
	_dialogo_desistencia.ok_button_text = "Desistir"
	_dialogo_desistencia.cancel_button_text = "Continuar jogando"

	add_child(_dialogo_desistencia)

	_dialogo_desistencia.confirmed.connect(_confirmar_desistencia)
	_dialogo_desistencia.canceled.connect(_cancelar_desistencia)


func _confirmar_desistencia() -> void:
	if not _confirmando_desistencia:
		return

	_confirmando_desistencia = false
	_transicao_pendente = true
	_voltar_ao_menu.call_deferred()


func _cancelar_desistencia() -> void:
	if not _confirmando_desistencia:
		return

	_confirmando_desistencia = false
	_restaurar_controle_rodada()


func _restaurar_controle_rodada() -> void:
	if is_instance_valid(_rodada):
		_rodada.set_process(true)
		_rodada.set_process_unhandled_input(true)
