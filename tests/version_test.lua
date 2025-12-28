local helpers = require('helpers')

return function()
  helpers.describe("Version Normalization", function()
    helpers.test("version field takes priority over other version fields", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            version = 'main',
            branch = 'develop',
            tag = 'v1.0.0',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'main', "version field should take priority")

      helpers.cleanup_test_env()
    end)

    helpers.test("sem_version field is wrapped with vim.version.range()", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            sem_version = '^6',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")

      local version = vim_pack_call[1].version
      helpers.assert_not_nil(version, "version should be set")
      helpers.assert_equal(type(version), 'table', "sem_version should be converted to vim.VersionRange")
      helpers.assert_not_nil(version.from, "vim.VersionRange should have 'from' field")

      helpers.cleanup_test_env()
    end)

    helpers.test("branch field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            branch = 'develop',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'develop', "branch should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("tag field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            tag = 'v1.0.0',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'v1.0.0', "tag should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("commit field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            commit = 'abc123def',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'abc123def', "commit should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("sem_version takes priority over branch/tag/commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            sem_version = '^1.0.0',
            branch = 'main',
            tag = 'v1.0.0',
            commit = 'abc123',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")

      local version = vim_pack_call[1].version
      helpers.assert_equal(type(version), 'table', "sem_version should be used and converted to vim.VersionRange")

      helpers.cleanup_test_env()
    end)

    helpers.test("branch takes priority over tag and commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            branch = 'develop',
            tag = 'v1.0.0',
            commit = 'abc123',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'develop', "branch should take priority over tag and commit")

      helpers.cleanup_test_env()
    end)

    helpers.test("tag takes priority over commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            tag = 'v2.0.0',
            commit = 'abc123',
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'v2.0.0', "tag should take priority over commit")

      helpers.cleanup_test_env()
    end)

    helpers.test("no version fields results in nil version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin' },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_nil(vim_pack_call[1].version, "version should be nil when no version fields provided")

      helpers.cleanup_test_env()
    end)

    helpers.test("vim.VersionRange passed directly through version field", function()
      helpers.setup_test_env()

      local range = vim.version.range('^6')
      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            version = range,
          },
        },
        confirm = false,
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, range, "vim.VersionRange should be passed through directly")

      helpers.cleanup_test_env()
    end)
  end)
end
