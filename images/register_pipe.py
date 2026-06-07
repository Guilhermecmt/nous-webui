# -*- coding: utf-8 -*-
"""
Registra (ou atualiza) o Pipe "Gerador de Imagem Local" no Open WebUI via API.

Idempotente: cria se nao existir, atualiza se ja existir, e garante que fica
ATIVO. Precisa de uma conta de admin (a primeira conta criada no Nous e' admin).

USO:
    <venv>/Scripts/python.exe images/register_pipe.py \
        --email voce@exemplo.com --password SUASENHA
    (opcionais: --base http://localhost:8080  --pipe caminho/para/nous_image_pipe.py)
"""
import os
import sys
import argparse

try:
    import requests
except ImportError:
    sys.exit("Modulo 'requests' ausente. Rode com o Python do venv do Open WebUI.")

FUNC_ID = "nous_image"
FUNC_NAME = "Gerador de Imagem Local"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost:8080")
    ap.add_argument("--email", required=True)
    ap.add_argument("--password", required=True)
    ap.add_argument("--pipe", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "nous_image_pipe.py"))
    a = ap.parse_args()

    base = a.base.rstrip("/")
    if not os.path.isfile(a.pipe):
        sys.exit(f"Pipe nao encontrado: {a.pipe}")
    content = open(a.pipe, encoding="utf-8").read()

    s = requests.Session()
    try:
        r = s.post(f"{base}/api/v1/auths/signin",
                   json={"email": a.email, "password": a.password}, timeout=20)
        r.raise_for_status()
        token = r.json()["token"]
    except Exception as e:
        sys.exit(f"Falha ao autenticar em {base}: {e}\n"
                 "Crie sua conta no Nous primeiro (a 1a conta vira admin).")
    h = {"Authorization": f"Bearer {token}"}

    form = {"id": FUNC_ID, "name": FUNC_NAME, "content": content,
            "meta": {"description":
                     "Imagem->Flux (ComfyUI); visao+texto->Gemma.",
                     "manifest": {}}}

    exists = s.get(f"{base}/api/v1/functions/id/{FUNC_ID}",
                   headers=h, timeout=20).status_code == 200
    if exists:
        r = s.post(f"{base}/api/v1/functions/id/{FUNC_ID}/update",
                   headers=h, json=form, timeout=30)
        action = "atualizado"
    else:
        r = s.post(f"{base}/api/v1/functions/create",
                   headers=h, json=form, timeout=30)
        action = "criado"
    if r.status_code != 200:
        sys.exit(f"Falha ao registrar o Pipe ({r.status_code}): {r.text[:300]}")

    # Garante que esta ativo
    info = s.get(f"{base}/api/v1/functions/id/{FUNC_ID}", headers=h, timeout=20)
    if info.status_code == 200 and not info.json().get("is_active", False):
        s.post(f"{base}/api/v1/functions/id/{FUNC_ID}/toggle", headers=h, timeout=20)

    print(f"Pipe '{FUNC_NAME}' {action} e ativo. "
          "Selecione-o no topo do chat do Nous.")


if __name__ == "__main__":
    main()
