local helpers = require('helpers')

return function()
  helpers.describe("Lazy Loading - FileType", function()
    helpers.test("single filetype creates FileType autocmd", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            ft = 'rust',
          },
        },
        confirm = false,
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'FileType', 'rust'),
        "Single filetype should create FileType autocmd"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("multiple filetypes create FileType autocmd with all patterns", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            ft = { 'lua', 'vim', 'python' },
          },
        },
        confirm = false,
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      local found = helpers.find_autocmd(autocmds, 'FileType', 'lua')
        or helpers.find_autocmd(autocmds, 'FileType', 'vim')
        or helpers.find_autocmd(autocmds, 'FileType', 'python')
      helpers.assert_not_nil(found, "Multiple filetypes should create FileType autocmd")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy ft plugin does not load at startup", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            ft = 'lua',
          },
        },
        confirm = false,
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_false(
        state.spec_registry[src].loaded,
        "Lazy ft plugin should not be loaded at startup"
      )

      helpers.cleanup_test_env()
    end)
  end)
end
