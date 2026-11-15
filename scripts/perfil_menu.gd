extends VBoxContainer

const ARQUIVO_PERFIL: String = "user://perfil.cfg"

@onready var _texto: Label = $TextoPerfil
@onready var _apelido: LineEdit = $Apelido
@onready var _criar: Button = $CriarPerfil
@onready var _tentar: Button = $TentarNovamente
@onready var _consulta: ConsultaPerfil = $ConsultaPerfil

var _jogador_id: int = 0
var _ocupado: bool = false


func _ready() -> void:
	_consulta.perfil_carregado.connect(_ao_carregar_perfil)
	_consulta.consulta_falhou.connect(_ao_falhar_consulta)

	_criar.pressed.connect(_cadastrar)
	_tentar.pressed.connect(_consultar_perfil)

	_tentar.hide()

	var configuracao: ConfigFile = ConfigFile.new()
	var erro: Error = configuracao.load(ARQUIVO_PERFIL)

	if erro == ERR_FILE_NOT_FOUND:
		_mostrar_cadastro()
		return

	if erro != OK:
		_bloquear_cadastro(
			"Não foi possível ler o perfil salvo neste computador."
		)
		return

	_jogador_id = int(
		configuracao.get_value("jogador", "id", 0)
	)

	if _jogador_id < 1:
		_bloquear_cadastro("O identificador do perfil salvo é inválido.")
		return

	_consultar_perfil()


func _mostrar_cadastro() -> void:
	_texto.text = "Crie seu perfil para guardar seus resultados."
	_apelido.show()
	_criar.show()
	_tentar.hide()
	_definir_ocupado(false)


func _bloquear_cadastro(mensagem: String) -> void:
	_texto.text = mensagem
	_apelido.hide()
	_criar.hide()
	_tentar.hide()


func _definir_ocupado(valor: bool) -> void:
	_ocupado = valor
	_apelido.editable = not valor
	_criar.disabled = valor
	_tentar.disabled = valor


func _cadastrar() -> void:
	if _ocupado:
		return

	var nome: String = _apelido.text.strip_edges()

	if nome.is_empty() or nome.length() > 30:
		_texto.text = "Use um apelido de 1 a 30 caracteres."
		return

	_texto.text = "Criando perfil…"
	_definir_ocupado(true)
	_consulta.cadastrar(nome)


func _consultar_perfil() -> void:
	if _ocupado or _jogador_id < 1:
		return

	_apelido.hide()
	_criar.hide()
	_tentar.hide()
	_texto.text = "Carregando perfil…"

	_definir_ocupado(true)
	_consulta.consultar(_jogador_id)


func _ao_carregar_perfil(perfil: Dictionary) -> void:
	_definir_ocupado(false)

	var id_recebido: int = int(perfil.get("id", 0))

	if id_recebido < 1:
		_ao_falhar_consulta("A API retornou um identificador inválido.")
		return

	_jogador_id = id_recebido

	var configuracao: ConfigFile = ConfigFile.new()
	configuracao.set_value("jogador", "id", _jogador_id)

	var erro: Error = configuracao.save(ARQUIVO_PERFIL)

	_apelido.hide()
	_criar.hide()
	_tentar.hide()

	var nome: String = str(perfil["apelido"])

	if erro != OK:
		_texto.text = (
			"Perfil: %s\nNão foi possível lembrar este perfil "
			+ "no computador. ID: %d."
		) % [nome, _jogador_id]

		print("Erro ao salvar perfil local: ", error_string(erro))
		return

	_texto.text = "Jogador: %s" % nome


func _ao_falhar_consulta(mensagem: String) -> void:
	_definir_ocupado(false)
	_texto.text = mensagem
	_tentar.visible = _jogador_id > 0

	print("Consulta do perfil: ", mensagem)
