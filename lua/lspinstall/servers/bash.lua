local config = require"lspinstall/util".extract_config("bashls")

local install_script

if require"lspinstall/util".detect_windows() then

  config.default_config.cmd[1] = "./node_modules/.bin/bash-language-server.cmd"

  install_script = [[
    if (-Not (Test-Path -Path .\package.json -PathType Leaf)){ npm init -y --scope=lspinstall }
    npm install bash-language-server@latest
  ]]

else

  config.default_config.cmd[1] = "./node_modules/.bin/bash-language-server"

  install_script = [[
  ! test -f package.json && npm init -y --scope=lspinstall || true
  npm install bash-language-server@latest
  ]]

end

return vim.tbl_extend('error', config, { install_script = install_script })
