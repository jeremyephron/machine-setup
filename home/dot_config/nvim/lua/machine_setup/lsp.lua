local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup({
  automatic_enable = false,
})

require("mason-tool-installer").setup({
  ensure_installed = {
    { "bash-language-server", version = "5.6.0" },
    { "basedpyright", version = "1.39.10" },
    { "clangd", version = "22.1.6" },
    { "debugpy", version = "1.8.21" },
    { "dockerfile-language-server", version = "0.15.0" },
    { "jdtls", version = "v1.60.0" },
    { "prettier", version = "3.9.6" },
    { "ruff", version = "0.16.5" },
    { "rust-analyzer", version = "2026-08-31" },
    { "shellcheck", version = "v0.11.0" },
    { "shfmt", version = "v3.14.0" },
    { "stylua", version = "v2.5.2" },
    { "terraform-ls", version = "v0.39.0" },
    { "typescript-language-server", version = "6.0.0" },
    { "yaml-language-server", version = "1.24.0" },
  },
  run_on_start = false,
})

local on_attach = function(_, buffer)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = buffer, desc = "LSP: " .. desc })
  end
  map("gd", vim.lsp.buf.definition, "Definition")
  map("gD", vim.lsp.buf.declaration, "Declaration")
  map("gr", vim.lsp.buf.references, "References")
  map("gI", vim.lsp.buf.implementation, "Implementation")
  map("K", vim.lsp.buf.hover, "Hover documentation")
  map("<leader>rn", vim.lsp.buf.rename, "Rename")
  map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document symbols")
  map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")
end

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = true,
  virtual_text = { spacing = 2, source = "if_many" },
})

local servers = {
  bashls = {},
  basedpyright = {
    settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
  },
  clangd = {},
  dockerls = {},
  jdtls = {},
  ruff = {},
  rust_analyzer = {},
  terraformls = {},
  ts_ls = {},
  yamlls = {},
}

for server, config in pairs(servers) do
  config.capabilities = capabilities
  config.on_attach = on_attach
  vim.lsp.config(server, config)
  vim.lsp.enable(server)
end
