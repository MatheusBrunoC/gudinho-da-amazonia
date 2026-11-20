class_name RegrasPartida
extends RefCounted

# Distância do centro do círculo até a linha horizontal (pixels do mundo).
const DISTANCIA_LINHA: float = 220.0

static func altura_linha(centro: Vector2) -> float:
	return centro.y + DISTANCIA_LINHA
