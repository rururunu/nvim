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
        & python tests/editor_layout.py
        if ($LASTEXITCODE -ne 0) { throw 'Editor layout validation failed' }
        & python tests/terminal_layout.py
        if ($LASTEXITCODE -ne 0) { throw 'Terminal layout validation failed' }
        & python tests/minimap.py
        if ($LASTEXITCODE -ne 0) { throw 'Minimap validation failed' }
        & python tests/buffer_close.py
        if ($LASTEXITCODE -ne 0) { throw 'Buffer close with explorer validation failed' }
        & python tests/workspace_ui.py
        if ($LASTEXITCODE -ne 0) { throw 'Workspace layout and buffers validation failed' }
    }
} finally {
    Pop-Location
}
