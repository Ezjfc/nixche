local env = ...
local scope = "nixche/neovim/neovim-with-lsps"
local currentVersion = vim.version()

if env.NEED_VERSION ~= "" and vim.version.cmp(currentVersion, env.NEED_VERSION) < 0 then
  vim.print(
    scope ..
    ": Neovim " .. tostring(currentVersion) .. " does not support Native LSP. " ..
    "Please upgrade to " .. env.NEED_VERSION .. " or above"
  )
else
  -- Prevents message popups from spamming:
  local mopt = vim.o.messagesopt
  vim.o.messagesopt = "wait:0,history:500"

  for name, _ in pairs(env.LSPS) do
    vim.print(scope .. ": enabling " .. name)
    vim.lsp.enable(name)
  end

  vim.o.messagesopt = mopt
end
