local config = require"lspinstall/util".extract_config("efm")

local install_script

if require"lspinstall/util".detect_windows() then

  config.default_config.cmd[1] = "./efm-langserver.exe"

  install_script = [[
  $Env:GOPATH = $pwd; $Env:GOBIN = $pwd; $Env:GO111MODULE = "on";
  go get -v github.com/mattn/efm-langserver
  go clean -modcache
  ]]

else

  config.default_config.cmd[1] = "./efm-langserver"

  install_script = [[
  GOPATH=$(pwd) GOBIN=$(pwd) GO111MODULE=on go get -v github.com/mattn/efm-langserver
  GOPATH=$(pwd) GO111MODULE=on go clean -modcache
  ]]
end

return vim.tbl_extend('error', config, { install_script = install_script })
