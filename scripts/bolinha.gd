class_name Bolinha
extends RigidBody2D

signal impacto_detectado(impulso: float)

const IMPULSO_MINIMO_SOM: float = 8.0
const INTERVALO_SOM_MS: int = 80

var _ultimos_impactos: Dictionary = {}
var _contatos_anteriores: Dictionary = {}


@export var cor: Color = Color("#2980B9")
@export var eh_alvo: bool = false
@export_range(1, 10, 1) var valor_pontos: int = 1

const RAIO: float = 12.0
var _retorno_ativo: bool = false
var _limites_retorno: Rect2

var em_campo: bool = true
var _camada_original: int
var _mascara_original: int



func _draw() -> void:
	# Corpo da bolinha.
	draw_circle(Vector2.ZERO, RAIO, cor)

	# Contorno.
	draw_arc(
		Vector2.ZERO,
		RAIO,
		0.0,
		TAU,
		48,
		cor.darkened(0.4),
		1.5,
		true
	)

	# Pequeno brilho para dar aparência de vidro.
	draw_circle(
		Vector2(-4.0, -4.0),
		3.0,
		Color(1.0, 1.0, 1.0, 0.7)
	)
	
func obter_raio() -> float:
	return RAIO
	
func configurar_retorno(area: Rect2) -> void:
	# Mantém o centro a um raio de distância da borda.
	_limites_retorno = area.grow(-obter_raio())
	_retorno_ativo = true


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	_detectar_impactos(state)
	
	if not _retorno_ativo:
		return

	var posicao: Vector2 = state.transform.origin

	if _limites_retorno.has_point(posicao):
		return

	var nova_posicao: Vector2 = Vector2(
		wrapf(
			posicao.x,
			_limites_retorno.position.x,
			_limites_retorno.end.x
		),
		wrapf(
			posicao.y,
			_limites_retorno.position.y,
			_limites_retorno.end.y
		)
	)

	var transformacao: Transform2D = state.transform
	transformacao.origin = nova_posicao
	state.transform = transformacao

	reset_physics_interpolation()
	
func obter_valor_pontos() -> int:
	return valor_pontos
	

func aguardar_entrada() -> void:
	em_campo = false

	_camada_original = collision_layer
	_mascara_original = collision_mask

	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	collision_layer = 0
	collision_mask = 0
	hide()


func entrar_em_campo(posicao_global: Vector2) -> void:
	global_position = posicao_global
	reset_physics_interpolation()

	collision_layer = _camada_original
	collision_mask = _mascara_original

	em_campo = true
	show()
	freeze = false
	sleeping = true

func _detectar_impactos(
	state: PhysicsDirectBodyState2D
) -> void:
	if not em_campo:
		_contatos_anteriores.clear()
		return

	var agora: int = Time.get_ticks_msec()
	var contatos_atuais: Dictionary = {}

	for i in range(state.get_contact_count()):
		var objeto: Object = state.get_contact_collider_object(i)

		if not is_instance_valid(objeto):
			continue

		if not objeto is Bolinha:
			continue

		var outra: Bolinha = objeto as Bolinha
		var outro_id: int = outra.get_instance_id()

		contatos_atuais[outro_id] = true

		var impulso: float = state.get_contact_impulse(i).length()
		var contato_novo: bool = not _contatos_anteriores.has(
			outro_id
		)

		# Em contatos rápidos, o impulso pode ainda estar zerado.
		# Nesse caso, estimamos a intensidade sonora pela velocidade.
		if impulso < IMPULSO_MINIMO_SOM and contato_novo:
			var velocidade_relativa: Vector2 = (
				state.get_contact_local_velocity_at_position(i)
				- state.get_contact_collider_velocity_at_position(i)
			)

			var massa_reduzida: float = (
				mass * outra.mass / (mass + outra.mass)
			)

			impulso = velocidade_relativa.length() * massa_reduzida

		if impulso < IMPULSO_MINIMO_SOM:
			continue

		var ultimo: int = int(
			_ultimos_impactos.get(outro_id, -INTERVALO_SOM_MS)
		)

		if agora - ultimo < INTERVALO_SOM_MS:
			continue

		# Registra nas duas bolinhas para não duplicar o som.
		_ultimos_impactos[outro_id] = agora
		outra._ultimos_impactos[get_instance_id()] = agora

		impacto_detectado.emit(impulso)

	_contatos_anteriores = contatos_atuais
