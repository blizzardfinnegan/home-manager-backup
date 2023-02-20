local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = '/home/pinestar/.local/jdtls/workspaces' .. project_name
local config = {
  cmd = {
    'java',
    '-jar', '/home/pinestar/.local/jdtls/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar',
    '-configuration', '/home/pinestar/.local/jdtls/config_linux',
    '-data', workspace_dir,
    '/home/pinestar/.local/jdtls/bin/jdtls'},
  root_dir = vim.fs.dirname(vim.fs.find({'.gradlew', '.git', 'mvnw'}, { upward = true })[1]),
}
require('jdtls').start_or_attach(config)
