class_name JogadorPartida
extends RefCounted

var nome: String
var bolinha: Bolinha
var _pontos: int = 0


func _init(nome_inicial: String, bolinha_inicial: Bolinha) -> void:
	nome = nome_inicial
	bolinha = bolinha_inicial


func adicionar_pontos(quantidade: int) -> void:
	_pontos += quantidade


func obter_pontos() -> int:
	return _pontos
