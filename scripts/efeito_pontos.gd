class_name EfeitoPontos
extends Node2D

@onready var _texto: Label = $Texto

@export var duracao: float = 0.9
@export var deslocamento: float = 45.0


func _ready() -> void:
	z_index = 20

	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_texto.position = Vector2(-40.0, -20.0)
	_texto.size = Vector2(80.0, 40.0)

	_texto.add_theme_font_size_override("font_size", 28)
	_texto.add_theme_color_override("font_color", Color.WHITE)
	_texto.add_theme_color_override(
		"font_outline_color",
		Color("#103B29")
	)
	_texto.add_theme_constant_override("outline_size", 5)


func apresentar(valor: int) -> void:
	_texto.text = "+%d" % valor

	var animacao: Tween = create_tween().set_parallel(true)

	animacao.tween_property(
		self,
		"position",
		position + Vector2(0.0, -deslocamento),
		duracao
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	animacao.tween_property(
		self,
		"modulate:a",
		0.0,
		duracao * 0.6
	).set_delay(duracao * 0.4)

	animacao.finished.connect(queue_free)
