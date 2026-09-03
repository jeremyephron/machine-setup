local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_commit = "306a05526ada86a7b30af95c5cc81ffba93fef97"

if not vim.uv.fs_stat(lazypath) then
  local commands = {
    { "git", "init", lazypath },
    { "git", "-C", lazypath, "remote", "add", "origin", "https://github.com/folke/lazy.nvim.git" },
    { "git", "-C", lazypath, "fetch", "--depth=1", "origin", lazy_commit .. ":refs/remotes/origin/main" },
    { "git", "-C", lazypath, "checkout", "--detach", lazy_commit },
  }
  for _, command in ipairs(commands) do
    local output = vim.fn.system(command)
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({ { "Failed to install pinned lazy.nvim:\n" .. output, "ErrorMsg" } }, true, {})
      return
    end
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup("machine_setup.plugins", {
  change_detection = { notify = false },
  checker = { enabled = false },
  install = { colorscheme = { "monokai", "habamax" } },
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  rocks = { enabled = false },
  ui = { border = "rounded" },
})
