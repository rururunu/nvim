local api = vim.api
api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end -- 验证样例不进入最近项目历史。
local root = vim.fn.stdpath("cache") .. "/workbench-validation"
local cases = {
  {
    name = "JAVA",
    dir = "java",
    file = "src/main/java/sample/Main.java",
    server = "jdtls",
    line = 3,
    needle = "sum(2",
  },
  { name = "RUST", dir = "rust", file = "src/main.rs", server = "rust-analyzer", line = 1, needle = "sum(2" },
  { name = "KOTLIN", dir = "kotlin", file = "Main.kt", server = "kotlin_language_server", line = 1, needle = "sum(2" },
}
local report = {}
for _, case in ipairs(cases) do
  local cwd = root .. "/" .. case.dir
  vim.cmd("tcd " .. vim.fn.fnameescape(cwd))
  vim.t.workspace_path = cwd
  vim.cmd("edit " .. vim.fn.fnameescape(cwd .. "/" .. case.file))
  local buf = api.nvim_get_current_buf()
  local client
  assert(
    vim.wait(55000, function()
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        if c.name == case.server and c.initialized then
          client = c
          return true
        end
      end
    end, 100),
    case.name .. " LSP startup timeout"
  )
  local line = api.nvim_buf_get_lines(buf, case.line, case.line + 1, false)[1]
  local col = assert(line:find(case.needle, 1, true)) - 1
  local pos = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = case.line, character = col } }
  local function request(method, params)
    local response = client:request_sync(method, params, 30000, buf)
    assert(response and not response.err, case.name .. " " .. method .. " " .. vim.inspect(response))
    return response.result
  end
  -- Java may finish loading its project after initialize.
  local definition
  assert(
    vim.wait(45000, function()
      local r = client:request_sync("textDocument/definition", pos, 3000, buf)
      if r and r.result and not vim.tbl_isempty(r.result) then
        definition = r.result
        return true
      end
    end, 500),
    case.name .. " definition"
  )
  local rename = request("textDocument/rename", vim.tbl_extend("force", pos, { newName = "addNumbers" }))
  assert(rename and (rename.changes or rename.documentChanges), case.name .. " rename edits")
  local completion = request("textDocument/completion", pos)
  assert(completion and (completion.items or completion[1]), case.name .. " completion")
  local formatted = request(
    "textDocument/formatting",
    { textDocument = pos.textDocument, options = { tabSize = 4, insertSpaces = true } }
  )
  assert(formatted ~= nil, case.name .. " formatting")
  report[#report + 1] = case.name .. " LSP_DEFINITION_RENAME_COMPLETION_FORMAT_OK"
  print(report[#report])
end
vim.fn.writefile(report, root .. "/lsp-report.txt")
for _, c in ipairs(vim.lsp.get_clients()) do
  c:stop(true)
end
vim.cmd("qa!")

