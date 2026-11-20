extends Control

func _ready() -> void:
	$Voltar.pressed.connect(_voltar)
	$Voltar.grab_focus()

func _voltar() -> void:
	var erro: Error = get_tree().change_scene_to_file("res://cenas/menu_inicial.tscn")
	if erro != OK:
		push_error("Não foi possível abrir o menu: %s" % error_string(erro))
