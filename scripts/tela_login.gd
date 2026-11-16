extends Control

@onready var _usuario: LineEdit = $Centro/Campos/Usuario
@onready var _senha: LineEdit = $Centro/Campos/Senha
@onready var _entrar: Button = $Centro/Campos/Entrar
@onready var _mensagem: Label = $Centro/Campos/Mensagem
@onready var _voltar: Button = $Centro/Campos/Voltar
@onready var _criar_conta: Button = $Centro/Campos/BotaoCriarConta
var _enviando: bool = false


func _ready() -> void:
	_entrar.pressed.connect(_solicitar_login)
	_voltar.pressed.connect(_voltar_ao_menu)

	SessaoJogador.login_realizado.connect(_ao_entrar)
	SessaoJogador.login_falhou.connect(_ao_falhar)

	if SessaoJogador.possui_sessao():
		_ao_entrar(SessaoJogador.obter_perfil())
	else:
		_usuario.grab_focus()
	_criar_conta.pressed.connect(_abrir_cadastro)

func _solicitar_login() -> void:
	if _enviando:
		return

	var senha_digitada: String = _senha.text

	_senha.clear()
	_definir_enviando(true)
	_mensagem.text = "Entrando..."

	SessaoJogador.entrar(_usuario.text, senha_digitada)


func _ao_entrar(_perfil: Dictionary) -> void:
	_definir_enviando(false)
	_senha.clear()
	_mensagem.text = "Login realizado. Abrindo perfil..."

	_abrir_perfil.call_deferred()


func _ao_falhar(mensagem: String) -> void:
	_definir_enviando(false)
	_mensagem.text = mensagem
	_senha.grab_focus()


func _definir_enviando(valor: bool) -> void:
	_enviando = valor
	_entrar.disabled = valor
	_usuario.editable = not valor
	_senha.editable = not valor
	_criar_conta.disabled = valor

func _voltar_ao_menu() -> void:
	if _enviando:
		SessaoJogador.cancelar_login()
		_definir_enviando(false)
		_mensagem.text = ""

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/menu_inicial.tscn"
	)

	if erro != OK:
		_mensagem.text = "Não foi possível voltar ao menu."


func _abrir_perfil() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/tela_perfil.tscn"
	)

	if erro != OK:
		_mensagem.text = "Não foi possível abrir a tela do perfil."
		
func _abrir_cadastro() -> void:
	if _enviando:
		return

	_senha.clear()

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/tela_cadastro.tscn"
	)

	if erro != OK:
		_mensagem.text = "Não foi possível abrir o cadastro."
