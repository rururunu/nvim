param([switch]$UI, [switch]$Signal)
$ErrorActionPreference = 'Stop'
$configRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $configRoot
try {
    $testNames = @('workbench', 'backup', 'languages', 'lsp', 'dap')
    if ($Signal) { $testNames += @('signal_build', 'signal_profile', 'signal_lsp') }
    foreach ($testName in $testNames) {
        Write-Host "Checking $testName..."
        $lua = "lua local ok,err=xpcall(function() dofile('tests/$testName.lua') end,debug.traceback); if not ok then io.stderr:write(err); vim.cmd('cquit 1') end"
        & nvim --headless -n -i NONE -c $lua
        if ($LASTEXITCODE -ne 0) { throw "Validation failed: $testName" }
    }
    if ($UI) {
        & python tests/ui.py
        if ($LASTEXITCODE -ne 0) { throw 'Embedded UI validation failed' }
    }
} finally {
    Pop-Location
}
