class_name InterfacePartida
extends CanvasLayer

signal continuacao_solicitada
signal menu_solicitado


@onready var _barra_forca: ProgressBar = $HUD/BarraForca
@onready var _texto_pontuacao: Label = $HUD/TextoPontuacao
@onready var _texto_vez: Label = $HUD/TextoVez
@onready var _texto_rodada: Label = $HUD/TextoRodada
@onready var _botao_continuar: Button = $HUD/BotaoContinuar
@onready var _botao_menu: Button = $HUD/BotaoMenu

@onready var _texto_historico: Label = $HUD/TextoHistorico

var _permite_desistir: bool = false
var _nomes: PackedStringArray = ["Jogador 1", "Jogador 2"]
var _base: Vector2i = Vector2i.ZERO
var _pontos: Vector2i = Vector2i.ZERO

func definir_jogadores(nome1: String, nome2: String) -> void:
	_nomes = [nome1, nome2]
	_atualizar_total()

func _atualizar_total() -> void:
	_texto_pontuacao.text = "%s   %d  ×  %d   %s" % [_nomes[0], _base.x + _pontos.x, _base.y + _pontos.y, _nomes[1]]

func mostrar_aviso(mensagem: String) -> void:
	$HUD/TextoAviso.text = mensagem

func mostrar_movimento(nome: String) -> void:
	_texto_vez.text = "Tacada de %s • aguarde as bolinhas pararem" % nome



func _ready() -> void:
	_botao_continuar.hide()
	_botao_continuar.pressed.connect(_solicitar_continuacao)
	_botao_menu.hide()
	_botao_menu.pressed.connect(_solicitar_menu)
	_texto_historico.hide()
	
func atualizar_forca(carga: float) -> void:
	_barra_forca.value = clampf(carga, 0.0, 1.0) * 100.0


func atualizar_placar(pontos1: int, pontos2: int) -> void:
	_pontos = Vector2i(pontos1, pontos2)
	_atualizar_total()


func mostrar_vez(nome: String, tacadas_restantes: int) -> void:
	var etapa: String = "tacada inicial" if tacadas_restantes == 2 else "tacada extra • última do turno"
	_texto_vez.text = "Vez de %s — %s" % [nome, etapa]


func mostrar_contexto(numero: int, total1: int, total2: int) -> void:
	_texto_rodada.text = "RODADA %d DE 2  •  PLACAR GERAL" % numero
	_base = Vector2i(total1, total2)
	_atualizar_total()


func mostrar_resultado(
	resultado: String,
	texto_botao: String,
	permitir_menu: bool = false
) -> void:
	_texto_vez.text = resultado
	_botao_continuar.text = texto_botao
	_botao_continuar.disabled = false
	_botao_continuar.show()

	_botao_menu.text = (
		"Voltar ao menu" if permitir_menu else "Desistir"
	)
	_botao_menu.visible = permitir_menu or _permite_desistir


func _solicitar_continuacao() -> void:
	_botao_continuar.disabled = true
	continuacao_solicitada.emit()
	
func mostrar_escolha_posicao(nome_jogador: String) -> void:
	_texto_vez.text = "%s: clique à direita da linha para posicionar a bolinha." % nome_jogador
	
func _solicitar_menu() -> void:
	menu_solicitado.emit()

func mostrar_estado_historico(mensagem: String) -> void:
	_texto_historico.text = mensagem
	_texto_historico.visible = not mensagem.is_empty()


func permitir_desistencia(permitir: bool) -> void:
	_permite_desistir = permitir
	_botao_menu.text = "Desistir"
	_botao_menu.visible = permitir
