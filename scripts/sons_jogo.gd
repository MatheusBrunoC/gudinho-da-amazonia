extends Node

const SOM_COLISAO: AudioStream = preload(
	"res://recursos/sons/colisao_bolinha.wav"
)

const SOM_CLIQUE: AudioStream = preload(
	"res://recursos/sons/clique_botao.wav"
)

const MAX_SONS: int = 8
const IMPULSO_REFERENCIA: float = 350.0
const NOME_BUS: StringName = &"Efeitos"
const ARQUIVO_CONFIG: String = "user://audio.cfg"

var volume_efeitos: float = 1.0
var efeitos_silenciados: bool = false
var _tocador_clique: AudioStreamPlayer
var _tocadores: Array[AudioStreamPlayer] = []
var _indice_bus: int = -1


func _ready() -> void:
	_preparar_bus()
	_carregar_configuracoes()
	_aplicar_configuracoes()

	for i in range(MAX_SONS):
		var tocador: AudioStreamPlayer = AudioStreamPlayer.new()
		tocador.stream = SOM_COLISAO
		tocador.bus = NOME_BUS

		add_child(tocador)
		_tocadores.append(tocador)
	_preparar_som_botoes()


func _preparar_bus() -> void:
	_indice_bus = AudioServer.get_bus_index(NOME_BUS)

	if _indice_bus == -1:
		AudioServer.add_bus()
		_indice_bus = AudioServer.bus_count - 1

		AudioServer.set_bus_name(_indice_bus, NOME_BUS)
		AudioServer.set_bus_send(_indice_bus, &"Master")


func definir_volume_efeitos(valor: float) -> void:
	volume_efeitos = clampf(valor, 0.0, 1.0)
	_aplicar_configuracoes()


func definir_efeitos_silenciados(silenciado: bool) -> void:
	efeitos_silenciados = silenciado
	_aplicar_configuracoes()


func _aplicar_configuracoes() -> void:
	AudioServer.set_bus_volume_db(
		_indice_bus,
		linear_to_db(maxf(volume_efeitos, 0.0001))
	)

	AudioServer.set_bus_mute(
		_indice_bus,
		efeitos_silenciados or volume_efeitos <= 0.0
	)


func salvar_configuracoes() -> Error:
	var config: ConfigFile = ConfigFile.new()

	config.set_value("audio", "volume_efeitos", volume_efeitos)
	config.set_value(
		"audio",
		"efeitos_silenciados",
		efeitos_silenciados
	)

	return config.save(ARQUIVO_CONFIG)


func _carregar_configuracoes() -> void:
	var config: ConfigFile = ConfigFile.new()

	if config.load(ARQUIVO_CONFIG) != OK:
		return

	volume_efeitos = clampf(
		float(config.get_value("audio", "volume_efeitos", 1.0)),
		0.0,
		1.0
	)

	efeitos_silenciados = bool(
		config.get_value("audio", "efeitos_silenciados", false)
	)


func tocar_colisao(impulso: float, tonalidade: float) -> void:
	if efeitos_silenciados or volume_efeitos <= 0.0:
		return

	var intensidade: float = clampf(
		impulso / IMPULSO_REFERENCIA,
		0.0,
		1.0
	)

	for tocador in _tocadores:
		if not tocador.playing:
			tocador.volume_db = lerpf(-8.0, 4.0, intensidade)
			tocador.pitch_scale = tonalidade
			tocador.play()
			return

func _preparar_som_botoes() -> void:
	_tocador_clique = AudioStreamPlayer.new()
	_tocador_clique.stream = SOM_CLIQUE
	_tocador_clique.bus = NOME_BUS
	_tocador_clique.volume_db = -14.0
	_tocador_clique.max_polyphony = 4

	add_child(_tocador_clique)

	# Detecta botões das próximas telas.
	get_tree().node_added.connect(_ao_no_adicionado)

	# Também procura botões que já estejam na árvore.
	_conectar_botoes_existentes(get_tree().root)


func _ao_no_adicionado(no: Node) -> void:
	if no is BaseButton:
		_conectar_botao.call_deferred(no)


func _conectar_botoes_existentes(no: Node) -> void:
	_conectar_botao(no)

	for filho in no.get_children():
		_conectar_botoes_existentes(filho)


func _conectar_botao(no: Node) -> void:
	if not is_instance_valid(no):
		return

	if not no is BaseButton:
		return

	var botao: BaseButton = no as BaseButton

	if not botao.pressed.is_connected(tocar_clique):
		botao.pressed.connect(tocar_clique)


func tocar_clique() -> void:
	if efeitos_silenciados or volume_efeitos <= 0.0:
		return

	_tocador_clique.play()
