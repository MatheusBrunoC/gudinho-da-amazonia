extends Control

@onready var _audio: Button = $Centro/Opcoes/BotaoAudio
@onready var _voltar: Button = $Centro/Opcoes/BotaoVoltar

var _abrindo: bool = false


func _ready() -> void:
	_audio.pressed.connect(
		_abrir_cena.bind("res://cenas/configuracoes_audio.tscn")
	)
	_voltar.pressed.connect(
		_abrir_cena.bind("res://cenas/menu_inicial.tscn")
	)

	_audio.grab_focus()



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
