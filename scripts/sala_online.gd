extends Control
## A interface apresenta o estado; RedeSala administra a conexão.
@onready var _endereco: LineEdit = %Endereco
@onready var _porta: SpinBox = %Porta
@onready var _estado: Label = %Estado
@onready var _jogadores: Label = %Jogadores
@onready var _criar: Button = %Criar
@onready var _entrar: Button = %Entrar
@onready var _pronto: Button = %Pronto
@onready var _sair: Button = %Desconectar

func _ready() -> void:
	_criar.pressed.connect(func(): RedeSala.criar(int(_porta.value)))
	_entrar.pressed.connect(func(): RedeSala.entrar(_endereco.text, int(_porta.value)))
	_pronto.pressed.connect(RedeSala.marcar_pronto)
	_sair.pressed.connect(RedeSala.fechar)
	%Voltar.pressed.connect(_voltar)
	RedeSala.atualizada.connect(_atualizar)
	_atualizar()

func _atualizar() -> void:
	_estado.text = RedeSala.mensagem
	var conectado: bool = RedeSala.em_sala()
	_criar.disabled = conectado
	_entrar.disabled = conectado
	_endereco.editable = not conectado
	_porta.editable = not conectado
	_sair.disabled = not conectado
	_pronto.disabled = not RedeSala.participantes.has(RedeSala.meu_id())
	if not _pronto.disabled:
		_pronto.disabled = RedeSala.participantes[RedeSala.meu_id()]
	var linhas: PackedStringArray = []
	for id in RedeSala.participantes:
		var nome: String = "Jogador 1 — anfitrião" if id == 1 else "Jogador 2 — visitante"
		if id == RedeSala.meu_id():
			nome += " (você)"
		linhas.append(nome + (" • pronto" if RedeSala.participantes[id] else " • aguardando confirmação"))
	_jogadores.text = "\n".join(linhas)

func _voltar() -> void:
	RedeSala.fechar()
	var erro: Error = get_tree().change_scene_to_file("res://cenas/menu_inicial.tscn")
	if erro != OK:
		_estado.text = error_string(erro)
