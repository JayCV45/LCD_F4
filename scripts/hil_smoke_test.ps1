param(
  [string]$Port,
  [int]$Baud = 115200,
  [int]$TimeoutS = 25,
  [string]$LogPath = "hil.log"
)

# Allow env vars if params not provided
if (-not $Port)     { $Port = $env:HIL_COM_PORT }
if ($env:HIL_BAUD)  { $Baud = [int]$env:HIL_BAUD }
if ($env:HIL_TIMEOUT_S) { $TimeoutS = [int]$env:HIL_TIMEOUT_S }
if ($env:HIL_LOG_PATH)  { $LogPath = $env:HIL_LOG_PATH }

if (-not $Port) { throw "HIL_COM_PORT is not set (example: COM4)." }

# Ensure port exists
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
if ($ports -notcontains $Port) {
  throw "Port $Port not found. Available: $($ports -join ', ')"
}

# Clear old log
if (Test-Path $LogPath) { Remove-Item $LogPath -Force }

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud, 'None', 8, 'One'
$sp.ReadTimeout = 200
$sp.DtrEnable = $true
$sp.RtsEnable = $true

$deadline = (Get-Date).AddSeconds($TimeoutS)
$buffer = ""

try {
  $sp.Open()

  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 50

    $chunk = $sp.ReadExisting()
    if ([string]::IsNullOrEmpty($chunk)) { continue }

    Add-Content -Path $LogPath -Value $chunk
    $buffer += $chunk

    if ($buffer -match "HIL:PASS") {
      Write-Host "HIL RESULT: PASS"
      exit 0
    }
    if ($buffer -match "HIL:FAIL") {
      Write-Host "HIL RESULT: FAIL"
      exit 1
    }

    # Prevent unbounded growth
    if ($buffer.Length -gt 8192) { $buffer = $buffer.Substring($buffer.Length - 4096) }
  }

  Write-Host "HIL RESULT: TIMEOUT (no PASS/FAIL)"
  exit 1
}
finally {
  if ($sp -and $sp.IsOpen) { $sp.Close() }
}
