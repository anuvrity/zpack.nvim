local helpers = require('helpers')

return function()
  helpers.describe("Spec Import", function()
    helpers.test("import loads *.lua files from directory", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return { '/mock/config/lua/test_plugins/foo.lua', '/mock/config/lua/test_plugins/bar.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.foo'] = { 'test/foo-plugin' }
      package.loaded['test_plugins.bar'] = { 'test/bar-plugin' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins' } })
      helpers.flush_pending()

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/foo-plugin'], "foo-plugin should be registered")
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/bar-plugin'], "bar-plugin should be registered")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.foo'] = nil
      package.loaded['test_plugins.bar'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("import loads */init.lua files from subdirectories", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return {}
        elseif pattern == '/mock/config/lua/test_plugins/*/init.lua' then
          return { '/mock/config/lua/test_plugins/mini/init.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.mini'] = { 'test/mini-plugin' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins' } })
      helpers.flush_pending()

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/mini-plugin'],
        "mini-plugin should be registered")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.mini'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("import loads both *.lua and */init.lua", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return { '/mock/config/lua/test_plugins/telescope.lua' }
        elseif pattern == '/mock/config/lua/test_plugins/*/init.lua' then
          return { '/mock/config/lua/test_plugins/mini/init.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.telescope'] = { 'test/telescope' }
      package.loaded['test_plugins.mini'] = { 'test/mini' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins' } })
      helpers.flush_pending()

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/telescope'], "telescope should be registered")
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/mini'], "mini should be registered")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.telescope'] = nil
      package.loaded['test_plugins.mini'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("import only goes 1 level deep for init.lua", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return {}
        elseif pattern == '/mock/config/lua/test_plugins/*/init.lua' then
          return { '/mock/config/lua/test_plugins/level1/init.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.level1'] = { 'test/level1-plugin' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins' } })
      helpers.flush_pending()

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/level1-plugin'],
        "level1-plugin should be registered")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.level1'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("import with enabled=false skips import", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return { '/mock/config/lua/test_plugins/foo.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.foo'] = { 'test/foo-plugin' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins', enabled = false } })
      helpers.flush_pending()

      helpers.assert_nil(state.spec_registry['https://github.com/test/foo-plugin'],
        "foo-plugin should NOT be registered when enabled=false")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.foo'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("nested import works (init.lua with import)", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern == '/mock/config/lua/test_plugins/*.lua' then
          return {}
        elseif pattern == '/mock/config/lua/test_plugins/*/init.lua' then
          return { '/mock/config/lua/test_plugins/mini/init.lua' }
        elseif pattern == '/mock/config/lua/test_plugins/mini/*.lua' then
          return { '/mock/config/lua/test_plugins/mini/ai.lua', '/mock/config/lua/test_plugins/mini/surround.lua' }
        elseif pattern == '/mock/config/lua/test_plugins/mini/*/init.lua' then
          return {}
        end
        return {}
      end

      package.loaded['test_plugins.mini'] = { import = 'test_plugins.mini' }
      package.loaded['test_plugins.mini.ai'] = { 'echasnovski/mini.ai' }
      package.loaded['test_plugins.mini.surround'] = { 'echasnovski/mini.surround' }

      local state = require('zpack.state')
      require('zpack').setup({ { import = 'test_plugins' } })
      helpers.flush_pending()

      helpers.assert_not_nil(state.spec_registry['https://github.com/echasnovski/mini.ai'],
        "mini.ai should be registered")
      helpers.assert_not_nil(state.spec_registry['https://github.com/echasnovski/mini.surround'],
        "mini.surround should be registered")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.mini'] = nil
      package.loaded['test_plugins.mini.ai'] = nil
      package.loaded['test_plugins.mini.surround'] = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("duplicate import is skipped", function()
      helpers.setup_test_env()

      local original_glob = vim.fn.glob
      local original_stdpath = vim.fn.stdpath
      local glob_call_count = 0
      vim.fn.stdpath = function() return '/mock/config' end
      vim.fn.glob = function(pattern)
        if pattern:find('test_plugins/%*.lua') then
          glob_call_count = glob_call_count + 1
          return { '/mock/config/lua/test_plugins/foo.lua' }
        end
        return {}
      end

      package.loaded['test_plugins.foo'] = { 'test/foo-plugin' }

      require('zpack').setup({
        { import = 'test_plugins' },
        { import = 'test_plugins' },
      })
      helpers.flush_pending()

      helpers.assert_equal(glob_call_count, 1, "import should only be processed once")

      vim.fn.glob = original_glob
      vim.fn.stdpath = original_stdpath
      package.loaded['test_plugins.foo'] = nil
      helpers.cleanup_test_env()
    end)
  end)
end
