class_name CampoCircular
extends CampoBase

#var tamanho_campo: Vector2 = Vector2(1280, 720)
var centro_circulo: Vector2 = Vector2(640, 360)
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
	
func bolinha_esta_fora(posicao_global: Vector2, raio: float) -> bool:
	var posicao_local: Vector2 = to_local(posicao_global)
	var distancia: float = posicao_local.distance_to(centro_circulo)

	return distancia > raio_circulo + raio

func obter_centro_global() -> Vector2:
	return to_global(centro_circulo)
