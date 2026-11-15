extends Control

@onready var _audio: Button = $Centro/Opcoes/BotaoAudio
@onready var _como_jogar: Button = $Centro/Opcoes/BotaoInstrucoes
@onready var _voltar: Button = $Centro/Opcoes/BotaoVoltar
@onready var _instrucoes: AcceptDialog = $Instrucoes

var _abrindo: bool = false


func _ready() -> void:
	_audio.pressed.connect(
		_abrir_cena.bind("res://cenas/configuracoes_audio.tscn")
	)
	_como_jogar.pressed.connect(_mostrar_instrucoes)
	_voltar.pressed.connect(
		_abrir_cena.bind("res://cenas/menu_inicial.tscn")
	)

	_instrucoes.title = "Como jogar"
	_instrucoes.ok_button_text = "Entendi"
	_instrucoes.dialog_autowrap = true

	_audio.grab_focus()


func _mostrar_instrucoes() -> void:
	_instrucoes.popup_centered(Vector2i(700, 550))


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
