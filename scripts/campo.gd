class_name CampoCircular
extends CampoBase

#var tamanho_campo: Vector2 = Vector2(1280, 720)
var centro_circulo: Vector2 = RegrasPartida.CENTRO_CIRCULO
var raio_circulo: float = 140.0

#var cor_terra: Color = Color("#B88758")
var cor_linha: Color = Color("#FFF1D6")


func _draw() -> void:
		# Desenha o contorno do círculo.
	draw_arc(
		centro_circulo,
		raio_circulo,
		0.0,
		TAU,
		128,
		cor_linha,
		4.0,
		true
	)

	var x: float = RegrasPartida.x_linha(centro_circulo)
	draw_rect(Rect2(x, 0, 1280 - x, 720), Color(0.15, 0.55, 0.3, 0.12))
	draw_line(Vector2(x, 12), Vector2(x, 708), cor_linha, 4.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(x + 24, 230), "ÁREA DE LANÇAMENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, cor_linha)
	draw_string(ThemeDB.fallback_font, Vector2(x + 24, 257), "Posicione à direita da linha", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cor_linha)

func bolinha_esta_fora(posicao_global: Vector2, raio: float) -> bool:
	var posicao_local: Vector2 = to_local(posicao_global)
	var distancia: float = posicao_local.distance_to(centro_circulo)

	return distancia > raio_circulo + raio

func obter_centro_global() -> Vector2:
	return to_global(centro_circulo)


# A linha do círculo conta como dentro; basta o centro da bolinha tocar a área.
func centro_esta_no_circulo(posicao_global: Vector2) -> bool:
	return to_local(posicao_global).distance_to(centro_circulo) <= raio_circulo
