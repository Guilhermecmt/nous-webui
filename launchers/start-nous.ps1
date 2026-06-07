<#
  Nous WebUI - Iniciar (em segundo plano, sem janela de terminal).
  Sobe o Ollama (se preciso) + o servidor Nous OCULTO e abre o navegador.
  Compile para .exe com build-exe.ps1 (-noConsole) para nao mostrar janela.
  Para encerrar: use stop-nous.ps1 (ou o atalho "Parar Nous").
#>
$ErrorActionPreference = "SilentlyContinue"

$venv = Join-Path $env:USERPROFILE "open-webui"
$exe  = Join-Path $venv "Scripts\open-webui.exe"
$py   = Join-Path $venv "Scripts\python.exe"
$url  = "http://localhost:8080"

# --- Configuracao ---
$env:WEBUI_NAME          = "Nous"
$env:DATA_DIR            = Join-Path $env:USERPROFILE "NousData"
$env:OLLAMA_BASE_URL     = "http://127.0.0.1:11434"
# Modelo sai da VRAM 30s apos a ultima mensagem (era 5 min). O Pipe ja envia
# keep_alive por requisicao; isto cobre tambem clientes diretos do Ollama.
$env:OLLAMA_KEEP_ALIVE   = "30s"
$env:ENABLE_WEB_SEARCH   = "True"
$env:WEB_SEARCH_ENGINE   = "duckduckgo"
$env:WEB_SEARCH_RESULT_COUNT = "5"
$env:ENABLE_RAG_WEB_SEARCH   = "True"
$env:RAG_WEB_SEARCH_ENGINE   = "duckduckgo"
# Injeta os resultados da busca direto no contexto (sem exigir modelo de
# embedding) - sem isto, o Gemma responde "nao tenho acesso em tempo real".
$env:BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL = "True"
$env:PORT                = "8080"

# Chave secreta ESTAVEL: sem ela, o open-webui gera uma nova a cada inicio e
# desloga voce. Guardamos uma chave local (em NousData, fora do git) e a reusamos.
$keyFile = Join-Path $env:DATA_DIR ".webui_secret_key"
if (-not (Test-Path $keyFile)) {
    New-Item -ItemType Directory -Force -Path $env:DATA_DIR | Out-Null
    $bytes = New-Object 'byte[]' 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $key = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
    [IO.File]::WriteAllText($keyFile, $key)
}
$env:WEBUI_SECRET_KEY = (Get-Content $keyFile -Raw).Trim()

# Sugestoes da tela inicial (substitui as genericas em ingles)
$env:DEFAULT_PROMPT_SUGGESTIONS = '[{"title":["Resumir um texto","cole o conteudo e peca um resumo claro"],"content":"Resuma o texto a seguir de forma clara e objetiva:\n\n"},{"title":["Escrever um e-mail","profissional e direto"],"content":"Escreva um e-mail profissional sobre: "},{"title":["Explicar um conceito","de forma simples"],"content":"Explique de forma simples o conceito de: "},{"title":["Ideias criativas","para um projeto"],"content":"Me de 5 ideias criativas para: "}]'

function Test-Up {
    try { return (Invoke-WebRequest "$url/health" -TimeoutSec 3 -UseBasicParsing).StatusCode -eq 200 }
    catch { return $false }
}

# Garante a memoria nativa (Filter global e ativo) registrada no banco.
# Idempotente, sem login: re-sincroniza nous_memory.py a cada inicio.
function Register-Memory {
    $reg = Join-Path $PSScriptRoot "..\memory\register_memory.py"
    if ((Test-Path $py) -and (Test-Path $reg)) {
        & $py "$reg" --data-dir "$env:DATA_DIR" | Out-Null
    }
}

# Garante o Pipe de imagem registrado no banco (sem credenciais).
# So' faz algo se nous_image_pipe.py existir (ComfyUI instalado).
function Register-Pipe {
    $reg = Join-Path $PSScriptRoot "..\images\register_pipe_auto.py"
    if ((Test-Path $py) -and (Test-Path $reg)) {
        & $py "$reg" --data-dir "$env:DATA_DIR" | Out-Null
    }
}

# Ja esta rodando? Garante funcoes nativas e abre o navegador.
if (Test-Up) { Register-Memory; Register-Pipe; Start-Process $url; return }

# Garante o Ollama (em segundo plano)
try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" -TimeoutSec 3 | Out-Null }
catch {
    $ollama = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama app.exe"
    if (Test-Path $ollama) { Start-Process $ollama -WindowStyle Hidden }
    Start-Sleep -Seconds 4
}

# Sobe o servidor OCULTO (sem janela) e desanexa
Start-Process -FilePath $exe -ArgumentList "serve" -WindowStyle Hidden

# Sobe o Nous Monitor (painel de VRAM / modelos) em segundo plano
$monitor = Join-Path $PSScriptRoot "..\monitor\nous_monitor.py"
if ((Test-Path $py) -and (Test-Path $monitor)) {
    try { Invoke-RestMethod "http://127.0.0.1:8990/health" -TimeoutSec 2 | Out-Null }
    catch { Start-Process -FilePath $py -ArgumentList "`"$monitor`"" -WindowStyle Hidden }
}

# Espera ficar pronto, garante funcoes nativas e abre o navegador
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 2
    if (Test-Up) { Register-Memory; Register-Pipe; Start-Process $url; break }
}
