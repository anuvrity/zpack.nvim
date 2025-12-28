local helpers = require('helpers')

return function()
  helpers.describe("Lazy Loading - Commands", function()
    helpers.test("plugin with cmd creates command placeholder", function()
      helpers.setup_test_env()

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        cmd = 'TestCommand',
      })

      helpers.flush_pending()
      local commands = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(commands.TestCommand, "Command should be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin with multiple cmds creates all commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        cmd = { 'TestCmd1', 'TestCmd2', 'TestCmd3' },
      })

      helpers.flush_pending()
      local commands = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(commands.TestCmd1, "Command 1 should be created")
      helpers.assert_not_nil(commands.TestCmd2, "Command 2 should be created")
      helpers.assert_not_nil(commands.TestCmd3, "Command 3 should be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy cmd plugin does not load at startup", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        cmd = 'TestCommand',
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_false(
        state.spec_registry[src].loaded,
        "Lazy cmd plugin should not be loaded at startup"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin loads when command is invoked", function()
      helpers.setup_test_env()
      local loaded = false

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        cmd = 'TestCommand',
        config = function()
          loaded = true
        end,
      })

      helpers.flush_pending()
      pcall(vim.cmd, 'TestCommand')
      helpers.flush_pending()
      helpers.assert_true(loaded, "Plugin should load when command is invoked")

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin loads when command is invoked with args", function()
      helpers.setup_test_env()
      local loaded = false

      require('zpack').setup({ auto_import = false })
      require('zpack').add({
        'test/plugin',
        cmd = 'TestCommand',
        config = function()
          loaded = true
        end,
      })

      helpers.flush_pending()
      pcall(vim.cmd, 'TestCommand somearg')
      helpers.flush_pending()
      helpers.assert_true(loaded, "Plugin should load when command is invoked with args")

      helpers.cleanup_test_env()
    end)
  end)
end
