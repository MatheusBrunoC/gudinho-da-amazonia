class_name ArenaJogo
extends Node2D

const AREA_INICIAL: Rect2 = Rect2(0, 0, 1280, 720)
const AREA_MAXIMA: Rect2 = Rect2(-320, -180, 1920, 1080)
const MARGEM_CAMERA: float = 48.0

@onready var _camera: Camera2D = $Camera

var _bolinhas: Array[Bolinha] = []


func configurar(bolinhas_jogadores: Array[Bolinha]) -> void:
	_bolinhas = bolinhas_jogadores

	_camera.global_position = AREA_INICIAL.get_center()
	_camera.zoom = Vector2.ONE
	_camera.make_current()

	# Prepara o retorno de todos os jogadores pelas bordas.
	for bolinha in _bolinhas:
		bolinha.configurar_retorno(AREA_MAXIMA)


func _process(_delta: float) -> void:
	if _bolinhas.is_empty():
		return

	var centro: Vector2 = AREA_INICIAL.get_center()
	var metade_necessaria: Vector2 = AREA_INICIAL.size / 2.0

	for bolinha in _bolinhas:
		# A câmera acompanha as bolinhas que já entraram no campo.
		if not bolinha.em_campo:
			continue

		var distancia: Vector2 = (
			bolinha.global_position - centro
		).abs()

		metade_necessaria.x = maxf(
			metade_necessaria.x,
			distancia.x + MARGEM_CAMERA
		)
		metade_necessaria.y = maxf(
			metade_necessaria.y,
			distancia.y + MARGEM_CAMERA
		)

	var zoom_horizontal: float = (
		AREA_INICIAL.size.x / (metade_necessaria.x * 2.0)
	)
	var zoom_vertical: float = (
		AREA_INICIAL.size.y / (metade_necessaria.y * 2.0)
	)

	var zoom_minimo: float = maxf(
		AREA_INICIAL.size.x / AREA_MAXIMA.size.x,
		AREA_INICIAL.size.y / AREA_MAXIMA.size.y
	)

	var zoom_desejado: float = clampf(
		minf(zoom_horizontal, zoom_vertical),
		zoom_minimo,
		1.0
	)

	# Mantém a maior área de visão já alcançada nesta rodada.
	var novo_zoom: float = minf(_camera.zoom.x, zoom_desejado)
	_camera.zoom = Vector2(novo_zoom, novo_zoom)


func _draw() -> void:
	draw_rect(AREA_MAXIMA, Color("#B88758"))

	draw_rect(
		AREA_MAXIMA,
		Color("#6B4930"),
		false,
		6.0
	)

func obter_area_inicial() -> Rect2:
	return AREA_INICIAL
