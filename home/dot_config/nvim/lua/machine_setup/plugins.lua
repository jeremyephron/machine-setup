local profile = require("machine_setup.profile")

return {
  { "folke/lazy.nvim", branch = "main" },
  {
    "tanvirtin/monokai.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("monokai").setup({ palette = require("monokai").pro })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto", globalstatus = true } },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { preset = "helix" },
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Search text" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Search help" },
      { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
      { "<leader>fc", function() require("telescope.builtin").commands() end, desc = "Search commands" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          mappings = { i = { ["<C-u>"] = false, ["<C-d>"] = false } },
          path_display = { "smart" },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        vim.keymap.set("n", "]c", gs.next_hunk, { buffer = buffer, desc = "Next Git hunk" })
        vim.keymap.set("n", "[c", gs.prev_hunk, { buffer = buffer, desc = "Previous Git hunk" })
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = buffer, desc = "Preview Git hunk" })
        vim.keymap.set("n", "<leader>gb", gs.blame_line, { buffer = buffer, desc = "Blame line" })
      end,
    },
  },
  { "tpope/vim-fugitive", cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite" } },
  {
    "nvim-treesitter/nvim-treesitter",
    cond = not profile.minimal,
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local parsers = profile.minimal and {
        "bash", "json", "lua", "markdown", "markdown_inline", "python", "vim", "vimdoc",
      } or {
        "bash", "c", "cpp", "css", "dockerfile", "git_config", "git_rebase", "gitattributes",
        "gitignore", "go", "html", "java", "javascript", "json", "latex", "lua",
        "markdown", "markdown_inline", "python", "query", "regex", "rust", "toml", "tsx",
        "typescript", "vim", "vimdoc", "yaml",
      }
      local installation = require("nvim-treesitter").install(parsers)
      if #vim.api.nvim_list_uis() == 0 then
        installation:wait(300000)
      end
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    cond = not profile.minimal,
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("machine_setup.lsp")
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } }, { { name = "buffer" } }),
      })
    end,
  },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        bash = { "shfmt" },
        sh = { "shfmt" },
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        rust = { "rustfmt" },
        terraform = { "terraform_fmt" },
      },
      format_after_save = { lsp_format = "fallback", timeout_ms = 3000 },
    },
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format buffer" },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { bash = { "shellcheck" }, sh = { "shellcheck" } }
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, { callback = function() lint.try_lint() end })
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = { direction = "float", open_mapping = [[<C-\>]], float_opts = { border = "rounded" } },
  },
  {
    "lervag/vimtex",
    cond = not profile.minimal,
    ft = "tex",
    init = function()
      vim.g.vimtex_compiler_method = "latexmk"
      if vim.fn.has("mac") == 1 then
        vim.g.vimtex_view_method = "skim"
        vim.g.vimtex_view_skim_sync = 1
        vim.g.vimtex_view_skim_activate = 1
      else
        vim.g.vimtex_view_method = "general"
      end
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = { { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics list" } },
  },
}
