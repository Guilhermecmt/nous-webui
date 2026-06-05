# -*- coding: utf-8 -*-
"""
Nous WebUI - Preparador de logo.

Converte uma imagem-fonte (ex.: coruja dourada em fundo escuro) na logo-mestre
transparente usada pelo app: remove o fundo, recorta justo e centraliza.

Uso:
    python prepare_logo.py --source caminho/para/imagem.png
    (padrao do source: branding/assets/source-logo.png)
    (saida: branding/assets/nous_logo.png)
"""
import argparse, os
import numpy as np
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "branding", "assets")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default=os.path.join(ASSETS, "source-logo.png"))
    ap.add_argument("--out", default=os.path.join(ASSETS, "nous_logo.png"))
    ap.add_argument("--lo", type=float, default=24.0, help="luminancia minima (fundo)")
    ap.add_argument("--hi", type=float, default=105.0, help="luminancia maxima (traco)")
    args = ap.parse_args()

    src = Image.open(args.source).convert("RGB")
    arr = np.asarray(src).astype(np.float32)
    L = 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]

    alpha = np.clip((L - args.lo) / (args.hi - args.lo), 0, 1)
    alpha = alpha * alpha * (3 - 2 * alpha)  # smoothstep
    af = np.clip(alpha[..., None], 0.0001, 1.0)
    rgb = np.clip(arr / af, 0, 255).astype(np.uint8)  # unpremultiply -> ouro limpo
    a8 = (alpha * 255).astype(np.uint8)
    img = Image.fromarray(np.dstack([rgb, a8]), "RGBA")

    ys, xs = np.where(a8 > 16)
    crop = img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    w, h = crop.size
    pad = int(max(w, h) * 0.07)
    side = max(w, h) + 2 * pad
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(crop, ((side - w) // 2, (side - h) // 2))
    canvas.resize((512, 512), Image.LANCZOS).save(args.out)
    print("Logo-mestre gerada:", args.out)


if __name__ == "__main__":
    main()
