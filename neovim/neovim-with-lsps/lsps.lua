local env = ...

if env.VERSION ~= "" and vim.version.cmp(vim.version(), env.VERSION) > 0 then
  vim.print(
    "nixche/neovim/neovim-with-lsps" ..
    ": Neovim " .. vim.version() .. "does not support Native LSP. " +
    "Please upgrade to " .. env.VERSION .. " or above"
  )
else
  local mopt = vim.o.messagesopt
  -- Prevents message popups from spamming:
  mopt = "wait:0,history:500"

  for name, _ in pairs(env.LSPS) do
    vim.print(env.MESSAGE_SCOPE .. ': enabling ' .. name)
    vim.lsp.enable(name)
  end

  vim.o.messagesopt = mopt
end
