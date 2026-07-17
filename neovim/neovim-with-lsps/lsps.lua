local env = ...
local currentVersion = vim.version.version(.)
local compareVersion = vim.version.cmp

if env.NEED_VERSION ~= "" and compareVersion(currentVersion, env.NEED_VERSION) > 0 then
  vim.print(
    "nixche/neovim/neovim-with-lsps" ..
    ": Neovim " .. tostring(currentVersion) .. "does not support Native LSP. " ..
    "Please upgrade to " .. env.NEED_VERSION .. " or above"
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
