local helpers = require('helpers')

return function()
  helpers.describe("Setup and Initialization", function()
    helpers.test("setup() initializes zpack state", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      helpers.assert_false(state.is_setup, "State should not be setup initially")

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      helpers.assert_true(state.is_setup, "State should be setup after setup()")
      helpers.assert_not_nil(state.spec_registry, "Spec registry should exist")
      helpers.assert_not_nil(state.lazy_group, "Lazy group should exist")
      helpers.assert_not_nil(state.startup_group, "Startup group should exist")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() cannot be called twice", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })
      helpers.assert_true(state.is_setup, "State should be setup after first call")

      -- Second call should warn but state should remain setup
      require('zpack').setup({ spec = {}, defaults = { confirm = false } })
      helpers.assert_true(state.is_setup, "State should still be setup after second call")

      helpers.cleanup_test_env()
    end)

    helpers.test("add() shows deprecation error", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })
      require('zpack').add({ 'test/plugin' })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("REMOVED") and notif.msg:find("add") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation error for add()")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() with specs as first argument registers plugins", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        { 'test/plugin1' },
        { 'test/plugin2' },
      })

      local src1 = 'https://github.com/test/plugin1'
      local src2 = 'https://github.com/test/plugin2'
      helpers.assert_not_nil(state.spec_registry[src1], "Plugin 1 should be registered")
      helpers.assert_not_nil(state.spec_registry[src2], "Plugin 2 should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() with single spec as first argument", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({ 'test/plugin' })

      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Single inline spec should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() with spec field registers single plugin", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = { { 'test/plugin' } },
        defaults = { confirm = false },
      })

      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin should be registered")
      helpers.assert_equal(state.spec_registry[src].spec[1], 'test/plugin', "Spec should match")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() with spec as single spec (not wrapped in list)", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = { 'test/plugin', config = function() end },
        defaults = { confirm = false },
      })

      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Single spec should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("setup() with spec field registers multiple plugins", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { 'test/plugin1' },
          { 'test/plugin2' },
        },
        defaults = { confirm = false },
      })

      local src1 = 'https://github.com/test/plugin1'
      local src2 = 'https://github.com/test/plugin2'
      helpers.assert_not_nil(state.spec_registry[src1], "Plugin 1 should be registered")
      helpers.assert_not_nil(state.spec_registry[src2], "Plugin 2 should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin spec supports src field", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { src = 'https://custom.url/plugin.git' },
        },
        defaults = { confirm = false },
      })

      local src = 'https://custom.url/plugin.git'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin with src should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin spec supports url field (lazy.nvim compat)", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { url = 'https://custom.url/plugin.git' },
        },
        defaults = { confirm = false },
      })

      local src = 'https://custom.url/plugin.git'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin with url should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin spec supports dir field (lazy.nvim compat)", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { dir = '/path/to/local/plugin' },
        },
        defaults = { confirm = false },
      })

      local src = '/path/to/local/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin with dir should be registered")

      helpers.cleanup_test_env()
    end)
  end)
end
