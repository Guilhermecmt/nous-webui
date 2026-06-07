# -*- coding: utf-8 -*-
"""
Nous WebUI - Aplicador de identidade visual.

Aplica em uma instalacao existente do Open WebUI:
  - a logo (coruja Nous) em todos os favicons/logos/splash
  - favicon.svg (PNG embutido) e favicon.ico
  - o tema "Branco & Ouro" (static/custom.css)
  - o comportamento extra (static/loader.js): botao de tema claro/escuro
  - o nome do app "Nous" (sem o sufixo "(Open WebUI)")

Portatil: localiza o Open WebUI via `import open_webui`, entao funciona em
qualquer maquina, desde que rodado com o Python do ambiente que tem o
open-webui instalado:

    <venv>/Scripts/python.exe  branding/apply_branding.py
"""
import os, io, base64, shutil
from PIL import Image

try:
    import open_webui
except ImportError:
    raise SystemExit(
        "open_webui nao encontrado. Rode este script com o Python do ambiente "
        "que tem o Open WebUI instalado (ex.: <venv>/Scripts/python.exe)."
    )

OW = os.path.dirname(open_webui.__file__)
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "branding", "assets")
MASTER = os.path.join(ASSETS, "nous_logo.png")
CSS_SRC = os.path.join(REPO, "branding", "nous-gold.css")
JS_SRC = os.path.join(REPO, "branding", "nous-loader.js")
BACKUP = os.path.join(REPO, "bkp", "openwebui-originais")
os.makedirs(BACKUP, exist_ok=True)

STATIC_DIRS = {
    "static": os.path.join(OW, "static"),
    "frontend_static": os.path.join(OW, "frontend", "static"),
}
# nome -> tamanho padrao (px) usado SE o arquivo ainda nao existir.
# Importante: o frontend referencia /static/favicon.png e /static/splash.png;
# se faltarem, a logo/splash quebram (404). Por isso criamos os que faltam.
IMG_TARGETS = {
    "apple-touch-icon.png": 180,
    "favicon-96x96.png": 96,
    "favicon-dark.png": 512,
    "favicon.png": 512,
    "logo.png": 512,
    "splash.png": 512,
    "splash-dark.png": 512,
    "web-app-manifest-192x192.png": 192,
    "web-app-manifest-512x512.png": 512,
}


def backup(path, label):
    if os.path.exists(path):
        b = os.path.join(BACKUP, f"{label}__{os.path.basename(path)}")
        if not os.path.exists(b):
            shutil.copy2(path, b)


def _fit(master, w, h):
    """Redimensiona a logo p/ (w,h). Se nao for quadrada, centraliza com fundo
    transparente (preserva o formato esperado pelo frontend)."""
    if w == h:
        return master.resize((w, h), Image.LANCZOS)
    side = min(w, h)
    m = master.resize((side, side), Image.LANCZOS)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(m, ((w - side) // 2, (h - side) // 2), m)
    return out


def apply_images(master):
    # frontend/favicon.png (raiz)
    extra = os.path.join(OW, "frontend", "favicon.png")
    if os.path.exists(extra):
        backup(extra, "frontend")
        with Image.open(extra) as im:
            w, h = im.size
        _fit(master, w, h).save(extra)
    for label, d in STATIC_DIRS.items():
        if not os.path.isdir(d):
            continue
        for name, default in IMG_TARGETS.items():
            p = os.path.join(d, name)
            if os.path.exists(p):
                backup(p, label)
                with Image.open(p) as im:
                    w, h = im.size
            else:
                w = h = default  # cria do zero (instalacao que nao trazia o arquivo)
            _fit(master, w, h).save(p)


def apply_favicons_and_css(master):
    small = master.resize((128, 128), Image.LANCZOS)
    buf = io.BytesIO(); small.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode()
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" '
        'viewBox="0 0 128 128"><image href="data:image/png;base64,'
        + b64 + '" width="128" height="128"/></svg>'
    )
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    css = open(CSS_SRC, encoding="utf-8").read()
    js = open(JS_SRC, encoding="utf-8").read() if os.path.exists(JS_SRC) else ""
    for label, d in STATIC_DIRS.items():
        if not os.path.isdir(d):
            continue
        for f in ("custom.css", "loader.js", "favicon.svg", "favicon.ico"):
            backup(os.path.join(d, f), label)
        open(os.path.join(d, "custom.css"), "w", encoding="utf-8").write(css)
        if js:
            open(os.path.join(d, "loader.js"), "w", encoding="utf-8").write(js)
        open(os.path.join(d, "favicon.svg"), "w", encoding="utf-8").write(svg)
        master.save(os.path.join(d, "favicon.ico"), sizes=ico_sizes)


def patch_name(app_name="Nous"):
    env = os.path.join(OW, "env.py")
    src = open(env, encoding="utf-8").read()
    old = (
        "WEBUI_NAME = os.getenv('WEBUI_NAME', 'Open WebUI')\n"
        "if WEBUI_NAME != 'Open WebUI':\n"
        "    WEBUI_NAME += ' (Open WebUI)'"
    )
    new = f"WEBUI_NAME = os.getenv('WEBUI_NAME') or '{app_name}'"
    if new in src:
        return "ja aplicado"
    if old in src:
        backup(env, "env")
        open(env, "w", encoding="utf-8", newline="\n").write(src.replace(old, new))
        return "patch aplicado"
    return "PADRAO NAO ENCONTRADO (versao diferente do Open WebUI?)"


def main():
    if not os.path.exists(MASTER):
        raise SystemExit(f"Logo-mestre nao encontrada: {MASTER}")
    master = Image.open(MASTER).convert("RGBA")
    print("Open WebUI em:", OW)
    apply_images(master);            print("  [ok] logos/favicons (png)")
    apply_favicons_and_css(master);  print("  [ok] favicon.svg/.ico + tema custom.css + loader.js")
    print("  [nome]", patch_name())
    print("\nIdentidade Nous aplicada. Reinicie o servidor e use Ctrl+Shift+R no navegador.")


if __name__ == "__main__":
    main()
