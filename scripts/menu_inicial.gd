extends Control

@onready var _jogar: Button = $Centro/Opcoes/BotaoJogar
@onready var _perfil: Button = $Centro/Opcoes/BotaoPerfil
@onready var _opcoes: Button = $Centro/Opcoes/BotaoOpcoes
@onready var _sair: Button = $Centro/Opcoes/BotaoSair

var _abrindo: bool = false


func _ready() -> void:
	_jogar.pressed.connect(
		_abrir_cena.bind("res://cenas/menu_jogar.tscn")
	)
	_perfil.pressed.connect(
		_abrir_cena.bind("res://cenas/tela_perfil.tscn")
	)
	_opcoes.pressed.connect(
		_abrir_cena.bind("res://cenas/menu_opcoes.tscn")
	)
	$Centro/Opcoes/BotaoInstrucoes.pressed.connect(
		_abrir_cena.bind("res://cenas/instrucoes.tscn")
	)
	_sair.pressed.connect(_encerrar)
	_sair.visible = not OS.has_feature("web")

	_jogar.grab_focus()


func _abrir_cena(caminho: String) -> void:
	if _abrindo:
		return

	_abrindo = true

	var erro: Error = get_tree().change_scene_to_file(caminho)

	if erro != OK:
		_abrindo = false
		push_error(
			"Falha ao abrir a tela: %s" % error_string(erro)
		)


func _encerrar() -> void:
	get_tree().quit()
