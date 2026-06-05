<#
  Nous WebUI - Iniciar (em segundo plano, sem janela de terminal).
  Sobe o Ollama (se preciso) + o servidor Nous OCULTO e abre o navegador.
  Compile para .exe com build-exe.ps1 (-noConsole) para nao mostrar janela.
  Para encerrar: use stop-nous.ps1 (ou o atalho "Parar Nous").
#>
$ErrorActionPreference = "SilentlyContinue"

$venv = Join-Path $env:USERPROFILE "open-webui"
$exe  = Join-Path $venv "Scripts\open-webui.exe"
$url  = "http://localhost:8080"

# --- Configuracao ---
$env:WEBUI_NAME          = "Nous"
$env:DATA_DIR            = Join-Path $env:USERPROFILE "NousData"
$env:OLLAMA_BASE_URL     = "http://127.0.0.1:11434"
$env:ENABLE_WEB_SEARCH   = "True"
$env:WEB_SEARCH_ENGINE   = "duckduckgo"
$env:WEB_SEARCH_RESULT_COUNT = "5"
$env:ENABLE_RAG_WEB_SEARCH   = "True"
$env:RAG_WEB_SEARCH_ENGINE   = "duckduckgo"
$env:PORT                = "8080"

# Sugestoes da tela inicial (substitui as genericas em ingles)
$env:DEFAULT_PROMPT_SUGGESTIONS = '[{"title":["Resumir um texto","cole o conteudo e peca um resumo claro"],"content":"Resuma o texto a seguir de forma clara e objetiva:\n\n"},{"title":["Escrever um e-mail","profissional e direto"],"content":"Escreva um e-mail profissional sobre: "},{"title":["Explicar um conceito","de forma simples"],"content":"Explique de forma simples o conceito de: "},{"title":["Ideias criativas","para um projeto"],"content":"Me de 5 ideias criativas para: "}]'

function Test-Up {
    try { return (Invoke-WebRequest "$url/health" -TimeoutSec 3 -UseBasicParsing).StatusCode -eq 200 }
    catch { return $false }
}

# Ja esta rodando? So abre o navegador.
if (Test-Up) { Start-Process $url; return }

# Garante o Ollama (em segundo plano)
try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" -TimeoutSec 3 | Out-Null }
catch {
    $ollama = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama app.exe"
    if (Test-Path $ollama) { Start-Process $ollama -WindowStyle Hidden }
    Start-Sleep -Seconds 4
}

# Sobe o servidor OCULTO (sem janela) e desanexa
Start-Process -FilePath $exe -ArgumentList "serve" -WindowStyle Hidden

# Espera ficar pronto e abre o navegador
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 2
    if (Test-Up) { Start-Process $url; break }
}
