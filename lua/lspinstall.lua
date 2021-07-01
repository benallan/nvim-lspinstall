local servers = require "lspinstall/servers"
local configs = require "lspconfig/configs"
local util = require"lspinstall/util"
local install_path = util.install_path

local windows_os = util.detect_windows()

local M = {}

local function install_server_posix(lang, path, onExit)
  vim.cmd("new")
  local shell = vim.o.shell
  vim.o.shell = "/bin/bash"

  local preamble = "set -e\n"
  vim.fn.termopen(preamble .. servers[lang].install_script, { cwd = path, on_exit = onExit })

  vim.o.shell = shell
  vim.cmd("startinsert")
end


local function install_server_win(lang, path, onExit)
  local saved_options = util.get_shell_options()
  vim.cmd("new")

  util.apply_shell_options {
    shell = "powershell.exe",
    shellquote = "",
    shellpipe = "|",
    shellxquote = "",
    shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command",
    shellredir = "| Out-File -Encoding UTF8",
  }

  local preamble = '$ErrorActionPreference="Stop"\n'
  vim.fn.termopen(preamble .. servers[lang].install_script, { cwd = path, on_exit = onExit })

  util.apply_shell_options(saved_options)
  vim.cmd("startinsert")
end


-- INSTALL
function M.install_server(lang)
  if not servers[lang] then error("Could not find language server for " .. lang) end

  local path = install_path(lang)
  vim.fn.mkdir(path, "p") -- fail: throws

  local function onExit(_, code)
    if code ~= 0 then error("[nvim-lspinstall] Could not install language server for " .. lang) end
    vim.notify("[nvim-lspinstall] Successfully installed language server for " .. lang)
    if M.post_install_hook then M.post_install_hook() end
  end

  if windows_os then
    install_server_win(lang, path, onExit)
  else
    install_server_posix(lang, path, onExit)
  end
end


-- UNINSTALL

function M.uninstall_server(lang)
  if not servers[lang] then error("Could not find language server for " .. lang) end

  local path = install_path(lang)

  if vim.fn.isdirectory(path) ~= 1 then -- 0: false, 1: true
    error("Language server is not installed")
  end

  local function onExit(_, code)
    if code ~= 0 then error("[nvim-lspinstall] Could not uninstall language server for " .. lang) end
    if vim.fn.delete(path, "rf") ~= 0 then -- here 0: success, -1: fail
      error("[nvim-lspinstall] Could not delete directory " .. lang)
    end
    vim.notify("[nvim-lspinstall] Successfully uninstalled language server for " .. lang)
    if M.post_uninstall_hook then M.post_uninstall_hook() end
  end

  vim.cmd("new")
  local shell = vim.o.shell
  vim.o.shell = "/usr/bin/env bash"
  vim.fn.termopen("set -e\n" .. (servers[lang].uninstall_script or ""),
                  { cwd = path, on_exit = onExit })
  vim.o.shell = shell
  vim.cmd("startinsert")
end

-- UTILITY

function M.is_server_installed(lang)
  return vim.fn.isdirectory(install_path(lang)) == 1 -- 0: false, 1: true
end

function M.available_servers() return vim.tbl_keys(servers) end

function M.installed_servers()
  return vim.tbl_filter(function(key) return M.is_server_installed(key) end, M.available_servers())
end

function M.not_installed_servers()
  return vim.tbl_filter(function(key) return not M.is_server_installed(key) end,
                        M.available_servers())
end

--- Sets the configs in lspconfig for all installed servers
function M.setup()
  for lang, server_config in pairs(servers) do
    if M.is_server_installed(lang) and not configs[lang] then -- don't overwrite existing config, leads to problems
      local config = vim.tbl_deep_extend("keep", server_config,
                                         { default_config = { cmd_cwd = install_path(lang) } })
      if config.default_config.cmd then
        local executable = config.default_config.cmd[1]
        if vim.regex([[^[.]\{1,2}\/]]):match_str(executable) then -- matches ./ and ../
          -- prepend the install path if the executable is a relative path
          -- we need this because for the executable cmd[1] itself, cwd is not considered!
          config.default_config.cmd[1] = install_path(lang) .. "/" .. executable
        end
      end
      configs[lang] = config
    end
  end
end

return M
