-- Add the project's lua directory to package.path
local project_root = vim.fn.getcwd()
package.path = project_root .. '/lua/?.lua;' .. project_root .. '/lua/?/init.lua;' .. package.path

-- Run the test suite
local exit_code = require('tests.run_all')
vim.cmd('qa!')
