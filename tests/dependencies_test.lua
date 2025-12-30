local helpers = require('helpers')

return function()
  helpers.describe("Dependencies Field", function()
    helpers.test("string dependency is registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/parent'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep'])

      helpers.cleanup_test_env()
    end)

    helpers.test("array of string dependencies are registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep1', 'test/dep2' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep1'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep2'])

      helpers.cleanup_test_env()
    end)

    helpers.test("inline spec dependency is registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', opts = { from_dep = true } },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep']

      helpers.assert_not_nil(dep_entry)
      helpers.assert_equal(dep_entry.specs[1].opts.from_dep, true)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency graph is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep1', 'test/dep2' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_not_nil(state.dependency_graph[parent_src])
      helpers.assert_equal(vim.tbl_count(state.dependency_graph[parent_src]), 2)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency specs are marked as dependencies", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', opts = {} },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep']

      helpers.assert_true(dep_entry.specs[1]._is_dependency, "dependency spec should be marked")

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone spec is not marked as dependency", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = {} },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local entry = state.spec_registry['https://github.com/test/plugin']

      helpers.assert_false(entry.specs[1]._is_dependency or false)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependencies are loaded before parent on lazy trigger", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            cmd = 'ParentCmd',
            dependencies = { 'test/dep' },
            config = function()
              table.insert(load_order, 'parent')
            end,
          },
          {
            'test/dep',
            config = function()
              table.insert(load_order, 'dep')
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(#load_order, 1, "only standalone dep should load at startup")
      helpers.assert_equal(load_order[1], 'dep')

      pcall(vim.cmd, 'ParentCmd')
      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "parent should load on trigger")
      helpers.assert_equal(load_order[2], 'parent')

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency-only plugin inherits lazy from parent", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/dep-only' },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_true(
        state.unloaded_plugin_names['dep-only'] or false,
        "dependency-only plugin should be lazy when parent is lazy"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("nested dependencies are supported", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              {
                'test/child',
                dependencies = {
                  { 'test/grandchild' },
                },
              },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/parent'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/child'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/grandchild'])

      helpers.cleanup_test_env()
    end)

    helpers.test("duplicate dependencies are not added twice to graph", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep', 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_equal(vim.tbl_count(state.dependency_graph[parent_src]), 1, "should not duplicate dependency")

      helpers.cleanup_test_env()
    end)

    helpers.test("reverse dependency graph is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_src = 'https://github.com/test/dep'
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_not_nil(state.reverse_dependency_graph[dep_src])
      helpers.assert_true(state.reverse_dependency_graph[dep_src][parent_src], "parent should be in reverse graph")

      helpers.cleanup_test_env()
    end)

    helpers.test("circular dependency is detected at runtime and handled gracefully", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/a',
            dependencies = {
              {
                'test/b',
                dependencies = { 'test/a' },
              },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local a_src = 'https://github.com/test/a'
      local b_src = 'https://github.com/test/b'

      helpers.assert_not_nil(state.spec_registry[a_src], "a should be registered")
      helpers.assert_not_nil(state.spec_registry[b_src], "b should be registered")
      helpers.assert_equal(state.spec_registry[a_src].load_status, "loaded", "a should be loaded")
      helpers.assert_equal(state.spec_registry[b_src].load_status, "loaded", "b should be loaded")

      helpers.cleanup_test_env()
    end)

    helpers.test("self-dependency is detected at runtime and handled gracefully", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/self',
            dependencies = { 'test/self' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/self'

      helpers.assert_not_nil(state.spec_registry[src], "plugin should be registered")
      helpers.assert_equal(state.spec_registry[src].load_status, "loaded", "plugin should be loaded")

      helpers.cleanup_test_env()
    end)

    helpers.test("src_to_pack_spec index is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'

      helpers.assert_not_nil(state.src_to_pack_spec[src], "src_to_pack_spec should be populated")
      helpers.assert_equal(state.src_to_pack_spec[src].src, src)

      helpers.cleanup_test_env()
    end)
  end)
end
