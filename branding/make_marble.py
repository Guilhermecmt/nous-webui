# -*- coding: utf-8 -*-
"""Marmore com veios de ouro (escuro e claro) para o fundo do Nous.
Veios = isolinhas de ruido (distancia normalizada pelo gradiente => espessura
constante, finos e organicos como marmore real)."""
import os
import numpy as np
from PIL import Image, ImageFilter

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "branding", "assets")
W = H = 1500


def smooth_noise(scale, rng):
    s = max(2, W // scale)
    base = rng.random((s, s)).astype(np.float32)
    img = Image.fromarray((base * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    return np.asarray(img, dtype=np.float32) / 255.0


def turbulence(seed):
    rng = np.random.default_rng(seed)
    t = np.zeros((H, W), np.float32); amp = 1.0
    for sc in (200, 100, 50):
        t += smooth_noise(sc, rng) * amp; amp *= 0.5
    return (t - t.min()) / (t.max() - t.min())


def blur01(a, r):
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    return np.asarray(im, dtype=np.float32) / 255.0


def isolines(turb, levels, linewidth):
    gy, gx = np.gradient(turb)
    gmag = np.hypot(gx, gy) + 1e-6
    v = np.zeros((H, W), np.float32)
    for lv in levels:
        dist = (turb - lv) / gmag          # ~distancia em pixels ate o veio
        v = np.maximum(v, np.exp(-(dist / linewidth) ** 2))
    return v


def marble(gold_lo, gold_hi, base_top, base_bottom, levels, linewidth=2.8):
    yy = np.linspace(0, 1, H)[:, None]
    xx = np.linspace(0, 1, W)[None, :]
    t1 = turbulence(3)
    t2 = turbulence(21)
    veins = np.maximum(isolines(t1, levels, linewidth),
                       0.75 * isolines(t2, levels[1::2], linewidth * 1.1))
    veins = np.clip(veins, 0, 1)
    glow = blur01(veins, 3)

    diag = (xx + yy) / 2.0
    base = np.array(base_top, float) * (1 - diag[..., None]) + np.array(base_bottom, float) * diag[..., None]
    base = np.clip(base + (t1[..., None] - 0.5) * 7, 0, 255)   # mosqueado bem sutil

    goldcol = np.array(gold_lo, float) * (1 - t1[..., None]) + np.array(gold_hi, float) * t1[..., None]
    out = base * (1 - veins[..., None]) + goldcol * veins[..., None]
    out = np.clip(out + glow[..., None] * 0.12 * np.array(gold_hi, float), 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGB").filter(ImageFilter.GaussianBlur(0.5))


LEVELS = [0.30, 0.45, 0.60, 0.75]
dark = marble((150, 110, 40), (242, 208, 124), base_top=(26, 24, 30), base_bottom=(6, 6, 9), levels=LEVELS)
light = marble((150, 112, 38), (210, 172, 84), base_top=(252, 250, 247), base_bottom=(234, 229, 220), levels=LEVELS)

dark.save(os.path.join(ASSETS, "marble-dark.png"))
light.save(os.path.join(ASSETS, "marble-light.png"))
combo = Image.new("RGB", (1500, 750))
combo.paste(dark.resize((750, 750)), (0, 0))
combo.paste(light.resize((750, 750)), (750, 0))
combo.save(os.path.join(ASSETS, "marble-preview.png"))
print("OK: marble gerado")
