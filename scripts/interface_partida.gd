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

func _ready() -> void:
	_botao_continuar.hide()
	_botao_continuar.pressed.connect(_solicitar_continuacao)
	_botao_menu.hide()
	_botao_menu.pressed.connect(_solicitar_menu)

func atualizar_forca(carga: float) -> void:
	_barra_forca.value = clampf(carga, 0.0, 1.0) * 100.0


func atualizar_placar(pontos1: int, pontos2: int) -> void:
	_texto_pontuacao.text = "Nesta rodada — J1: %d | J2: %d" % [
		pontos1,
		pontos2
	]


func mostrar_vez(nome: String, tacadas_restantes: int) -> void:
	_texto_vez.text = "Vez de %s | Limite restante: %d" % [
		nome,
		tacadas_restantes
	]


func mostrar_contexto(numero: int, total1: int, total2: int) -> void:
	_texto_rodada.text = "Rodada %d/2 | Total acumulado — J1: %d | J2: %d" % [
		numero,
		total1,
		total2
	]


func mostrar_resultado(resultado: String, texto_botao: String, permitir_menu: bool = false) -> void:
	_texto_vez.text = resultado
	_botao_continuar.text = texto_botao
	_botao_continuar.disabled = false
	_botao_continuar.show()
	_botao_menu.visible = permitir_menu


func _solicitar_continuacao() -> void:
	_botao_continuar.disabled = true
	continuacao_solicitada.emit()
	
func mostrar_escolha_posicao(nome_jogador: String) -> void:
	_texto_vez.text = "%s: escolha fora do círculo marcado. Vermelho = inválido." % nome_jogador
	
func _solicitar_menu() -> void:
	menu_solicitado.emit()
