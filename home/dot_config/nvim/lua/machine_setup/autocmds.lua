local group = vim.api.nvim_create_augroup("machine_setup", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local lines = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = "*",
  callback = function(event)
    if vim.bo[event.buf].binary or vim.bo[event.buf].filetype == "diff" then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "bash", "css", "html", "javascript", "json", "lua", "markdown", "sh", "typescript", "yaml" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop = 2
  end,
})
