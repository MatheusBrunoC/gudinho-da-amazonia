extends Node
## O anfitrião executa as regras e a física; o visitante envia intenções.
const CENA_RODADA: PackedScene = preload("res://cenas/partida.tscn")
const INTERVALO_ESTADO: float = 0.05

@onready var _identidade: Label = %Identidade
@onready var _estado: Label = %Estado
@onready var _placar: Label = %Placar
@onready var _forca: ProgressBar = %Forca
@onready var _continuar: Button = %Continuar
@onready var _total: Label = %Total
@onready var _indicador_vez: Label = %IndicadorVez



var rodada: RodadaPartida
var numero_jogador_local: int = 0
var _aguardando_acao: bool = false
var _carregando: bool = false
var _carga: float = 0.0
var _versao_acao: int = 0
var _sequencia: int = 0
var _ultima_sequencia: int = -1
var _tempo_estado: float = 0.0
var _quadros_apos_disparo: int = 0
var _numero_rodada: int = 1
var _totais: Array[int] = [0, 0]
# Identifica cada nova arena, inclusive nas revanches.
var _epoca: int = 1
var _rodada_liberada: bool = false
var _carregados_rodada: Dictionary = {}
var _confirmacoes: Dictionary = {}
var _continuacao_pendente: bool = false
var _transicao_pendente: bool = false

func _ready() -> void:
	%Sair.pressed.connect(_sair)
	_continuar.pressed.connect(_solicitar_continuacao)
	RedeSala.partida_atualizada.connect(_ao_atualizar_sala)
	if not RedeSala.partida_em_abertura:
		_identidade.text = "Abra esta cena pela sala online."
		_estado.text = "Nenhuma partida conectada."
		return
	numero_jogador_local = 1 if RedeSala.meu_id() == 1 else 2
	_identidade.text = "Você é o Jogador %d — %s" % [numero_jogador_local,
		"anfitrião" if numero_jogador_local == 1 else "visitante"]
	_criar_rodada()
	RedeSala.confirmar_cena_carregada.call_deferred()
	_informar_carregamento.call_deferred()

func _criar_rodada() -> void:
	rodada = CENA_RODADA.instantiate() as RodadaPartida
	rodada.sons_locais_ativos = false
	rodada.efeitos_pontos_locais_ativos = false
	rodada.configurar_rodada(_numero_rodada)
	rodada.name = "Rodada"
	rodada.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(rodada)

	if multiplayer.is_server():
		rodada.alvo_recolhido.connect(_ao_alvo_recolhido_online)
		
	rodada.seletor.posicao_confirmada.disconnect(rodada._confirmar_posicao_inicial)
	rodada.seletor.posicao_confirmada.connect(_solicitar_posicao)
	rodada.seletor.process_mode = Node.PROCESS_MODE_ALWAYS
	_desativar_seletor()
	rodada.mira.hide()
	rodada.interface.hide()
	# Somente os corpos do servidor participam da simulação.
	for no in rodada.get_children():
		if no is Bolinha:
			no.process_mode = Node.PROCESS_MODE_ALWAYS
			no.freeze = true

			if multiplayer.is_server():
				no.impacto_detectado.connect(_ao_impacto_online)
	if multiplayer.is_server():
		rodada.arena.process_mode = Node.PROCESS_MODE_ALWAYS
	_atualizar()

func _conectados() -> bool:
	return rodada != null and RedeSala.partida_em_abertura and RedeSala.cenas_carregadas.size() == 2 and _rodada_liberada

func _pode_agir() -> bool:
	return _conectados() and not rodada.partida_encerrada and not rodada.jogada_em_andamento

func _minha_vez() -> bool:
	return _pode_agir() and numero_jogador_local == rodada.indice_jogador_atual + 1

func _ao_atualizar_sala() -> void:
	if rodada != null and not RedeSala.partida_em_abertura:
		for no in rodada.get_children():
			if no is Bolinha:
				no.freeze = true
		_carregando = false
		_carga = 0.0
	_tentar_liberar()
	_atualizar()
	if _conectados() and multiplayer.is_server():
		_publicar(true)

func _atualizar() -> void:
	if rodada == null:
		return
	_atualizar_indicador_vez()
	var pontos1: int = rodada.jogadores[0].obter_pontos()
	var pontos2: int = rodada.jogadores[1].obter_pontos()
	_placar.text = "Rodada %d/2 — J1: %d | J2: %d" % [_numero_rodada, pontos1, pontos2]
	_total.text = "Total acumulado — J1: %d | J2: %d" % [
		_totais[0] + (0 if rodada.partida_encerrada else pontos1),
		_totais[1] + (0 if rodada.partida_encerrada else pontos2)]
	_continuar.visible = _conectados() and rodada.partida_encerrada
	_continuar.disabled = _continuacao_pendente or _confirmacoes.has(RedeSala.meu_id())
	_continuar.text = "Próxima rodada" if _numero_rodada == 1 else "Jogar novamente"
	if not RedeSala.partida_em_abertura:
		_desativar_seletor()
		rodada.mira.hide()
		_estado.text = RedeSala.mensagem + " Volte à sala para tentar novamente."
	elif not _conectados():
		_estado.text = "Aguardando o outro jogador carregar a arena…"
	elif rodada.partida_encerrada:
		_desativar_seletor()
		_estado.text = "Rodada 1 encerrada. O Jogador 2 começa a próxima." if _numero_rodada == 1 else _resultado_confronto()
		if _continuar.disabled:
			_estado.text += "\nVocê confirmou. Aguardando o outro jogador."
		else:
			_estado.text += "\nOs dois jogadores precisam confirmar para continuar."
	elif rodada.jogada_em_andamento:
		_desativar_seletor()
		_estado.text = "Tacada de %s — aguardando as bolinhas pararem…" % rodada.obter_jogador_atual().nome
	elif _aguardando_acao:
		_estado.text = "Aguardando confirmação do anfitrião…"
	else:
		var jogador: JogadorPartida = rodada.obter_jogador_atual()
		if not _minha_vez():
			_desativar_seletor()
			_estado.text = "Vez de %s. Aguarde." % jogador.nome
		elif jogador.bolinha.em_campo:
			_desativar_seletor()
			_estado.text = "Sua vez: mire, segure o botão esquerdo e solte.\nTacadas disponíveis neste turno: %d" % (rodada.MAX_TACADAS_CONSECUTIVAS - rodada.tacadas_no_turno)
		else:
			_estado.text = "Escolha sua posição inicial fora da região proibida e clique.\nVermelho indica uma posição inválida."
			if not rodada.seletor.ativo:
				rodada.seletor.iniciar(rodada.campo.obter_centro_global(), jogador.bolinha,
					_ocupantes(), rodada.arena.obter_area_inicial())

func _process(delta: float) -> void:
	if rodada == null:
		return
	var pode_mirar: bool = _minha_vez() and not _aguardando_acao and rodada.obter_jogador_atual().bolinha.em_campo
	rodada.mira.visible = pode_mirar
	if pode_mirar:
		rodada.atualizar_mira()
		if _carregando:
			_carga = minf(_carga + delta / rodada.TEMPO_CARGA, 1.0)
	else:
		_carregando = false
		_carga = 0.0
	_forca.value = _carga * 100.0

func _physics_process(delta: float) -> void:
	if not _conectados() or not multiplayer.is_server():
		return
	if rodada.jogada_em_andamento:
		_quadros_apos_disparo += 1
		# Deixa o motor aplicar o impulso antes de testar repouso.
		if _quadros_apos_disparo > 2 and rodada.todas_bolinhas_paradas():
			rodada.finalizar_jogada()
			if rodada.partida_encerrada:
				for i in range(2):
					_totais[i] += rodada.jogadores[i].obter_pontos()
			_versao_acao += 1
			_atualizar()
			_publicar(true)
	_tempo_estado += delta
	if _tempo_estado >= INTERVALO_ESTADO:
		_tempo_estado = 0.0
		_publicar(false)

func _desativar_seletor() -> void:
	if rodada != null:
		rodada.seletor.ativo = false
		rodada.seletor.hide()

func _ocupantes() -> Array[Bolinha]:
	var resultado: Array[Bolinha] = []
	for no in rodada.get_children():
		if no is Bolinha and no.em_campo and not no.is_queued_for_deletion():
			resultado.append(no)
	return resultado

func _unhandled_input(event: InputEvent) -> void:
	if not _minha_vez() or _aguardando_acao:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if rodada.seletor.ativo:
			if event.pressed:
				rodada.seletor.confirmar()
			return
		if not rodada.obter_jogador_atual().bolinha.em_campo:
			return
		if event.pressed:
			_carregando = true
			_carga = 0.0
		elif _carregando:
			_carregando = false
			var bolinha: Bolinha = rodada.obter_jogador_atual().bolinha
			_solicitar_tacada(bolinha.global_position.direction_to(rodada.get_global_mouse_position()), _carga)
			_carga = 0.0

func _remetente_pode_agir(id: int, versao: int) -> bool:
	if not multiplayer.is_server() or not _pode_agir() or versao != _versao_acao:
		return false
	if not RedeSala.participantes.has(id):
		return false
	return rodada.indice_jogador_atual == (0 if id == 1 else 1)

func _solicitar_posicao(posicao: Vector2) -> void:
	if not _minha_vez() or _aguardando_acao:
		return
	_aguardando_acao = true
	_desativar_seletor()
	_atualizar()
	if multiplayer.is_server():
		_validar_posicao(1, posicao, _versao_acao)
	else:
		_pedir_posicao.rpc_id(1, posicao, _versao_acao)

@rpc("any_peer", "call_remote", "reliable")
func _pedir_posicao(posicao: Vector2, versao: int) -> void:
	if multiplayer.is_server():
		_validar_posicao(multiplayer.get_remote_sender_id(), posicao, versao)

func _validar_posicao(id: int, posicao: Vector2, versao: int) -> void:
	if not _remetente_pode_agir(id, versao):
		_recusar(id)
		return
	var bolinha: Bolinha = rodada.obter_jogador_atual().bolinha
	if bolinha.em_campo or not rodada.seletor.posicao_permitida(posicao,
		rodada.campo.obter_centro_global(), bolinha.obter_raio(), rodada.arena.obter_area_inicial(), _ocupantes()):
		_recusar(id)
		return
	bolinha.entrar_em_campo(posicao)
	_aceitar_acao()

func _solicitar_tacada(direcao: Vector2, carga: float) -> void:
	if not _minha_vez() or _aguardando_acao:
		return
	_aguardando_acao = true
	_atualizar()
	if multiplayer.is_server():
		_validar_tacada(1, direcao, carga, _versao_acao)
	else:
		_pedir_tacada.rpc_id(1, direcao, carga, _versao_acao)

@rpc("any_peer", "call_remote", "reliable")
func _pedir_tacada(direcao: Vector2, carga: float, versao: int) -> void:
	if multiplayer.is_server():
		_validar_tacada(multiplayer.get_remote_sender_id(), direcao, carga, versao)

func _validar_tacada(id: int, direcao: Vector2, carga: float, versao: int) -> void:
	if not _remetente_pode_agir(id, versao):
		_recusar(id)
		return
	if not direcao.is_finite() or not is_finite(direcao.length_squared()) or direcao.is_zero_approx() or not is_finite(carga) or carga < 0.0 or carga > 1.0:
		_recusar(id)
		return
	var bolinha: Bolinha = rodada.obter_jogador_atual().bolinha
	if not bolinha.em_campo:
		_recusar(id)
		return
	rodada.jogada_em_andamento = true
	_quadros_apos_disparo = 0
	bolinha.sleeping = false
	bolinha.apply_central_impulse(direcao.normalized() * lerpf(rodada.IMPULSO_MINIMO, rodada.IMPULSO_MAXIMO, carga))
	_aceitar_acao()

func _aceitar_acao() -> void:
	_versao_acao += 1
	_aguardando_acao = false
	_desativar_seletor()
	_atualizar()
	_publicar(true)

func _recusar(id: int) -> void:
	if id == 1:
		_acao_recusada()
	elif RedeSala.participantes.has(id):
		_acao_recusada.rpc_id(id)

@rpc("authority", "call_remote", "reliable")
func _acao_recusada() -> void:
	_aguardando_acao = false
	_atualizar()

func _publicar(confiavel: bool) -> void:
	_sequencia += 1
	var bolinhas: Dictionary = {}
	for no in rodada.get_children():
		if no is Bolinha and not no.is_queued_for_deletion():
			bolinhas[String(no.name)] = [no.global_position, no.rotation, no.em_campo]
	var estado: Dictionary = {
		"seq": _sequencia, "versao": _versao_acao, "bolinhas": bolinhas,
		"epoca": _epoca, "liberada": _rodada_liberada,
		"totais": _totais.duplicate(), "confirmacoes": _confirmacoes.duplicate(),
		"vez": rodada.indice_jogador_atual, "tacadas": rodada.tacadas_no_turno,
		"movendo": rodada.jogada_em_andamento, "fim": rodada.partida_encerrada,
		"pontos": [rodada.jogadores[0].obter_pontos(), rodada.jogadores[1].obter_pontos()],
		"zoom": rodada.arena.get_node("Camera").zoom
	}
	if confiavel:
		_receber_evento.rpc(estado)
	else:
		_receber_movimento.rpc(estado)

@rpc("authority", "call_remote", "reliable", 0)
func _receber_evento(estado: Dictionary) -> void:
	_aplicar_estado(estado)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _receber_movimento(estado: Dictionary) -> void:
	_aplicar_estado(estado)

func _aplicar_estado(estado: Dictionary) -> void:
	if rodada == null or not RedeSala.partida_em_abertura or multiplayer.is_server():
		return
	if int(estado.epoca) != _epoca or int(estado.seq) <= _ultima_sequencia:
		return
	_rodada_liberada = bool(estado.liberada)
	_totais.assign(estado.totais)
	_confirmacoes = estado.confirmacoes.duplicate()
	_ultima_sequencia = int(estado.seq)
	if _versao_acao != int(estado.versao):
		_aguardando_acao = false
	_versao_acao = int(estado.versao)
	rodada.indice_jogador_atual = int(estado.vez)
	rodada.tacadas_no_turno = int(estado.tacadas)
	rodada.jogada_em_andamento = bool(estado.movendo)
	rodada.partida_encerrada = bool(estado.fim)
	for i in range(2):
		rodada.jogadores[i].adicionar_pontos(int(estado.pontos[i]) - rodada.jogadores[i].obter_pontos())
	for no in rodada.get_children():
		if not no is Bolinha or no.is_queued_for_deletion():
			continue
		if not estado.bolinhas.has(String(no.name)):
			no.queue_free()
			continue
		var dados: Array = estado.bolinhas[String(no.name)]
		no.global_position = dados[0]
		no.rotation = dados[1]
		no.em_campo = bool(dados[2])
		no.visible = no.em_campo
		no.freeze = true
	rodada.arena.get_node("Camera").zoom = estado.zoom
	_atualizar()

func _sair() -> void:
	RedeSala.fechar()
	var erro: Error = get_tree().change_scene_to_file("res://cenas/sala_online.tscn")
	if erro != OK:
		_estado.text = error_string(erro)


func _resultado_confronto() -> String:
	if _totais[0] > _totais[1]:
		return "Jogador 1 venceu o confronto!"
	if _totais[1] > _totais[0]:
		return "Jogador 2 venceu o confronto!"
	return "O confronto terminou empatado!"

func _informar_carregamento() -> void:
	if not RedeSala.partida_em_abertura:
		return
	if multiplayer.is_server():
		_registrar_carregamento(1, _epoca)
	else:
		_rodada_carregada.rpc_id(1, _epoca)

@rpc("any_peer", "call_remote", "reliable")
func _rodada_carregada(epoca: int) -> void:
	if multiplayer.is_server():
		_registrar_carregamento(multiplayer.get_remote_sender_id(), epoca)

func _registrar_carregamento(id: int, epoca: int) -> void:
	if epoca != _epoca or not RedeSala.participantes.has(id):
		return
	_carregados_rodada[id] = true
	_tentar_liberar()

func _tentar_liberar() -> void:
	if not multiplayer.is_server() or not RedeSala.partida_em_abertura or _rodada_liberada:
		return
	if _carregados_rodada.size() != 2 or RedeSala.cenas_carregadas.size() != 2 or rodada == null:
		return
	_rodada_liberada = true
	for no in rodada.get_children():
		if no is Bolinha:
			no.freeze = not no.em_campo
	_atualizar()
	_publicar(true)

func _solicitar_continuacao() -> void:
	if not _conectados() or not rodada.partida_encerrada or _continuacao_pendente:
		return
	_continuacao_pendente = true
	_atualizar()
	if multiplayer.is_server():
		_registrar_continuacao(1, _epoca)
	else:
		_pedir_continuacao.rpc_id(1, _epoca)

@rpc("any_peer", "call_remote", "reliable")
func _pedir_continuacao(epoca: int) -> void:
	if multiplayer.is_server():
		_registrar_continuacao(multiplayer.get_remote_sender_id(), epoca)

func _registrar_continuacao(id: int, epoca: int) -> void:
	if not _conectados() or not rodada.partida_encerrada or epoca != _epoca:
		return
	if not RedeSala.participantes.has(id) or _confirmacoes.has(id):
		return
	_confirmacoes[id] = true
	_atualizar()
	_publicar(true)
	if _confirmacoes.size() == 2 and not _transicao_pendente:
		_transicao_pendente = true
		_avancar_confronto.call_deferred()

func _avancar_confronto() -> void:
	if not RedeSala.partida_em_abertura or _confirmacoes.size() != 2:
		_transicao_pendente = false
		return
	var proxima: int = 2 if _numero_rodada == 1 else 1
	var totais: Array[int] = [0, 0]
	if proxima == 2:
		totais.assign(_totais)
	_preparar_rodada.rpc(proxima, totais, _epoca + 1, _versao_acao + 1)

@rpc("authority", "call_local", "reliable")
func _preparar_rodada(numero: int, totais: Array, epoca: int, versao: int) -> void:
	if not RedeSala.partida_em_abertura or epoca <= _epoca:
		return
	_rodada_liberada = false
	_numero_rodada = numero
	_totais.assign(totais)
	_epoca = epoca
	_versao_acao = versao
	_carregados_rodada.clear()
	_confirmacoes.clear()
	_continuacao_pendente = false
	_transicao_pendente = false
	_aguardando_acao = false
	_carregando = false
	_carga = 0.0
	_tempo_estado = 0.0
	_quadros_apos_disparo = 0
	if rodada != null:
		remove_child(rodada)
		rodada.queue_free()
	_criar_rodada()
	_informar_carregamento.call_deferred()
	
func _atualizar_indicador_vez() -> void:
	var texto: String = ""
	var cor: Color = Color.WHITE

	if not RedeSala.partida_em_abertura:
		texto = "CONEXÃO ENCERRADA"

	elif not _conectados():
		texto = "AGUARDANDO JOGADORES"

	elif rodada.partida_encerrada:
		texto = "RODADA ENCERRADA"

	elif rodada.jogada_em_andamento:
		texto = "BOLINHAS EM MOVIMENTO"

	elif _aguardando_acao:
		texto = "CONFIRMANDO JOGADA"

	elif _minha_vez():
		texto = "SUA VEZ"
		cor = Color("#A8D5BA")

	else:
		texto = "VEZ DO ADVERSÁRIO"

	_indicador_vez.text = texto
	_indicador_vez.add_theme_color_override(
		"font_color",
		cor
	)

func _ao_impacto_online(impulso: float) -> void:
	if not multiplayer.is_server() or not _conectados():
		return

	var tonalidade: float = randf_range(0.95, 1.05)

	_reproduzir_impacto.rpc(
		_epoca,
		impulso,
		tonalidade
	)


@rpc("authority", "call_local", "unreliable", 2)
func _reproduzir_impacto(
	epoca: int,
	impulso: float,
	tonalidade: float
) -> void:
	if not _conectados() or epoca != _epoca:
		return

	SonsJogo.tocar_colisao(impulso, tonalidade)

func _ao_alvo_recolhido_online(
	posicao_global: Vector2,
	valor: int
) -> void:
	if not multiplayer.is_server() or not _conectados():
		return

	_reproduzir_efeito_pontos.rpc(
		_epoca,
		posicao_global,
		valor
	)


@rpc("authority", "call_local", "reliable", 0)
func _reproduzir_efeito_pontos(
	epoca: int,
	posicao_global: Vector2,
	valor: int
) -> void:
	if not _conectados() or epoca != _epoca:
		return

	rodada.mostrar_efeito_pontos(posicao_global, valor)
