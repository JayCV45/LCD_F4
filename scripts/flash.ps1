param(
  [Parameter(Mandatory=$true)][string]$BinaryPath,
  [string]$Address = "0x08000000"
)

$ErrorActionPreference = "Stop"

$cli = $env:STM32_PROG_CLI
if (-not $cli -or -not (Test-Path $cli)) {
  $default = "C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe"
  if (Test-Path $default) { $cli = $default }
}

if (-not $cli -or -not (Test-Path $cli)) {
  throw "STM32_Programmer_CLI.exe not found. Install STM32CubeProgrammer or set STM32_PROG_CLI env var."
}

if (-not (Test-Path $BinaryPath)) {
  throw "Binary not found: $BinaryPath"
}

Write-Host "Flashing: $BinaryPath @ $Address"
& $cli -c port=SWD freq=4000 mode=UR -d "$BinaryPath" $Address -rst
if ($LASTEXITCODE -ne 0) { throw "Flashing failed (exit $LASTEXITCODE)" }
