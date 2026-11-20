"""Teste local sem banco: python -m unittest testar_cors.py (requer httpx)."""
import os
import unittest

# Apenas para importar a API durante o teste; não define segredos de produção.
os.environ.setdefault("JWT_SECRET", "chave-exclusiva-para-testes-locais-" * 3)
os.environ["CORS_ORIGINS"] = "https://lively-sunburst-2446bf.netlify.app"

from fastapi.testclient import TestClient
from main import app


class TesteCORS(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.origem = os.environ["CORS_ORIGINS"]

    def test_preflight_das_rotas_do_jogo(self):
        for rota, metodo in [
            ("/auth/login", "POST"), ("/contas", "POST"),
            ("/treinos", "POST"), ("/me", "GET"), ("/me/treinos", "GET"),
        ]:
            with self.subTest(rota=rota):
                resposta = self.client.options(rota, headers={
                    "Origin": self.origem,
                    "Access-Control-Request-Method": metodo,
                    "Access-Control-Request-Headers": "content-type,authorization",
                })
                self.assertEqual(resposta.status_code, 200)
                self.assertEqual(resposta.headers["access-control-allow-origin"], self.origem)

    def test_perfil_continua_exigindo_autenticacao(self):
        resposta = self.client.get("/me", headers={"Origin": self.origem})
        self.assertEqual(resposta.status_code, 401)
        self.assertEqual(resposta.headers["access-control-allow-origin"], self.origem)

    def test_origem_nao_autorizada(self):
        resposta = self.client.options("/auth/login", headers={
            "Origin": "https://outro-site.example",
            "Access-Control-Request-Method": "POST",
        })
        self.assertEqual(resposta.status_code, 400)
        self.assertNotIn("access-control-allow-origin", resposta.headers)
