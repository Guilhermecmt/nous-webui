# -*- coding: utf-8 -*-
"""
Nous WebUI - Redefinir a senha de um usuario (uso local pelo dono da maquina).

Edita diretamente o banco local (bcrypt). Util quando se esquece a senha e
nao ha servidor de e-mail configurado.

Uso:
    python reset-password.py --email voce@exemplo.com --password NovaSenha
    python reset-password.py --email voce@exemplo.com           (senha aleatoria)

A senha NUNCA fica escrita neste arquivo - e passada por argumento ou gerada.
"""
import argparse, os, sqlite3, secrets, string

try:
    import bcrypt
except ImportError:
    raise SystemExit("bcrypt nao encontrado. Rode com o Python do ambiente do Open WebUI.")


def default_db():
    data = os.environ.get("DATA_DIR") or os.environ.get("NOUS_DATA_DIR") \
        or os.path.join(os.path.expanduser("~"), "NousData")
    return os.path.join(data, "webui.db")


def gen_password(n=16):
    alpha = string.ascii_letters + string.digits + "@#%&*"
    return "".join(secrets.choice(alpha) for _ in range(n))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--email", required=True)
    ap.add_argument("--password", default=None, help="se omitido, gera uma senha aleatoria")
    ap.add_argument("--db", default=default_db())
    args = ap.parse_args()

    if not os.path.exists(args.db):
        raise SystemExit(f"Banco nao encontrado: {args.db}")

    pwd = args.password or gen_password()
    h = bcrypt.hashpw(pwd.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    con = sqlite3.connect(args.db)
    cur = con.execute("UPDATE auth SET password=?, active=1 WHERE email=?", (h, args.email))
    con.commit(); con.close()

    if cur.rowcount == 0:
        raise SystemExit(f"Nenhum usuario com o e-mail {args.email}")
    print(f"Senha redefinida para: {args.email}")
    print(f"Nova senha: {pwd}")
    print("Entre e troque-a em Settings > Account.")


if __name__ == "__main__":
    main()
