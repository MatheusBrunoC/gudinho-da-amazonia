extends Control

@onready var _botao_jogar: Button = $Centro/Opcoes/BotaoJogar
@onready var _botao_instrucoes: Button = $Centro/Opcoes/BotaoInstrucoes
@onready var _botao_sair: Button = $Centro/Opcoes/BotaoSair
@onready var _instrucoes: AcceptDialog = $Instrucoes
@onready var _botao_treino: Button = $Centro/Opcoes/BotaoTreino

func _ready() -> void:
	$Centro/Opcoes/BotaoOnline.pressed.connect(func(): get_tree().change_scene_to_file("res://cenas/sala_online.tscn"))
	_botao_jogar.pressed.connect(_jogar)
	_botao_instrucoes.pressed.connect(_mostrar_instrucoes)
	_botao_sair.pressed.connect(_sair)

	_instrucoes.title = "Como jogar"
	_instrucoes.ok_button_text = "Entendi"
	_instrucoes.dialog_autowrap = true

	_instrucoes.dialog_text = """COMO JOGAR

OBJETIVO
Retire as bolinhas do círculo para somar pontos.
O confronto tem duas rodadas. Vence quem acumular mais pontos!

CONTROLES
Na sua primeira vez em cada rodada, clique em uma posição
válida fora da área proibida para colocar sua bolinha.

Mova o mouse para mirar.
Segure o botão esquerdo para carregar a força.
Solte para disparar.

Nas próximas tacadas, você joga de onde sua bolinha parou.

PONTUAÇÃO
Bolinhas comuns: 1 ponto.
Bolinhas especiais: 2 pontos.
Bolinha central: 3 pontos.

Os pontos são contabilizados quando as bolinhas param.
Para pontuar, a bolinha-alvo precisa sair completamente do círculo.

TURNOS
Se marcar pontos, você pode jogar novamente.
Cada turno permite no máximo duas tacadas.
Se não marcar pontos, a vez passa ao adversário.

DUAS RODADAS
O Jogador 1 começa a primeira rodada.
O Jogador 2 começa a segunda.
Os pontos das duas rodadas são somados.
Se os totais forem iguais, o confronto termina empatado.

LIMITES DA ARENA
A câmera amplia a visão conforme necessário.
Ao ultrapassar o limite máximo, sua bolinha reaparece
pelo lado oposto.

TREINO E ONLINE
No treino, você enfrenta o computador.
No online, cada participante controla sua própria bolinha.
Os dois precisam confirmar para avançar à próxima rodada."""

	_botao_jogar.grab_focus()
	_botao_treino.pressed.connect(_abrir_treino)
	$Centro/Opcoes/BotaoAudio.pressed.connect(_abrir_audio)

func _jogar() -> void:
	_botao_jogar.disabled = true

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/confronto.tscn"
	)

	if erro != OK:
		_botao_jogar.disabled = false
		push_error("Falha ao abrir o jogo: %s" % error_string(erro))


func _mostrar_instrucoes() -> void:
	_instrucoes.popup_centered(Vector2i(700, 550))


func _sair() -> void:
	get_tree().quit()

func _abrir_treino() -> void:
	_botao_treino.disabled = true

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/treino.tscn"
	)

	if erro != OK:
		_botao_treino.disabled = false
		push_error(
			"Falha ao abrir o treino: %s" % error_string(erro)
		)

func _abrir_audio() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/configuracoes_audio.tscn"
	)

	if erro != OK:
		push_error(
			"Falha ao abrir as configurações de áudio: %s"
			% error_string(erro)
		)
