local helpers = require('helpers')

return function()
  helpers.describe("Lazy Loading - Events", function()
    helpers.test("inline event pattern is parsed correctly", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = 'BufReadPre *.lua',
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'BufReadPre', '*.lua'),
        "Inline event pattern should create autocmd"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("EventSpec with pattern creates autocmd with pattern", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = {
          event = 'BufRead',
          pattern = '*.rs',
        },
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'BufReadPost', '*.rs'),
        "EventSpec pattern should create autocmd with pattern"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("EventSpec with multiple patterns creates autocmd", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = {
          event = 'BufRead',
          pattern = { '*.lua', '*.vim' },
        },
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      local found = helpers.find_autocmd(autocmds, 'BufReadPost', '*.lua')
        or helpers.find_autocmd(autocmds, 'BufReadPost', '*.vim')
      helpers.assert_not_nil(found, "EventSpec with multiple patterns should create autocmd")

      helpers.cleanup_test_env()
    end)

    helpers.test("global pattern fallback is applied to events", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = 'BufRead',
        pattern = '*.md',
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'BufReadPost', '*.md'),
        "Global pattern should be applied to events"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("VeryLazy event creates UIEnter autocmd", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = 'VeryLazy',
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'UIEnter'),
        "VeryLazy should create UIEnter autocmd"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("multiple EventSpecs with different patterns", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = {
          { event = 'BufReadPre', pattern = '*.lua' },
          { event = 'BufNewFile', pattern = '*.rs' },
        },
      })

      helpers.flush_pending()
      local autocmds = vim.api.nvim_get_autocmds({ group = state.lazy_group })
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'BufReadPre', '*.lua'),
        "Should create BufReadPre autocmd with *.lua pattern"
      )
      helpers.assert_not_nil(
        helpers.find_autocmd(autocmds, 'BufNewFile', '*.rs'),
        "Should create BufNewFile autocmd with *.rs pattern"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy event plugin does not load at startup", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        event = 'BufRead',
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_false(
        state.spec_registry[src].loaded,
        "Lazy event plugin should not be loaded at startup"
      )

      helpers.cleanup_test_env()
    end)
  end)
end
