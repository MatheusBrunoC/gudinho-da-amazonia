extends VBoxContainer

const ARQUIVO_PERFIL: String = "user://perfil.cfg"

@onready var _texto: Label = $TextoPerfil
@onready var _apelido: LineEdit = $Apelido
@onready var _criar: Button = $CriarPerfil
@onready var _tentar: Button = $TentarNovamente
@onready var _consulta: ConsultaPerfil = $ConsultaPerfil

@onready var _escolher: HBoxContainer = $EscolherPerfil
@onready var _lista_perfis: OptionButton = $EscolherPerfil/ListaPerfis
@onready var _usar_perfil: Button = $EscolherPerfil/UsarPerfil
@onready var _consulta_lista: HTTPRequest = $ConsultaLista

var _jogador_id: int = 0
var _ocupado: bool = false


func _ready() -> void:
	_consulta.perfil_carregado.connect(_ao_carregar_perfil)
	_consulta.consulta_falhou.connect(_ao_falhar_consulta)

	_criar.pressed.connect(_cadastrar)
	_tentar.pressed.connect(_tentar_novamente)

	_tentar.hide()

	_escolher.hide()
	_usar_perfil.pressed.connect(_usar_perfil_selecionado)
	_lista_perfis.item_selected.connect(_ao_selecionar_item)

	_consulta_lista.timeout = 90.0
	_consulta_lista.request_completed.connect(_ao_receber_lista)

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
	_texto.text = "Escolha um perfil ou crie um novo."
	_apelido.show()
	_criar.show()
	_escolher.show()
	_tentar.hide()
	_definir_ocupado(false)
	_carregar_lista_perfis()

func _bloquear_cadastro(mensagem: String) -> void:
	_texto.text = mensagem
	_apelido.hide()
	_criar.hide()
	_tentar.hide()
	_escolher.hide()

func _definir_ocupado(valor: bool) -> void:
	_ocupado = valor

	_apelido.editable = not valor
	_criar.disabled = valor
	_tentar.disabled = valor

	_lista_perfis.disabled = valor or _lista_perfis.item_count <= 1
	_usar_perfil.disabled = (
		valor or _lista_perfis.get_selected_id() <= 0
	)

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
	_escolher.hide()
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

func _carregar_lista_perfis() -> void:
	if _ocupado:
		return

	_lista_perfis.clear()
	_lista_perfis.add_item("Selecione um perfil", 0)
	_lista_perfis.set_item_disabled(0, true)
	_lista_perfis.select(0)

	_texto.text = "Carregando perfis..."
	_tentar.hide()
	_definir_ocupado(true)

	var endereco: String = (
		_consulta.endereco_api.trim_suffix("/")
		+ "/jogadores?limite=100"
	)

	var erro: Error = _consulta_lista.request(endereco)

	if erro != OK:
		_falhar_lista(
			"Não foi possível iniciar a consulta dos perfis."
		)


func _ao_receber_lista(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray
) -> void:
	if resultado != HTTPRequest.RESULT_SUCCESS:
		_falhar_lista(
			"Sem conexão com a API. Clique em Tentar novamente."
		)
		return

	if codigo_http != 200:
		_falhar_lista(
			"Não foi possível listar os perfis. HTTP %d."
			% codigo_http
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		_falhar_lista("A API retornou uma resposta inválida.")
		return

	var dados: Dictionary = json.data

	if not dados.get("jogadores") is Array:
		_falhar_lista("A resposta não contém uma lista de jogadores.")
		return

	var jogadores: Array = dados["jogadores"]

	for item in jogadores:
		if not item is Dictionary:
			continue

		var jogador: Dictionary = item
		var identificador: int = int(jogador.get("id", 0))
		var nome: String = str(jogador.get("apelido", ""))

		if identificador <= 0 or nome.is_empty():
			continue

		_lista_perfis.add_item(
			"%s — #%d" % [nome, identificador],
			identificador
		)

	_definir_ocupado(false)
	_tentar.hide()

	if _lista_perfis.item_count <= 1:
		_texto.text = "Nenhum perfil cadastrado. Crie o primeiro!"
	else:
		_texto.text = "Escolha um perfil ou crie um novo."


func _falhar_lista(mensagem: String) -> void:
	_definir_ocupado(false)
	_texto.text = mensagem
	_tentar.show()


func _ao_selecionar_item(_indice: int) -> void:
	_definir_ocupado(_ocupado)


func _usar_perfil_selecionado() -> void:
	if _ocupado:
		return

	var identificador: int = _lista_perfis.get_selected_id()

	if identificador <= 0:
		return

	_jogador_id = identificador
	_consultar_perfil()


func _tentar_novamente() -> void:
	if _ocupado:
		return

	if _jogador_id > 0:
		_consultar_perfil()
	else:
		_carregar_lista_perfis()
