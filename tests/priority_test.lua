local helpers = require('helpers')

return function()
  helpers.describe("Priority-based Loading", function()
    helpers.test("default priority is 50", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      require('zpack').setup({
        spec = {
          { 'test/plugin' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      local priority = utils.get_priority(src)
      helpers.assert_equal(priority, 50, "Default priority should be 50")

      helpers.cleanup_test_env()
    end)

    helpers.test("custom priority is stored", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            priority = 100,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      local priority = utils.get_priority(src)
      helpers.assert_equal(priority, 100, "Custom priority should be stored")

      helpers.cleanup_test_env()
    end)

    helpers.test("higher priority plugins load first", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/plugin1',
            priority = 100,
            config = function()
              table.insert(load_order, 'plugin1')
            end,
          },
          {
            'test/plugin2',
            priority = 200,
            config = function()
              table.insert(load_order, 'plugin2')
            end,
          },
          {
            'test/plugin3',
            priority = 150,
            config = function()
              table.insert(load_order, 'plugin3')
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(#load_order, 3, "All plugins should load")
      helpers.assert_equal(load_order[1], 'plugin2', "Plugin2 (priority 200) should load first")
      helpers.assert_equal(load_order[2], 'plugin3', "Plugin3 (priority 150) should load second")
      helpers.assert_equal(load_order[3], 'plugin1', "Plugin1 (priority 100) should load third")

      helpers.cleanup_test_env()
    end)

    helpers.test("priority works with lazy loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            cmd = 'TestCommand',
            priority = 999,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      local priority = utils.get_priority(src)
      helpers.assert_equal(priority, 999, "Priority should work with lazy loading")

      helpers.cleanup_test_env()
    end)

    helpers.test("compare_priority function sorts correctly", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      require('zpack').setup({
        spec = {
          { 'test/plugin1', priority = 100 },
          { 'test/plugin2', priority = 50 },
          { 'test/plugin3', priority = 200 },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src1 = 'https://github.com/test/plugin1'
      local src2 = 'https://github.com/test/plugin2'
      local src3 = 'https://github.com/test/plugin3'

      helpers.assert_true(
        utils.compare_priority(src3, src1),
        "Plugin3 (200) should be higher priority than Plugin1 (100)"
      )
      helpers.assert_true(
        utils.compare_priority(src1, src2),
        "Plugin1 (100) should be higher priority than Plugin2 (50)"
      )
      helpers.assert_false(
        utils.compare_priority(src2, src3),
        "Plugin2 (50) should not be higher priority than Plugin3 (200)"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("compare_priority uses import order as tiebreaker", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      require('zpack').setup({
        spec = {
          { 'test/first' },  -- import_order = 0
          { 'test/second' }, -- import_order = 1
          { 'test/third' },  -- import_order = 2
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src1 = 'https://github.com/test/first'
      local src2 = 'https://github.com/test/second'
      local src3 = 'https://github.com/test/third'

      helpers.assert_true(
        utils.compare_priority(src1, src2),
        "first (import 0) should come before second (import 1) when priority equal"
      )
      helpers.assert_true(
        utils.compare_priority(src2, src3),
        "second (import 1) should come before third (import 2) when priority equal"
      )
      helpers.assert_false(
        utils.compare_priority(src3, src1),
        "third (import 2) should not come before first (import 0)"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("priority affects lazy plugin load order on same trigger", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/plugin1',
            event = 'VeryLazy',
            priority = 50,
            config = function()
              table.insert(load_order, 'plugin1')
            end,
          },
          {
            'test/plugin2',
            event = 'VeryLazy',
            priority = 100,
            config = function()
              table.insert(load_order, 'plugin2')
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      vim.api.nvim_exec_autocmds('UIEnter', {})
      helpers.flush_pending()

      if #load_order > 0 then
        helpers.assert_equal(
          load_order[1],
          'plugin2',
          "Higher priority plugin should load first on same trigger"
        )
      end

      helpers.cleanup_test_env()
    end)
  end)
end
