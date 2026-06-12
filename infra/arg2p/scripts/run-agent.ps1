param(
    [string]$Program = "examples/01-conflicting-duties.arg2p",
    [string[]]$ExtraArgs = @()
)

$lessonRoot = Split-Path $PSScriptRoot -Parent

Push-Location $lessonRoot
try {
    docker compose run --rm kotlin $Program @ExtraArgs
}
finally {
    Pop-Location
}
