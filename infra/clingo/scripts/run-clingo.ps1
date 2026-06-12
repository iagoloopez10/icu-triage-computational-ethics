param(
    [string[]]$Program = @("examples/01-utility-choice.lp"),
    [string[]]$ExtraArgs = @()
)

$lessonRoot = Split-Path $PSScriptRoot -Parent

Push-Location $lessonRoot
try {
    docker compose run --rm clingo @Program --opt-mode=optN -n 0 @ExtraArgs
}
finally {
    Pop-Location
}
