class_name AdversarioComputador
extends RefCounted


func escolher_alvo(
	origem: Vector2,
	alvos: Array[Bolinha]
) -> Bolinha:
	var escolhido: Bolinha = null
	var menor_distancia: float = INF

	for alvo in alvos:
		var distancia: float = origem.distance_squared_to(
			alvo.global_position
		)

		if distancia < menor_distancia:
			menor_distancia = distancia
			escolhido = alvo

	return escolhido


func escolher_forca(distancia: float) -> float:
	# Estimativa inicial. Ajustaremos com os testes.
	return clampf(distancia / 500.0 + 0.25, 0.55, 1.0)


func escolher_posicao(
	centro: Vector2,
	bolinha: Bolinha,
	area: Rect2,
	seletor: SeletorPosicao,
	ocupantes: Array[Bolinha],
	alvos: Array[Bolinha]
) -> Vector2:
	var melhor_posicao: Vector2 = Vector2(INF, INF)
	var menor_distancia: float = INF
	var area_util: Rect2 = area.grow(-bolinha.obter_raio())

	# Examina posições distribuídas pela área inicial.
	var y: float = area_util.position.y

	while y < area_util.end.y:
		var x: float = area_util.position.x

		while x < area_util.end.x:
			var candidata: Vector2 = Vector2(x, y)

			if seletor.posicao_permitida(
				candidata,
				centro,
				bolinha.obter_raio(),
				area,
				ocupantes
			):
				var alvo: Bolinha = escolher_alvo(
					candidata,
					alvos
				)

				if alvo != null:
					var distancia: float = (
						candidata.distance_squared_to(
							alvo.global_position
						)
					)

					if distancia < menor_distancia:
						menor_distancia = distancia
						melhor_posicao = candidata

			x += 32.0

		y += 32.0

	return melhor_posicao
