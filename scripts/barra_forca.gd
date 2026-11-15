class_name BarraForca
extends ProgressBar

@export var cor_fraca: Color = Color("#55B879")
@export var cor_media: Color = Color("#F2D34F")
@export var cor_forte: Color = Color("#E5534B")

var _preenchimento: StyleBoxFlat


func _ready() -> void:
	var estilo_original: StyleBox = get_theme_stylebox("fill")

	if estilo_original is StyleBoxFlat:
		# Cada barra recebe sua própria cópia do estilo.
		_preenchimento = estilo_original.duplicate() as StyleBoxFlat
	else:
		_preenchimento = StyleBoxFlat.new()
		_preenchimento.set_corner_radius_all(7)

	add_theme_stylebox_override("fill", _preenchimento)

	value_changed.connect(_atualizar_cor)
	_atualizar_cor(value)


func _atualizar_cor(valor: float) -> void:
	var intervalo: float = maxf(max_value - min_value, 0.001)
	var percentual: float = clampf(
		(valor - min_value) / intervalo,
		0.0,
		1.0
	)

	if percentual <= 0.5:
		_preenchimento.bg_color = cor_fraca.lerp(
			cor_media,
			percentual * 2.0
		)
	else:
		_preenchimento.bg_color = cor_media.lerp(
			cor_forte,
			(percentual - 0.5) * 2.0
		)
