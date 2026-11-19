# Abre o aplicativo Oficina de Bicicletas como uma janela propria no Windows,
# sem barra de navegador. Sobe o servidor local do Flutter se ainda nao estiver
# rodando e abre o Edge em modo aplicativo.

$ErrorActionPreference = 'Stop'

$porta = 53127
$url = "http://127.0.0.1:$porta"
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = 'C:\flutter\bin\flutter.bat'
$log = Join-Path $env:TEMP 'oficina_bicicletas_web.log'
$logErro = Join-Path $env:TEMP 'oficina_bicicletas_web_erro.log'

function Testar-Porta {
  return [bool](Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue)
}

if (-not (Testar-Porta)) {
  if (-not (Test-Path $flutter)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
      "Flutter nao encontrado em $flutter.",
      'Oficina de Bicicletas'
    )
    exit 1
  }

  Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/c', $flutter, 'run', '-d', 'web-server', '--release',
      '--web-port', "$porta", '--web-hostname', '127.0.0.1' `
    -WorkingDirectory $raiz -WindowStyle Hidden `
    -RedirectStandardOutput $log -RedirectStandardError $logErro

  $limite = (Get-Date).AddMinutes(6)
  while (-not (Testar-Porta) -and (Get-Date) -lt $limite) {
    Start-Sleep -Seconds 2
  }
}

if (-not (Testar-Porta)) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show(
    "Nao foi possivel iniciar o servidor do app.`n`nVeja o log: $log",
    'Oficina de Bicicletas'
  )
  exit 1
}

$edge = @(
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($edge) {
  Start-Process -FilePath $edge `
    -ArgumentList "--app=$url", '--window-size=1100,800'
} else {
  Start-Process $url
}
