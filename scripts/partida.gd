class_name RodadaPartida
extends Node2D

signal rodada_encerrada(pontos1: int, pontos2: int)
signal continuacao_solicitada
signal menu_solicitado
signal alvo_recolhido(posicao_global: Vector2, valor: int)
@onready var mira: Line2D = $Mira
@onready var interface: InterfacePartida = $Interface
@onready var campo: CampoBase = $Campo
@onready var arena: ArenaJogo = $Arena
@onready var seletor: SeletorPosicao = $SeletorPosicao

const MAX_TACADAS_CONSECUTIVAS: int = 2
const IMPULSO_MINIMO: float = 150.0
const IMPULSO_MAXIMO: float = 750.0
const TEMPO_CARGA: float = 1.5
const COMPRIMENTO_MIRA: float = 180.0
const CENA_EFEITO_PONTOS: PackedScene = preload(
	"res://cenas/efeito_pontos.tscn"
)
var jogadores: Array[JogadorPartida] = []
var indice_jogador_atual: int = 0
var efeitos_pontos_locais_ativos: bool = true
var jogada_em_andamento: bool = false
var partida_encerrada: bool = false
var carregando: bool = false
var carga: float = 0.0
var tacadas_no_turno: int = 0

var contra_computador: bool = false
var _computador: AdversarioComputador = AdversarioComputador.new()
var _tempo_computador: float = 0.0
var sons_locais_ativos: bool = true

const TEMPO_PENSAMENTO: float = 0.8


func _ready() -> void:
	interface.continuacao_solicitada.connect(_solicitar_continuacao)
	seletor.posicao_confirmada.connect(_confirmar_posicao_inicial)

	jogadores.append(
		JogadorPartida.new("Jogador 1", $BolinhaJogador1)
	)
	jogadores.append(
		JogadorPartida.new(
		"Computador" if contra_computador else "Jogador 2",
		$BolinhaJogador2
)
	)

	for jogador in jogadores:
		jogador.bolinha.aguardar_entrada()

	arena.configurar([
		jogadores[0].bolinha,
		jogadores[1].bolinha
	])

	atualizar_placar()
	_preparar_vez()
	interface.menu_solicitado.connect(_solicitar_menu)

	for no in get_children():
		if no is Bolinha:
			no.impacto_detectado.connect(_ao_impacto)
	alvo_recolhido.connect(_ao_alvo_recolhido)
	
	
func obter_jogador_atual() -> JogadorPartida:
	return jogadores[indice_jogador_atual]


func _process(delta: float) -> void:
	if partida_encerrada:
		return

	if jogada_em_andamento and todas_bolinhas_paradas():
		finalizar_jogada()

	mira.visible = (
		not jogada_em_andamento
		and not partida_encerrada
		and not seletor.ativo
		and not eh_vez_computador()
	)

	if jogada_em_andamento or partida_encerrada or seletor.ativo:
		return

	if eh_vez_computador():
		_tempo_computador -= delta

		if _tempo_computador <= 0.0:
			_jogar_computador()

		return

	if carregando:
		carga = minf(carga + delta / TEMPO_CARGA, 1.0)

	interface.atualizar_forca(carga)
	atualizar_mira()

func todas_bolinhas_paradas() -> bool:
	for no in get_children():
		if no is Bolinha and no.em_campo:
			if not no.sleeping:
				return false

	return true


func atualizar_mira() -> void:
	var bolinha: Bolinha = obter_jogador_atual().bolinha
	var direcao: Vector2 = bolinha.global_position.direction_to(
		get_global_mouse_position()
	)

	var inicio: Vector2 = bolinha.global_position + direcao * 16.0
	var fim: Vector2 = bolinha.global_position + direcao * COMPRIMENTO_MIRA

	mira.points = PackedVector2Array([
		mira.to_local(inicio),
		mira.to_local(fim)
	])


func _unhandled_input(event: InputEvent) -> void:
	if eh_vez_computador():
		return
		
	if jogada_em_andamento or partida_encerrada:
		return

	if seletor.ativo:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				seletor.confirmar()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				carregando = true
				carga = 0.0
			elif carregando:
				carregando = false
				disparar()

# Lê a intenção do jogador usando o mouse.
func disparar() -> void:
	var bolinha: Bolinha = obter_jogador_atual().bolinha

	var direcao: Vector2 = bolinha.global_position.direction_to(
		get_global_mouse_position()
	)

	var carga_escolhida: float = carga

	carregando = false
	carga = 0.0
	interface.atualizar_forca(0.0)

	executar_tacada(direcao, carga_escolhida)


# Executa uma tacada independentemente de quem a escolheu.
func executar_tacada( direcao: Vector2, forca_normalizada: float) -> bool:
	if jogada_em_andamento or partida_encerrada:
		return false

	if seletor.ativo:
		return false

	var bolinha: Bolinha = obter_jogador_atual().bolinha

	if not bolinha.em_campo:
		return false

	if not direcao.is_finite() or direcao.is_zero_approx():
		return false

	if not is_finite(forca_normalizada):
		return false

	var forca: float = clampf(forca_normalizada, 0.0, 1.0)

	var impulso: float = lerpf(
		IMPULSO_MINIMO,
		IMPULSO_MAXIMO,
		forca
	)

	jogada_em_andamento = true
	mira.hide()

	bolinha.sleeping = false
	bolinha.apply_central_impulse(
		direcao.normalized() * impulso
	)

	return true


func finalizar_jogada() -> void:
	var pontos_da_jogada: int = recolher_bolinhas_fora()

	obter_jogador_atual().adicionar_pontos(pontos_da_jogada)
	tacadas_no_turno += 1

	atualizar_placar()
	jogada_em_andamento = false

	if not existem_alvos():
		encerrar_partida()
		return

	var atingiu_limite: bool = (
		tacadas_no_turno >= MAX_TACADAS_CONSECUTIVAS
	)

	if pontos_da_jogada == 0 or atingiu_limite:
		indice_jogador_atual = (
			indice_jogador_atual + 1
		) % jogadores.size()

		tacadas_no_turno = 0

	_preparar_vez()


func recolher_bolinhas_fora() -> int:
	var total_pontos: int = 0

	for no in get_children():
		if no is Bolinha and no.eh_alvo:
			if no.is_queued_for_deletion():
				continue

			if campo.bolinha_esta_fora(
				no.global_position,
				no.obter_raio()
			):
				var valor: int = no.obter_valor_pontos()

				total_pontos += valor
				alvo_recolhido.emit(no.global_position, valor)

				no.queue_free()

	return total_pontos


func existem_alvos() -> bool:
	for no in get_children():
		if no is Bolinha and no.eh_alvo:
			if not no.is_queued_for_deletion():
				return true

	return false


func atualizar_placar() -> void:
	interface.atualizar_placar(
		jogadores[0].obter_pontos(),
		jogadores[1].obter_pontos()
	)


func encerrar_partida() -> void:
	partida_encerrada = true
	carregando = false
	carga = 0.0

	mira.hide()
	interface.atualizar_forca(0.0)

	rodada_encerrada.emit(
		jogadores[0].obter_pontos(),
		jogadores[1].obter_pontos()
	)

func configurar_rodada(numero: int) -> void:
	indice_jogador_atual = numero - 1

	if numero == 2:
		var bolinha1: Bolinha = $BolinhaJogador1
		var bolinha2: Bolinha = $BolinhaJogador2
		var posicao_original: Vector2 = bolinha1.position

		bolinha1.position = bolinha2.position
		bolinha2.position = posicao_original


func mostrar_contexto(numero: int, total1: int, total2: int) -> void:
	interface.mostrar_contexto(numero, total1, total2)


func apresentar_resultado(mensagem: String, texto_botao: String, permitir_menu: bool = false) -> void:
	interface.mostrar_resultado(
		mensagem,
		texto_botao,
		permitir_menu
	)


func _solicitar_continuacao() -> void:
	if partida_encerrada:
		continuacao_solicitada.emit()
		
func _preparar_vez() -> void:
	var jogador: JogadorPartida = obter_jogador_atual()

	carregando = false
	carga = 0.0
	interface.atualizar_forca(0.0)

	if eh_vez_computador():
		seletor.ativo = false
		seletor.hide()
		mira.hide()

		_tempo_computador = TEMPO_PENSAMENTO

		interface.mostrar_vez(
			"Computador",
			MAX_TACADAS_CONSECUTIVAS - tacadas_no_turno
		)
		return


	if not jogador.bolinha.em_campo:
		var ocupantes: Array[Bolinha] = []

		for no in get_children():
			if no is Bolinha and no.em_campo:
				if not no.is_queued_for_deletion():
					ocupantes.append(no)

		mira.hide()
		interface.mostrar_escolha_posicao(jogador.nome)

		seletor.iniciar(
			campo.obter_centro_global(),
			jogador.bolinha,
			ocupantes,
			arena.obter_area_inicial()
		)
		return

	interface.mostrar_vez(
		jogador.nome,
		MAX_TACADAS_CONSECUTIVAS - tacadas_no_turno
	)


func _confirmar_posicao_inicial(posicao_global: Vector2) -> void:
	obter_jogador_atual().bolinha.entrar_em_campo(posicao_global)
	_preparar_vez()

func _solicitar_menu() -> void:
	if partida_encerrada:
		menu_solicitado.emit()
		
func eh_vez_computador() -> bool:
	return contra_computador and indice_jogador_atual == 1


func _obter_alvos() -> Array[Bolinha]:
	var alvos: Array[Bolinha] = []

	for no in get_children():
		if no is Bolinha and no.eh_alvo:
			if not no.is_queued_for_deletion():
				alvos.append(no)

	return alvos


func _jogar_computador() -> void:
	# Evita repetir a tentativa a cada quadro.
	_tempo_computador = INF

	if not eh_vez_computador():
		return

	if jogada_em_andamento or partida_encerrada:
		return

	var bolinha: Bolinha = obter_jogador_atual().bolinha
	var alvos: Array[Bolinha] = _obter_alvos()

	if alvos.is_empty():
		return

	if not bolinha.em_campo:
		var ocupantes: Array[Bolinha] = []

		for no in get_children():
			if no is Bolinha and no.em_campo:
				if not no.is_queued_for_deletion():
					ocupantes.append(no)

		var posicao: Vector2 = _computador.escolher_posicao(
			campo.obter_centro_global(),
			bolinha,
			arena.obter_area_inicial(),
			seletor,
			ocupantes,
			alvos
		)

		if not posicao.is_finite():
			push_warning(
				"O computador não encontrou posição inicial válida."
			)
			return

		bolinha.entrar_em_campo(posicao)

		# Aguarda novamente antes de disparar.
		_preparar_vez()
		return

	var alvo: Bolinha = _computador.escolher_alvo(
		bolinha.global_position,
		alvos
	)

	if alvo == null:
		return

	var direcao: Vector2 = bolinha.global_position.direction_to(
		alvo.global_position
	)

	var distancia: float = bolinha.global_position.distance_to(
		alvo.global_position
	)

	executar_tacada(
		direcao,
		_computador.escolher_forca(distancia)
	)

func _ao_impacto(impulso: float) -> void:

	if not sons_locais_ativos:
		return

	SonsJogo.tocar_colisao(
		impulso,
		randf_range(0.95, 1.05)
	)

func _ao_alvo_recolhido(
	posicao_global: Vector2,
	valor: int
) -> void:
	if not efeitos_pontos_locais_ativos:
		return

	mostrar_efeito_pontos(posicao_global, valor)


func mostrar_efeito_pontos(
	posicao_global: Vector2,
	valor: int
) -> void:
	var efeito: EfeitoPontos = (
		CENA_EFEITO_PONTOS.instantiate() as EfeitoPontos
	)

	# Permite animar mesmo quando a rodada está desativada.
	efeito.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(efeito)
	efeito.global_position = posicao_global
	efeito.apresentar(valor)
