local helpers = require('helpers')

return function()
  helpers.describe("Deprecated Options", function()
    helpers.test("deprecated confirm option shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, confirm = false })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("confirm") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation warning for confirm")

      helpers.cleanup_test_env()
    end)

    helpers.test("deprecated disable_vim_loader option shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, disable_vim_loader = true })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("disable_vim_loader") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation warning for disable_vim_loader")

      helpers.cleanup_test_env()
    end)

    helpers.test("deprecated options still register plugins", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = { { 'test/plugin' } },
        confirm = false,
      })

      helpers.flush_pending()

      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin should be registered")

      helpers.cleanup_test_env()
    end)
  end)
end
