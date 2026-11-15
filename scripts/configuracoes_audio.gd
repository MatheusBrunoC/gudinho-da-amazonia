extends Control

@onready var _volume: HSlider = $Centro/Opcoes/VolumeEfeitos
@onready var _silenciar: CheckButton = $Centro/Opcoes/SilenciarEfeitos
@onready var _texto_volume: Label = $Centro/Opcoes/TextoVolume
@onready var _aviso: Label = $Centro/Opcoes/Aviso


func _ready() -> void:
	_volume.set_value_no_signal(
		SonsJogo.volume_efeitos * 100.0
	)

	_silenciar.set_pressed_no_signal(
		SonsJogo.efeitos_silenciados
	)

	_atualizar_texto_volume(_volume.value)

	_volume.value_changed.connect(_alterar_volume)
	_silenciar.toggled.connect(_alterar_silenciamento)

	$Centro/Opcoes/TestarSom.pressed.connect(_testar_som)
	$Centro/Opcoes/Voltar.pressed.connect(_salvar_e_voltar)


func _alterar_volume(valor: float) -> void:
	SonsJogo.definir_volume_efeitos(valor / 100.0)
	_atualizar_texto_volume(valor)
	_aviso.text = "Clique em Salvar e voltar para guardar a configuração."


func _atualizar_texto_volume(valor: float) -> void:
	_texto_volume.text = "Volume dos efeitos: %d%%" % int(valor)


func _alterar_silenciamento(ativo: bool) -> void:
	SonsJogo.definir_efeitos_silenciados(ativo)
	_aviso.text = "Clique em Salvar e voltar para guardar a configuração."


func _testar_som() -> void:
	if SonsJogo.efeitos_silenciados:
		_aviso.text = "Desmarque Silenciar efeitos para ouvir o teste."
		return

	if SonsJogo.volume_efeitos <= 0.0:
		_aviso.text = "Aumente o volume para ouvir o teste."
		return

	SonsJogo.tocar_colisao(350.0, 1.0)
	_aviso.text = "Reproduzindo uma colisão de teste."


func _salvar_e_voltar() -> void:
	var erro: Error = SonsJogo.salvar_configuracoes()

	if erro != OK:
		_aviso.text = "Não foi possível salvar: %s" % error_string(erro)
		return

	erro = get_tree().change_scene_to_file(
		"res://cenas/menu_opcoes.tscn"
	)

	if erro != OK:
		_aviso.text = "Não foi possível abrir o menu: %s" % error_string(erro)
