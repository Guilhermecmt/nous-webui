# -*- coding: utf-8 -*-
"""
Nous Monitor - micro-servico local que alimenta o painel de recursos do Nous.

Expoe (em http://127.0.0.1:8990, com CORS liberado p/ o navegador):
  GET  /stats   -> { gpu:{ded_used,ded_total,shr_used,shr_total}, models:[...] }
  POST /unload  -> descarrega modelo(s) do Ollama (libera a VRAM na hora)
                   body opcional: {"model":"gemma4:12b"}; sem body = todos

GPU: lido dos contadores de desempenho do Windows (funcionam em PT-BR com os
nomes em ingles) + tamanho real da VRAM via registro (qwMemorySize).
Modelos: lidos do proprio Ollama (/api/ps), com contagem regressiva de descarga.

Nao usa dependencia nova: aiohttp ja vem no venv do Open WebUI.
"""
import json
import asyncio
from datetime import datetime, timezone

import aiohttp
from aiohttp import web

OLLAMA = "http://127.0.0.1:11434"
PORT = 8990
_GPU_TTL = 2.5  # s de cache p/ nao chamar o powershell a cada poll

# PowerShell que devolve a memoria da GPU (usada + total) em bytes, como JSON.
_PS_GPU = r"""
$ErrorActionPreference='SilentlyContinue'
$c = Get-Counter @('\GPU Adapter Memory(*)\Dedicated Usage','\GPU Adapter Memory(*)\Shared Usage')
$ded = ($c.CounterSamples | Where-Object {$_.Path -like '*dedicated*'} | Measure-Object CookedValue -Sum).Sum
$shr = ($c.CounterSamples | Where-Object {$_.Path -like '*shared*'}    | Measure-Object CookedValue -Sum).Sum
$total = 0
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' | ForEach-Object {
  $v = (Get-ItemProperty $_.PSPath -Name 'HardwareInformation.qwMemorySize').'HardwareInformation.qwMemorySize'
  if ($v -and [int64]$v -gt $total) { $total = [int64]$v }
}
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
[pscustomobject]@{ded_used=[int64]$ded;shr_used=[int64]$shr;ded_total=[int64]$total;shr_total=[int64]($ram/2)} | ConvertTo-Json -Compress
"""

_gpu_cache = {"t": 0.0, "data": None}


async def _read_gpu():
    now = asyncio.get_event_loop().time()
    if _gpu_cache["data"] and (now - _gpu_cache["t"]) < _GPU_TTL:
        return _gpu_cache["data"]
    try:
        proc = await asyncio.create_subprocess_exec(
            "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", _PS_GPU,
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL)
        out, _ = await asyncio.wait_for(proc.communicate(), timeout=8)
        data = json.loads(out.decode("utf-8", "ignore").strip())
    except Exception:
        data = None
    _gpu_cache.update(t=now, data=data)
    return data


async def _read_models():
    try:
        timeout = aiohttp.ClientTimeout(total=5)
        async with aiohttp.ClientSession(timeout=timeout) as s:
            async with s.get(f"{OLLAMA}/api/ps") as r:
                raw = await r.json()
    except Exception:
        return []
    now = datetime.now(timezone.utc)
    out = []
    for m in raw.get("models", []):
        left = None
        exp = m.get("expires_at")
        if exp:
            try:
                dt = datetime.fromisoformat(exp.replace("Z", "+00:00"))
                left = max(0, int((dt - now).total_seconds()))
            except Exception:
                pass
        size = m.get("size", 0) or 0
        vram = m.get("size_vram", 0) or 0
        out.append({"name": m.get("name") or m.get("model"),
                    "vram": vram, "shared": max(0, size - vram),
                    "total": size, "seconds_left": left})
    return out


async def _unload(model=None):
    targets = [model] if model else [m["name"] for m in await _read_models()]
    timeout = aiohttp.ClientTimeout(total=10)
    async with aiohttp.ClientSession(timeout=timeout) as s:
        for t in targets:
            if not t:
                continue
            try:
                async with s.post(f"{OLLAMA}/api/generate",
                                  json={"model": t, "keep_alive": 0}):
                    pass
            except Exception:
                pass
    return targets


# ----------------------------------------------------------------- HTTP / CORS
_CORS = {"Access-Control-Allow-Origin": "*",
         "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
         "Access-Control-Allow-Headers": "Content-Type"}


@web.middleware
async def cors_mw(request, handler):
    if request.method == "OPTIONS":
        return web.Response(status=204, headers=_CORS)
    resp = await handler(request)
    resp.headers.update(_CORS)
    return resp


async def h_stats(request):
    gpu, models = await asyncio.gather(_read_gpu(), _read_models())
    return web.json_response({"gpu": gpu, "models": models})


async def h_unload(request):
    model = None
    try:
        body = await request.json()
        model = (body or {}).get("model")
    except Exception:
        pass
    return web.json_response({"unloaded": await _unload(model)})


async def h_health(request):
    return web.json_response({"ok": True})


def build_app():
    app = web.Application(middlewares=[cors_mw])
    app.add_routes([web.get("/stats", h_stats),
                    web.post("/unload", h_unload),
                    web.get("/health", h_health)])
    return app


if __name__ == "__main__":
    web.run_app(build_app(), host="127.0.0.1", port=PORT, print=None)
