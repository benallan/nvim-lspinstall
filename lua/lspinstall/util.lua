local M = {}

--- Gets a copy of the config that would be used by lspconfig. Without side effects.
--@returns a fresh config
function M.extract_config(name)
  -- needed so we can restore the initial state at the end
  local was_config_set = require'lspconfig/configs'[name]
  local was_package_loaded = package.loaded['lspconfig/' .. name]

  -- gets or requires config
  local config = require'lspconfig'[name].document_config

  -- restore the initial state
  if not was_config_set then
    require'lspconfig/configs'[name] = nil
  end
  if not was_package_loaded then
    package.loaded['lspconfig/' .. name] = nil
  end

  return vim.deepcopy(config)
end

--- Gets lsp server install directory
--@returns string
function M.install_path(lang)
  return vim.fn.stdpath("data") .. "/lspinstall/" .. lang
end

--- Check if current platform is windows
--@returns bool
function M.detect_windows()

  local sysname = vim.loop.os_uname().sysname

  -- The value of sysname seems to vary on windows
  return sysname == "Windows" or sysname == "Windows_NT"
end


--- Get current vim options related to shell
--@returns table
function M.get_shell_options()

  return {
    shell = vim.o.shell,
    shellquote = vim.o.shellquote,
    shellpipe = vim.o.shellpipe,
    shellxquote = vim.o.shellxquote,
    shellcmdflag = vim.o.shellcmdflag,
    shellredir = vim.o.shellredir,
  }

end


--- Get current vim options related to shell
--@param options Table of options (same format as return value of get_shell_shell_options)
--@returns table
function M.apply_shell_options(options)

    vim.o.shell = options.shell
    vim.o.shellquote = options.shellquote
    vim.o.shellpipe = options.shellpipe
    vim.o.shellxquote = options.shellxquote
    vim.o.shellcmdflag = options.shellcmdflag
    vim.o.shellredir = options.shellredir

end

return M
