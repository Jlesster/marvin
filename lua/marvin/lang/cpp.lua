-- lua/marvin/lang/cpp.lua
-- C/C++ language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function cr() return require('marvin.creator.cpp') end
local function det() return require('marvin.detector') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = p.type == 'cmake' and '[CMake]' or '[Makefile]'
  return string.format('%s  %s', info.name or p.name, kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  -- File creation (from creator/cpp.lua)
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Build
  add(sep('Build'))
  local tool = p.type == 'cmake' and 'CMake' or 'Make'
  add(item('build_menu', '󰑕', tool .. '…', 'Configure, build, test, install, clean'))

  -- Project files
  add(sep('Project Files'))
  add(item('proj_files_menu', '󰈙', 'Build System…',
    'Makefile, CMakeLists.txt, compile_commands.json'))

  return items
end

-- ── Submenu: Build ────────────────────────────────────────────────────────────
function M.show_build_menu(p, back)
  local items = {}
  if p.type == 'cmake' then
    items = {
      { id = 'cmake_cfg', label = '󰒓 Configure', desc = 'cmake -B build -S .' },
      { id = 'cmake_build', label = '󰑕 Build', desc = 'cmake --build build' },
      { id = 'cmake_test', label = '󰙨 Test', desc = 'ctest --test-dir build' },
      { id = 'cmake_install', label = '󰇚 Install', desc = 'cmake --install build' },
      { id = 'cmake_clean', label = '󰃢 Clean', desc = 'cmake --build build --target clean' },
    }
  else
    items = {
      { id = 'make_build', label = '󰑕 Build', desc = 'make' },
      { id = 'make_test', label = '󰙨 Test', desc = 'make test' },
      { id = 'make_install', label = '󰇚 Install', desc = 'make install' },
      { id = 'make_clean', label = '󰃢 Clean', desc = 'make clean' },
    }
  end
  ui().select(items, { prompt = 'Build', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Project Files ────────────────────────────────────────────────────
function M.show_proj_files_menu(p, back)
  local items = {
    {
      id    = 'gen_makefile',
      label = '󰈙 New/Regenerate Makefile',
      desc  = 'Interactive Makefile wizard (C, C++, Go, Rust, Generic)',
    },
    {
      id    = 'gen_cmake',
      label = '󰒓 New/Regenerate CMakeLists.txt',
      desc  = 'Interactive CMake wizard with auto-link detection',
    },
    {
      id    = 'gen_compile_commands',
      label = '󰘦 Generate compile_commands.json',
      desc  = 'For clangd — via cmake, bear, or compiledb',
    },
  }
  ui().select(items, {
    prompt      = 'Build System',
    on_back     = back,
    format_item = plain,
  }, function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── compile_commands.json generator ──────────────────────────────────────────
function M.generate_compile_commands(p, back)
  local root          = p and p.root or vim.fn.getcwd()

  -- Detect which method is available
  local has_cmake     = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_make      = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_bear      = vim.fn.executable('bear') == 1
  local has_compdb    = vim.fn.executable('compiledb') == 1
  local has_cmake_bin = vim.fn.executable('cmake') == 1

  local items         = {}
  local function add(t) items[#items + 1] = t end

  -- CMake is the best option — it generates natively
  if has_cmake and has_cmake_bin then
    add({
      id    = 'ccmd_cmake',
      label = '󰒓 CMake (recommended)',
      desc  = 'cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .',
    })
  end

  -- bear wraps any build system
  if has_bear then
    if has_make then
      add({
        id    = 'ccmd_bear_make',
        label = '󰈙 bear + make',
        desc  = 'bear -- make  (wraps your Makefile build)',
      })
    end
    add({
      id    = 'ccmd_bear_custom',
      label = '󰈙 bear + custom command…',
      desc  = 'bear -- <your build command>',
    })
  end

  -- compiledb for Make-based projects
  if has_compdb and has_make then
    add({
      id    = 'ccmd_compiledb',
      label = '󰘦 compiledb',
      desc  = 'compiledb make  (python-based, pip install compiledb)',
    })
  end

  -- Manual fallback — always available
  add({
    id    = 'ccmd_clangd_file',
    label = '󰄬 .clangd config (no build needed)',
    desc  = 'Write .clangd with -Iinclude flags instead',
  })

  -- Install hints if nothing useful found
  if #items == 1 then -- only the .clangd fallback
    add({
      id    = 'ccmd_install_hint',
      label = '󰋖 How to install bear / compiledb',
      desc  = 'Show install instructions',
    })
  end

  ui().select(items, {
    prompt      = 'Generate compile_commands.json',
    on_back     = back,
    format_item = plain,
  }, function(ch)
    if not ch then return end

    local function run(cmd, title)
      require('core.runner').execute({
        cmd      = cmd,
        cwd      = root,
        title    = title,
        term_cfg = require('marvin').config.terminal,
        plugin   = 'marvin',
        on_exit  = function(ok)
          if ok then
            -- For cmake: symlink compile_commands.json to root
            if ch.id == 'ccmd_cmake' then
              vim.defer_fn(function()
                local src = root .. '/build/compile_commands.json'
                local dst = root .. '/compile_commands.json'
                if vim.fn.filereadable(src) == 1 then
                  vim.fn.system('ln -sf ' .. vim.fn.shellescape(src)
                    .. ' ' .. vim.fn.shellescape(dst))
                  vim.notify(
                    '[Marvin] compile_commands.json → ' .. dst
                    .. '\nRestart clangd: :LspRestart',
                    vim.log.levels.INFO)
                end
              end, 500)
            else
              vim.notify(
                '[Marvin] compile_commands.json written.\nRestart clangd: :LspRestart',
                vim.log.levels.INFO)
            end
          end
        end,
      })
    end

    if ch.id == 'ccmd_cmake' then
      run('cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON', 'Generate compile_commands.json')
    elseif ch.id == 'ccmd_bear_make' then
      run('bear -- make', 'bear + make')
    elseif ch.id == 'ccmd_bear_custom' then
      ui().input({ prompt = 'Build command for bear', default = 'make' }, function(cmd)
        if cmd and cmd ~= '' then
          run('bear -- ' .. cmd, 'bear + ' .. cmd)
        end
      end)
    elseif ch.id == 'ccmd_compiledb' then
      run('compiledb make', 'compiledb')
    elseif ch.id == 'ccmd_clangd_file' then
      -- Detect include dirs that exist
      local inc_flags = {}
      for _, d in ipairs({ 'include', 'src', '.' }) do
        if vim.fn.isdirectory(root .. '/' .. d) == 1 then
          inc_flags[#inc_flags + 1] = '-I' .. d
        end
      end
      local cfg   = require('marvin').config.cpp or {}
      local std   = cfg.standard or 'c11'
      -- Detect C vs C++ from compiler setting
      local lang  = (cfg.compiler == 'g++' or cfg.compiler == 'clang++') and 'c++' or 'c'

      -- Build flags: includes, then std, then -x and lang as SEPARATE entries
      -- clangd requires -x and the language to be separate argv tokens
      local flags = {}
      for _, f in ipairs(inc_flags) do flags[#flags + 1] = f end
      flags[#flags + 1]    = '-std=' .. std
      flags[#flags + 1]    = '-x'
      flags[#flags + 1]    = lang

      local clangd_content = 'CompileFlags:\n  Add: [' .. table.concat(flags, ', ') .. ']\n'
      local clangd_path    = root .. '/.clangd'

      if vim.fn.filereadable(clangd_path) == 1 then
        ui().select({
            { id = 'overwrite', label = 'Overwrite existing .clangd' },
            { id = 'cancel',    label = 'Cancel' },
          }, { prompt = '.clangd already exists', format_item = plain },
          function(ow)
            if ow and ow.id == 'overwrite' then
              local f = io.open(clangd_path, 'w')
              if f then
                f:write(clangd_content); f:close()
                vim.cmd('edit ' .. vim.fn.fnameescape(clangd_path))
                vim.notify('[Marvin] .clangd written. Run :LspRestart', vim.log.levels.INFO)
              end
            end
          end)
      else
        local f = io.open(clangd_path, 'w')
        if f then
          f:write(clangd_content); f:close()
          vim.cmd('edit ' .. vim.fn.fnameescape(clangd_path))
          vim.notify('[Marvin] .clangd written. Run :LspRestart', vim.log.levels.INFO)
        end
      end
    elseif ch.id == 'ccmd_install_hint' then
      local lines = {
        '',
        '  Install bear (recommended):',
        '    Ubuntu/Debian:  sudo apt install bear',
        '    macOS:          brew install bear',
        '    Arch:           sudo pacman -S bear',
        '',
        '  Install compiledb (Python, Make-based projects):',
        '    pip install compiledb',
        '',
        '  Or use CMake — it generates compile_commands.json natively:',
        '    cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
        '    ln -sf build/compile_commands.json .',
        '',
      }
      vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
    end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  -- Delegate file-creation actions to creator/cpp.lua
  if cr().handle(id, back) then return end

  if id == 'build_menu' then
    M.show_build_menu(p, back)
  elseif id == 'proj_files_menu' then
    M.show_proj_files_menu(p, back)

    -- Project file generators
  elseif id == 'gen_makefile' then
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_cmake' then
    require('marvin.cmake_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_compile_commands' then
    M.generate_compile_commands(p, back)

    -- Build actions
  elseif id == 'cmake_cfg' then
    local function run(cmd, title)
      require('core.runner').execute({
        cmd = cmd,
        cwd = p.root,
        title = title,
        term_cfg = require('marvin').config.terminal,
        plugin = 'marvin',
      })
    end
    run('cmake -B build -S .', 'CMake Configure')
  elseif id == 'cmake_build' then
    require('core.runner').execute({
      cmd = 'cmake --build build',
      cwd = p.root,
      title = 'CMake Build',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_test' then
    require('core.runner').execute({
      cmd = 'ctest --test-dir build',
      cwd = p.root,
      title = 'CTest',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_clean' then
    require('core.runner').execute({
      cmd = 'cmake --build build --target clean',
      cwd = p.root,
      title = 'CMake Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_install' then
    require('core.runner').execute({
      cmd = 'cmake --install build',
      cwd = p.root,
      title = 'CMake Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_build' then
    require('core.runner').execute({
      cmd = 'make',
      cwd = p.root,
      title = 'Make',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_test' then
    require('core.runner').execute({
      cmd = 'make test',
      cwd = p.root,
      title = 'Make Test',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_clean' then
    require('core.runner').execute({
      cmd = 'make clean',
      cwd = p.root,
      title = 'Make Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_install' then
    require('core.runner').execute({
      cmd = 'make install',
      cwd = p.root,
      title = 'Make Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  end
end

return M
