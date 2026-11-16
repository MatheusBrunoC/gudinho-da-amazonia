extends Control

@onready var _apelido: LineEdit = $Centro/Campos/Apelido
@onready var _usuario: LineEdit = $Centro/Campos/Usuario
@onready var _senha: LineEdit = $Centro/Campos/Senha
@onready var _confirmacao: LineEdit = $Centro/Campos/ConfirmarSenha
@onready var _criar: Button = $Centro/Campos/CriarConta
@onready var _mensagem: Label = $Centro/Campos/Mensagem
@onready var _voltar: Button = $Centro/Campos/Voltar
@onready var _consulta: HTTPRequest = $ConsultaCadastro

var _ocupado: bool = false
var _conta_criada: bool = false


func _ready() -> void:
	_criar.pressed.connect(_cadastrar)
	_voltar.pressed.connect(_voltar_ao_login)

	_consulta.timeout = 90.0
	_consulta.request_completed.connect(_ao_receber_resposta)

	_apelido.grab_focus()


func _cadastrar() -> void:
	if _ocupado or _conta_criada:
		return

	var apelido: String = _apelido.text.strip_edges()
	var usuario: String = _usuario.text.strip_edges().to_lower()
	var senha: String = _senha.text

	if apelido.is_empty() or apelido.length() > 30:
		_mensagem.text = "Use um apelido de 1 a 30 caracteres."
		return

	var regra_usuario: RegEx = RegEx.new()
	regra_usuario.compile("^[a-z0-9_]{3,30}$")

	if regra_usuario.search(usuario) == null:
		_mensagem.text = (
			"O usuário deve ter de 3 a 30 caracteres: "
			+ "letras sem acentos, números ou _."
		)
		return

	if senha.length() < 15 or senha.length() > 128:
		_mensagem.text = "A senha deve ter de 15 a 128 caracteres."
		return

	if senha != _confirmacao.text:
		_mensagem.text = "As senhas não coincidem."
		return

	var dados: Dictionary = {
		"apelido": apelido,
		"nome_usuario": usuario,
		"senha": senha
	}

	_definir_ocupado(true)
	_mensagem.text = "Criando conta..."

	var erro: Error = _consulta.request(
		SessaoJogador.ENDERECO_API + "/contas",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(dados)
	)

	_senha.clear()
	_confirmacao.clear()

	if erro != OK:
		_definir_ocupado(false)
		_mensagem.text = "Não foi possível iniciar o cadastro."


func _ao_receber_resposta(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray
) -> void:
	_definir_ocupado(false)

	if resultado != HTTPRequest.RESULT_SUCCESS:
		_mensagem.text = (
			"Não foi possível confirmar o cadastro.\n"
			+ "Tente entrar com os dados escolhidos antes de cadastrar novamente."
		)
		return

	if codigo_http == 429:
		_mensagem.text = (
			"Muitas tentativas de cadastro. "
			+ "Aguarde 60 segundos e tente novamente."
		)
		return

	if codigo_http == 409:
		_mensagem.text = (
			"Esse nome de usuário já está em uso.\n"
			+ "Escolha outro ou volte ao login."
		)
		return

	if codigo_http == 422:
		_mensagem.text = "Confira os dados e os limites dos campos."
		return

	if codigo_http != 201:
		_mensagem.text = (
			"Não foi possível concluir o cadastro no momento."
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		_mensagem.text = (
			"A confirmação recebida é inválida.\n"
			+ "Tente entrar com os dados escolhidos."
		)
		return

	var conta: Dictionary = json.data

	if int(conta.get("id", 0)) <= 0:
		_mensagem.text = (
			"Não foi possível confirmar a conta.\n"
			+ "Tente entrar com os dados escolhidos."
		)
		return

	_conta_criada = true

	_apelido.hide()
	_usuario.hide()
	_senha.hide()
	_confirmacao.hide()
	_criar.hide()

	_mensagem.text = (
		"Conta criada com sucesso!\nUsuário: %s\n"
		+ "Volte ao login para entrar."
	) % str(conta.get("nome_usuario", ""))

	_voltar.grab_focus()


func _definir_ocupado(valor: bool) -> void:
	_ocupado = valor

	_apelido.editable = not valor
	_usuario.editable = not valor
	_senha.editable = not valor
	_confirmacao.editable = not valor

	_criar.disabled = valor
	_voltar.disabled = valor


func _voltar_ao_login() -> void:
	if _ocupado:
		return

	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/tela_login.tscn"
	)

	if erro != OK:
		_mensagem.text = "Não foi possível abrir o login."
