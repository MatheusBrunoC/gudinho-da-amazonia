extends Control

@onready var _nome: Label = $Centro/Opcoes/NomeJogador
@onready var _historico: VBoxContainer = $Centro/Opcoes/Historico
@onready var _lista: RichTextLabel = (
	$Centro/Opcoes/Historico/ListaHistorico
)
@onready var _atualizar: Button = (
	$Centro/Opcoes/Historico/BotaoAtualizar
)
@onready var _sair_perfil: Button = $Centro/Opcoes/BotaoSairPerfil
@onready var _voltar: Button = $BotaoVoltar
@onready var _consulta: HTTPRequest = $ConsultaHistorico

var _ocupado: bool = false
var _operacao: String = ""


func _ready() -> void:
	_voltar.pressed.connect(_voltar_ao_menu)
	_sair_perfil.pressed.connect(_sair_do_perfil)
	_atualizar.pressed.connect(_carregar_perfil)

	_consulta.timeout = 90.0
	_consulta.request_completed.connect(_ao_receber_resposta)

	_nome.text = "Carregando perfil..."
	_historico.hide()
	_sair_perfil.hide()

	if not SessaoJogador.possui_sessao():
		_abrir_login.call_deferred()
		return

	_sair_perfil.show()
	_carregar_perfil()


func _carregar_perfil() -> void:
	if _ocupado:
		return

	_historico.show()
	_lista.text = "Carregando..."
	_requisitar("perfil", "/me")


func _requisitar(operacao: String, caminho: String) -> void:
	if not SessaoJogador.possui_sessao():
		_encerrar_sessao()
		return

	_operacao = operacao
	_ocupado = true
	_atualizar.disabled = true

	var erro: Error = _consulta.request(
		SessaoJogador.ENDERECO_API + caminho,
		SessaoJogador.obter_cabecalhos()
	)

	if erro != OK:
		_ocupado = false
		_atualizar.disabled = false
		_lista.text = "Não foi possível iniciar a consulta."


func _ao_receber_resposta(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray
) -> void:
	_ocupado = false
	_atualizar.disabled = false

	if resultado != HTTPRequest.RESULT_SUCCESS:
		_lista.text = (
			"Sem conexão com a API.\n"
			+ "Verifique o servidor e clique em Atualizar histórico."
		)
		return

	if codigo_http == 401:
		_encerrar_sessao()
		return

	if codigo_http != 200:
		_lista.text = (
			"Não foi possível carregar os dados.\n"
			+ "Código HTTP: %d" % codigo_http
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		_lista.text = "A API retornou uma resposta inválida."
		return

	var dados: Dictionary = json.data

	if _operacao == "perfil":
		if not dados.get("apelido") is String:
			_lista.text = "A resposta não contém o nome do jogador."
			return

		_nome.text = "Jogador: %s" % str(dados["apelido"])
		_requisitar("historico", "/me/treinos?limite=10")
		return

	_mostrar_historico(dados)


func _mostrar_historico(dados: Dictionary) -> void:
	if not dados.get("treinos") is Array:
		_lista.text = "A resposta não contém uma lista de treinos."
		return

	var treinos: Array = dados["treinos"]

	if treinos.is_empty():
		_lista.text = (
			"Você ainda não possui treinos registrados.\n"
			+ "Conclua um confronto contra o computador para começar!"
		)
		return

	var linhas: PackedStringArray = PackedStringArray()

	for item in treinos:
		if not item is Dictionary:
			continue

		var treino: Dictionary = item
		var resultado_texto: String = "Resultado indisponível"

		match str(treino.get("resultado", "")):
			"vitoria":
				resultado_texto = "Vitória"
			"derrota":
				resultado_texto = "Derrota"
			"empate":
				resultado_texto = "Empate"

		linhas.append(
			"%s — %s\nVocê: %d × Computador: %d" % [
				_formatar_data(str(treino.get("criado_em", ""))),
				resultado_texto,
				int(treino.get("pontos_jogador", 0)),
				int(treino.get("pontos_computador", 0))
			]
		)

	_lista.text = "\n\n".join(linhas)
	_lista.scroll_to_line(0)


func _formatar_data(valor: String) -> String:
	if valor.length() < 16:
		return valor

	return "%s/%s/%s às %s" % [
		valor.substr(8, 2),
		valor.substr(5, 2),
		valor.substr(0, 4),
		valor.substr(11, 5)
	]


func _sair_do_perfil() -> void:
	_encerrar_sessao()


func _encerrar_sessao() -> void:
	_consulta.cancel_request()
	_ocupado = false

	SessaoJogador.sair()

	_nome.text = "Entre na sua conta."
	_lista.text = ""
	_historico.hide()
	_sair_perfil.hide()

	_abrir_login()


func _abrir_login() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/tela_login.tscn"
	)

	if erro != OK:
		_historico.show()
		_lista.text = "Não foi possível abrir a tela de login."


func _voltar_ao_menu() -> void:
	var erro: Error = get_tree().change_scene_to_file(
		"res://cenas/menu_inicial.tscn"
	)

	if erro != OK:
		_historico.show()
		_lista.text = "Não foi possível voltar ao menu."
