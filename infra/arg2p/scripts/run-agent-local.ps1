param(
    [string]$Program = "examples/01-conflicting-duties.arg2p",
    [string[]]$ExtraArgs = @()
)

$ErrorActionPreference = "Stop"

$lessonRoot = Split-Path $PSScriptRoot -Parent

Push-Location $lessonRoot
try {
    if (-not (Get-Command gradle -ErrorAction SilentlyContinue)) {
        throw "gradle command not found. Install Gradle or use Docker runner .\scripts\run-agent.ps1"
    }

    if (-not (Test-Path $Program)) {
        throw "Program not found: $Program"
    }

    $runnerProgram = $Program
    if ($runnerProgram.StartsWith("examples/")) {
        $runnerProgram = "../" + $runnerProgram.Substring(9)
    }

    $argsList = @($runnerProgram) + $ExtraArgs
    $argsLiteral = ($argsList | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }) -join ' '

    gradle --no-daemon -p examples/runner run --args=$argsLiteral
}
finally {
    Pop-Location
}
