vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end
local root = "C:/My/code/gitea/temporary/Signal-Server"
vim.cmd("tcd " .. vim.fn.fnameescape(root))
vim.t.workspace_path = root
local file = root .. "/service/src/main/java/org/whispersystems/textsecuregcm/util/Util.java"
vim.cmd("edit " .. vim.fn.fnameescape(file))
local buf = vim.api.nvim_get_current_buf()
local client
assert(
  vim.wait(55000, function()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if c.name == "jdtls" and c.initialized then
        client = c
        return true
      end
    end
  end, 100),
  "Signal Java LSP start timeout"
)
local pos
for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
  local col = line:find("Util::getCountryCode", 1, true)
  if col then
    col = col + 6
  end
  if col then
    pos = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = i - 1, character = col - 1 } }
    break
  end
end
assert(pos, "real reference in Util.java")
assert(
  vim.wait(55000, function()
    local r = client:request_sync("textDocument/definition", pos, 3000, buf)
    if r and r.result and not vim.tbl_isempty(r.result) then
      return true
    end
  end, 500),
  "Signal Java definition timeout"
)
local completion = client:request_sync("textDocument/completion", pos, 15000, buf)
assert(completion and completion.result and not completion.err, "Signal completion")
print("SIGNAL_REAL_PROJECT_LSP_DEFINITION_COMPLETION_OK")
for _, c in ipairs(vim.lsp.get_clients()) do
  c:stop(true)
end
vim.cmd("qa!")
