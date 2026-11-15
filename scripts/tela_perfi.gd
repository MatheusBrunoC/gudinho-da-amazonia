extends Control

@onready var _voltar: Button = $Centro/Opcoes/BotaoVoltar


func _ready() -> void:
	_voltar.pressed.connect(_voltar_ao_menu)


func _voltar_ao_menu() -> void:
	_voltar.disabled = true

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/menu_inicial.tscn"
	)

	if erro != OK:
		_voltar.disabled = false
		push_error(
			"Falha ao voltar ao menu: %s" % error_string(erro)
		)
