class_name RegrasPartida
extends RefCounted

const CENTRO_CIRCULO: Vector2 = Vector2(300, 360)
# Distância horizontal do centro do círculo até a linha vertical.
const DISTANCIA_LINHA: float = 700.0

static func x_linha(centro: Vector2) -> float:
	return centro.x + DISTANCIA_LINHA
