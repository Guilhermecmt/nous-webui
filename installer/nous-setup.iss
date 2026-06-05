; ============================================================
;  Nous - Instalador (Inno Setup)
;  Gera Nous-Setup.exe: instalador online pequeno que baixa e
;  configura tudo (Ollama, Python, Open WebUI) na maquina do usuario.
;  Compilar:  ISCC.exe nous-setup.iss
; ============================================================

#define MyAppName "Nous"
#define MyAppVersion "1.3.0"
#define MyAppPublisher "Nous"
#define MyAppURL "https://github.com/Guilhermecmt/nous-webui"

[Setup]
AppId={{8E5F2B41-9C3A-4D7E-AB12-A1B2C3D4E5F6}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\Nous
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=Nous-Setup
SetupIconFile=..\branding\assets\nous.ico
UninstallDisplayIcon={app}\launchers\Nous.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na Area de Trabalho"; GroupDescription: "Atalhos:"

[Files]
Source: "..\branding\*"; DestDir: "{app}\branding"; Flags: recursesubdirs ignoreversion
Source: "..\launchers\*"; DestDir: "{app}\launchers"; Flags: recursesubdirs ignoreversion
Source: "..\tools\*"; DestDir: "{app}\tools"; Flags: recursesubdirs ignoreversion
Source: "..\installer\install-nous.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Nous"; Filename: "{app}\launchers\Nous.exe"; IconFilename: "{app}\branding\assets\nous.ico"
Name: "{group}\Parar Nous"; Filename: "{app}\launchers\Parar Nous.exe"
Name: "{group}\Desinstalar o Nous"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Nous"; Filename: "{app}\launchers\Nous.exe"; IconFilename: "{app}\branding\assets\nous.ico"; Tasks: desktopicon

[Run]
; Configura o backend (Ollama, Python, Open WebUI, identidade). Janela visivel
; de proposito para o usuario acompanhar o download (~5-6 GB na primeira vez).
Filename: "powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\installer\install-nous.ps1"""; \
    StatusMsg: "Configurando o Nous: instalando Ollama, Python e o Open WebUI (pode levar varios minutos)..."; \
    Flags: waituntilterminated
; Abre o Nous ao final (opcional)
Filename: "{app}\launchers\Nous.exe"; Description: "Abrir o Nous agora"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
