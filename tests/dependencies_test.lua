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

    helpers.test("startup plugin dependencies are loaded before parent", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            opts = {},
            dependencies = {
              { 'test/dep', config = function() table.insert(load_order, 'dep') end },
            },
            config = function() table.insert(load_order, 'parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both plugins should load at startup")
      helpers.assert_equal(load_order[1], 'dep', "dependency should load first")
      helpers.assert_equal(load_order[2], 'parent', "parent should load second")

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

    helpers.test("standalone spec overrides lazy inheritance from dependency", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/shared' },
            },
          },
          {
            'test/shared',
            config = function() table.insert(load_order, 'shared') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_equal(#load_order, 1, "shared should load at startup")
      helpers.assert_equal(load_order[1], 'shared')
      helpers.assert_nil(
        state.unloaded_plugin_names['shared'],
        "standalone spec should make plugin startup, not lazy"
      )
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-parent'] or false,
        "lazy-parent should still be lazy"
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

    helpers.test("three-way circular dependency in startup plugins is handled gracefully", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/p1',
            dependencies = { 'test/p2' },
            config = function() table.insert(load_order, 'p1') end,
          },
          {
            'test/p2',
            dependencies = { 'test/p3' },
            config = function() table.insert(load_order, 'p2') end,
          },
          {
            'test/p3',
            dependencies = { 'test/p1' },
            config = function() table.insert(load_order, 'p3') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_equal(state.spec_registry['https://github.com/test/p1'].load_status, "loaded")
      helpers.assert_equal(state.spec_registry['https://github.com/test/p2'].load_status, "loaded")
      helpers.assert_equal(state.spec_registry['https://github.com/test/p3'].load_status, "loaded")
      helpers.assert_equal(#load_order, 3, "all three plugins should load despite cycle")

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone spec loads before dependent even when also declared as dependency", function()
      helpers.setup_test_env()
      local load_order = {}

      -- Simulates blink.lua + pkl.lua scenario:
      -- LuaSnip defined standalone in blink.lua AND as dependency in pkl.lua
      -- blink.cmp defined after LuaSnip in same file
      -- LuaSnip should load first due to import order
      require('zpack').setup({
        spec = {
          { 'test/luasnip', config = function() table.insert(load_order, 'luasnip') end },
          { 'test/blink', config = function() table.insert(load_order, 'blink') end },
          {
            'test/pkl',
            ft = 'pkl',
            dependencies = { 'test/luasnip' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both startup plugins should load")
      helpers.assert_equal(load_order[1], 'luasnip', "luasnip should load first (lower import order)")
      helpers.assert_equal(load_order[2], 'blink', "blink should load second")

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

    helpers.test("src_to_pack_spec contains resolved pack_spec with name", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/no-explicit-name' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/no-explicit-name'

      helpers.assert_not_nil(state.src_to_pack_spec[src], "src_to_pack_spec should be populated")
      helpers.assert_not_nil(state.src_to_pack_spec[src].name, "pack_spec should have resolved name")
      helpers.assert_equal(state.src_to_pack_spec[src].name, "no-explicit-name")

      helpers.cleanup_test_env()
    end)

    helpers.test("startup plugin with lazy dependency loads dep before config", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-dep',
            event = 'VeryLazy',
            config = function() table.insert(load_order, 'lazy-dep') end,
          },
          {
            'test/startup-parent',
            dependencies = { 'test/lazy-dep' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both plugins should load")
      helpers.assert_equal(load_order[1], 'lazy-dep', "lazy dependency should load first")
      helpers.assert_equal(load_order[2], 'startup-parent', "startup parent should load second")

      helpers.cleanup_test_env()
    end)

    helpers.test("startup plugin with multiple lazy dependencies loads all deps", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          { 'test/lazy-dep1', cmd = 'Dep1Cmd', config = function() table.insert(load_order, 'lazy-dep1') end },
          { 'test/lazy-dep2', ft = 'testft', config = function() table.insert(load_order, 'lazy-dep2') end },
          {
            'test/startup-parent',
            dependencies = { 'test/lazy-dep1', 'test/lazy-dep2' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 3, "all three plugins should load")
      helpers.assert_true(
        vim.tbl_contains(vim.list_slice(load_order, 1, 2), 'lazy-dep1'),
        "lazy-dep1 should load before parent"
      )
      helpers.assert_true(
        vim.tbl_contains(vim.list_slice(load_order, 1, 2), 'lazy-dep2'),
        "lazy-dep2 should load before parent"
      )
      helpers.assert_equal(load_order[3], 'startup-parent', "startup parent should load last")

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency-only plugin is loaded for startup parent even when lazy parent exists", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/shared-dep', config = function() table.insert(load_order, 'shared-dep') end },
            },
          },
          {
            'test/startup-parent',
            dependencies = { 'test/shared-dep' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "shared-dep and startup-parent should load")
      helpers.assert_equal(load_order[1], 'shared-dep', "shared dependency should load first")
      helpers.assert_equal(load_order[2], 'startup-parent', "startup parent should load second")

      local state = require('zpack.state')
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-parent'] or false,
        "lazy-parent should still be unloaded"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("deeply nested startup dependencies (4+ levels) load in order", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/level-a',
            dependencies = {
              {
                'test/level-b',
                dependencies = {
                  {
                    'test/level-c',
                    dependencies = {
                      {
                        'test/level-d',
                        dependencies = {
                          { 'test/level-e', config = function() table.insert(load_order, 'e') end },
                        },
                        config = function() table.insert(load_order, 'd') end,
                      },
                    },
                    config = function() table.insert(load_order, 'c') end,
                  },
                },
                config = function() table.insert(load_order, 'b') end,
              },
            },
            config = function() table.insert(load_order, 'a') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 5, "all 5 levels should load")
      helpers.assert_equal(load_order[1], 'e', "deepest dependency (e) should load first")
      helpers.assert_equal(load_order[2], 'd', "d should load second")
      helpers.assert_equal(load_order[3], 'c', "c should load third")
      helpers.assert_equal(load_order[4], 'b', "b should load fourth")
      helpers.assert_equal(load_order[5], 'a', "root (a) should load last")

      helpers.cleanup_test_env()
    end)

    helpers.test("diamond dependency pattern loads shared dependency once", function()
      helpers.setup_test_env()
      local load_order = {}

      -- Diamond pattern:
      --     A (shared base)
      --    / \
      --   B   C
      --    \ /
      --     D (root)
      require('zpack').setup({
        spec = {
          {
            'test/d-root',
            dependencies = {
              {
                'test/d-left',
                dependencies = { { 'test/d-base', config = function() table.insert(load_order, 'base') end } },
                config = function() table.insert(load_order, 'left') end,
              },
              {
                'test/d-right',
                dependencies = { 'test/d-base' },
                config = function() table.insert(load_order, 'right') end,
              },
            },
            config = function() table.insert(load_order, 'root') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      local base_count = 0
      for _, name in ipairs(load_order) do
        if name == 'base' then base_count = base_count + 1 end
      end

      helpers.assert_equal(base_count, 1, "shared base should load exactly once")
      helpers.assert_equal(#load_order, 4, "all 4 plugins should load")

      local base_pos = vim.fn.index(load_order, 'base') + 1
      local left_pos = vim.fn.index(load_order, 'left') + 1
      local right_pos = vim.fn.index(load_order, 'right') + 1
      local root_pos = vim.fn.index(load_order, 'root') + 1

      helpers.assert_true(base_pos < left_pos, "base should load before left")
      helpers.assert_true(base_pos < right_pos, "base should load before right")
      helpers.assert_true(left_pos < root_pos, "left should load before root")
      helpers.assert_true(right_pos < root_pos, "right should load before root")

      helpers.assert_equal(
        state.spec_registry['https://github.com/test/d-base'].load_status,
        "loaded",
        "base should be fully loaded"
      )

      helpers.cleanup_test_env()
    end)
  end)
end
