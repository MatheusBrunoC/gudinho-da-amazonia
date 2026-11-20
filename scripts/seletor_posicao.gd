class_name SeletorPosicao
extends Node2D

signal posicao_confirmada(posicao_global: Vector2)


var ativo: bool = false

var _centro: Vector2
var _posicao: Vector2
var _raio_bolinha: float
var _cor_bolinha: Color
var _area_inicial: Rect2
var _posicao_valida: bool = false
var _ocupantes: Array[Bolinha] = []


func _ready() -> void:
	hide()


func iniciar(
	centro_global: Vector2,
	bolinha: Bolinha,
	ocupantes: Array[Bolinha],
	area_inicial: Rect2
) -> void:
	_centro = centro_global
	_raio_bolinha = bolinha.obter_raio()
	_cor_bolinha = bolinha.cor
	_ocupantes = ocupantes
	_area_inicial = area_inicial

	ativo = true
	show()
	_atualizar_previa()


func _process(_delta: float) -> void:
	if ativo:
		_atualizar_previa()


func _atualizar_previa() -> void:
	# A prévia acompanha livremente a posição do mouse.
	_posicao = get_global_mouse_position()
	_posicao_valida = _verificar_posicao()
	queue_redraw()


func _verificar_posicao() -> bool:
	return posicao_permitida(_posicao, _centro, _raio_bolinha, _area_inicial, _ocupantes)


# A prévia e o servidor usam a mesma regra, com os dados locais de cada cena.
func posicao_permitida(
	posicao: Vector2,
	centro: Vector2,
	raio: float,
	area: Rect2,
	ocupantes: Array[Bolinha]
) -> bool:
	if not posicao.is_finite():
		return false
	if not area.grow(-raio).has_point(posicao):
		return false
	if posicao.x < RegrasPartida.x_linha(centro) + raio:
		return false
	for bolinha in ocupantes:
		if not is_instance_valid(bolinha) or bolinha.is_queued_for_deletion():
			continue
		if posicao.distance_to(bolinha.global_position) < raio + bolinha.obter_raio() + 2.0:
			return false
	return true


func confirmar() -> void:
	if not ativo:
		return

	_atualizar_previa()

	if not _posicao_valida:
		return

	ativo = false
	hide()
	posicao_confirmada.emit(_posicao)


func _draw() -> void:
	if not ativo:
		return

	# A restrição vale apenas para posicionar, não para o caminho da tacada.
	var linha: float = RegrasPartida.x_linha(_centro)
	draw_rect(Rect2(to_local(_area_inicial.position), Vector2(linha - _area_inicial.position.x, _area_inicial.size.y)), Color(0.8, 0.15, 0.1, 0.07))
	draw_rect(Rect2(to_local(Vector2(linha, _area_inicial.position.y)), Vector2(_area_inicial.end.x - linha, _area_inicial.size.y)), Color(0.25, 0.8, 0.45, 0.12))

	var cor_previa: Color = _cor_bolinha
	cor_previa.a = 0.6

	if not _posicao_valida:
		cor_previa = Color(1.0, 0.15, 0.15, 0.8)

	draw_circle(
		to_local(_posicao),
		_raio_bolinha,
		cor_previa
	)
