extends Control

@onready var _local: Button = $Centro/Opcoes/BotaoJogar
@onready var _treino: Button = $Centro/Opcoes/BotaoTreino
@onready var _online: Button = $Centro/Opcoes/BotaoOnline
@onready var _voltar: Button = $Centro/Opcoes/BotaoVoltar

var _abrindo: bool = false


func _ready() -> void:
	_local.pressed.connect(
		_abrir_cena.bind("res://cenas/confronto.tscn")
	)
	_treino.pressed.connect(
		_abrir_cena.bind("res://cenas/treino.tscn")
	)
	_online.pressed.connect(
		_abrir_cena.bind("res://cenas/sala_online.tscn")
	)
	_voltar.pressed.connect(
		_abrir_cena.bind("res://cenas/menu_inicial.tscn")
	)

	_local.grab_focus()


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
