local M = {}

--- Returns true when the current JAVA_HOME (or PATH java) is a GraalVM distro.
function M.is_graalvm()
  local java_home = os.getenv('JAVA_HOME') or ''
  -- GraalVM sets GRAALVM_HOME or embeds "graalvm" / "graal" in JAVA_HOME path
  if java_home:lower():match('graal') then return true end
  if os.getenv('GRAALVM_HOME') then return true end
  -- Fallback: ask the JVM itself
  local out = vim.trim(vim.fn.system('java -version 2>&1'))
  return out:lower():match('graalvm') ~= nil
end

--- Returns the GraalVM home directory (best-effort).
function M.graalvm_home()
  return os.getenv('GRAALVM_HOME')
      or os.getenv('JAVA_HOME')
      or vim.trim(vim.fn.system("dirname $(dirname $(readlink -f $(which java))) 2>/dev/null"))
end

--- Returns the path to the native-image binary, or nil if not installed.
function M.native_image_bin()
  local home = M.graalvm_home()
  local candidates = {
    home .. '/bin/native-image',
    home .. '/lib/svm/bin/native-image',
    vim.trim(vim.fn.system('which native-image 2>/dev/null')),
  }
  for _, p in ipairs(candidates) do
    if p ~= '' and vim.fn.executable(p) == 1 then return p end
  end
  return nil
end

--- Returns the path to the gu (GraalVM Updater) binary, or nil.
function M.gu_bin()
  local home = M.graalvm_home()
  local p = home .. '/bin/gu'
  if vim.fn.executable(p) == 1 then return p end
  local wp = vim.trim(vim.fn.system('which gu 2>/dev/null'))
  if wp ~= '' and vim.fn.executable(wp) == 1 then return wp end
  return nil
end

-- ── Config (merged from jason.config.graalvm) ───────────────────────────────

local defaults = {
  -- extra flags forwarded to native-image
  extra_build_args = '',
  -- where the native binary is written (relative to project root)
  output_dir       = 'target/native',
  -- whether to pass --no-fallback (recommended for true native)
  no_fallback      = true,
  -- whether to enable G1GC in native image (GraalVM EE only, ignored on CE)
  g1gc             = false,
  -- PGO: 'none' | 'instrument' | 'optimize'
  pgo              = 'none',
  -- Report size breakdown
  report_size      = true,
  -- Path to native-image-agent output dir (for config generation)
  agent_output_dir = 'src/main/resources/META-INF/native-image',
}

function M.get_config()
  local ok, jason = pcall(require, 'jason')
  if ok and jason.config and jason.config.graalvm then
    return vim.tbl_deep_extend('force', defaults, jason.config.graalvm)
  end
  return defaults
end

-- ── Command builders ─────────────────────────────────────────────────────────

--- Build the native-image command for a Maven project.
function M.native_image_cmd_maven(project)
  local cfg = M.get_config()
  local parts = { 'mvn -Pnative native:compile' }
  if cfg.extra_build_args ~= '' then
    parts[#parts + 1] = '-Dnative.image.buildArgs="' .. cfg.extra_build_args .. '"'
  end
  return table.concat(parts, ' ')
end

--- Build the native-image command for a Gradle project.
function M.native_image_cmd_gradle(project)
  local cfg = M.get_config()
  local parts = { './gradlew nativeCompile' }
  if cfg.extra_build_args ~= '' then
    parts[#parts + 1] = '-PnativeBuildArgs="' .. cfg.extra_build_args .. '"'
  end
  return table.concat(parts, ' ')
end

--- Build a bare native-image invocation (single JAR or class).
function M.native_image_cmd_jar(project)
  local cfg = M.get_config()
  local bin = M.native_image_bin()
  if not bin then
    return nil, 'native-image not found – run: gu install native-image'
  end

  -- Find the fat/shaded jar or the regular one
  local jar = M.find_jar(project)
  if not jar then
    return nil, 'No JAR found – run Build first'
  end

  local base = vim.fn.fnamemodify(jar, ':t:r')
  local out  = (cfg.output_dir ~= '' and (project.root .. '/' .. cfg.output_dir .. '/') or '')
      .. base

  local args = { bin, '-jar', vim.fn.shellescape(jar), '-o', vim.fn.shellescape(out) }

  if cfg.no_fallback then args[#args + 1] = '--no-fallback' end
  if cfg.g1gc then args[#args + 1] = '--gc=G1' end
  if cfg.report_size then args[#args + 1] = '-H:+PrintAnalysisCallTree' end

  if cfg.pgo == 'instrument' then
    args[#args + 1] = '--pgo-instrument'
  elseif cfg.pgo == 'optimize' then
    args[#args + 1] = '--pgo'
  end

  if cfg.extra_build_args ~= '' then
    args[#args + 1] = cfg.extra_build_args
  end

  return table.concat(args, ' '), nil
end

--- Returns the path to the produced native binary, or nil.
function M.find_native_binary(project)
  local cfg  = M.get_config()
  local dirs = {
    project.root .. '/' .. cfg.output_dir,
    project.root .. '/target',
    project.root .. '/build/native/nativeCompile',
    project.root .. '/build',
  }
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local handle = io.popen(
        'find ' .. vim.fn.shellescape(dir) ..
        ' -maxdepth 2 -type f -executable ! -name "*.so" ! -name "*.dylib" 2>/dev/null | head -1')
      if handle then
        local p = handle:read('*l'); handle:close()
        if p and p ~= '' then return p end
      end
    end
  end
  return nil
end

--- Finds the best JAR in the project (fat/shaded preferred).
function M.find_jar(project)
  local dirs = {
    project.root .. '/target',
    project.root .. '/build/libs',
  }
  local best = nil
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local jars = vim.fn.globpath(dir, '*.jar', false, true)
      for _, j in ipairs(jars) do
        if j:match('%-all%.jar') or j:match('%-shaded%.jar') or j:match('%-fat%.jar') then
          return j
        end
        -- prefer non-sources, non-javadoc
        if not j:match('%-sources%.jar') and not j:match('%-javadoc%.jar') then
          best = j
        end
      end
    end
  end
  return best
end

-- ── High-level actions (called from executor / dashboard) ───────────────────

function M.build_native(project)
  local ex = require('jason.executor')
  local cmd, err

  if project.type == 'maven' then
    cmd = M.native_image_cmd_maven(project)
  elseif project.type == 'gradle' then
    cmd = M.native_image_cmd_gradle(project)
  else
    cmd, err = M.native_image_cmd_jar(project)
  end

  if err then
    vim.notify('[GraalVM] ' .. err, vim.log.levels.ERROR); return
  end

  -- Ensure output dir exists
  local cfg    = M.get_config()
  local outdir = project.root .. '/' .. cfg.output_dir
  vim.fn.mkdir(outdir, 'p')

  ex.execute(cmd, project.root, 'Native Image')
end

function M.run_native(project)
  local ex  = require('jason.executor')
  local bin = M.find_native_binary(project)
  if not bin then
    vim.notify('[GraalVM] Native binary not found – build it first', vim.log.levels.WARN)
    return
  end
  ex.execute(vim.fn.shellescape(bin), project.root, 'Run Native')
end

function M.build_and_run_native(project)
  local ex  = require('jason.executor')
  local cfg = M.get_config()
  local build_cmd, err

  if project.type == 'maven' then
    build_cmd = M.native_image_cmd_maven(project)
  elseif project.type == 'gradle' then
    build_cmd = M.native_image_cmd_gradle(project)
  else
    build_cmd, err = M.native_image_cmd_jar(project)
  end

  if err then
    vim.notify('[GraalVM] ' .. err, vim.log.levels.ERROR); return
  end

  vim.fn.mkdir(project.root .. '/' .. cfg.output_dir, 'p')

  ex.execute_sequence({
    { cmd = build_cmd, title = 'Native Image Build' },
    {
      -- Delay resolving the binary until after the build finishes
      cmd   = 'sh -c ' .. vim.fn.shellescape(
        'BIN=$(find ' .. vim.fn.shellescape(project.root) ..
        ' -maxdepth 4 -type f -executable ! -name "*.so" ! -name "*.dylib" ' ..
        '-newer ' .. vim.fn.shellescape(project.root) .. '/pom.xml 2>/dev/null | head -1); ' ..
        'test -n "$BIN" && exec "$BIN" || echo "Binary not found" >&2 && exit 1'),
      title = 'Run Native',
    },
  }, project.root)
end

--- Run with the native-image tracing agent to collect reflection config.
function M.run_with_agent(project)
  local ex  = require('jason.executor')
  local cfg = M.get_config()
  local jar = M.find_jar(project)
  if not jar then
    vim.notify('[GraalVM] No JAR found – build the project first', vim.log.levels.WARN)
    return
  end
  local agent_dir = project.root .. '/' .. cfg.agent_output_dir
  vim.fn.mkdir(agent_dir, 'p')
  local cmd = string.format(
    'java -agentlib:native-image-agent=config-output-dir=%s -jar %s',
    vim.fn.shellescape(agent_dir), vim.fn.shellescape(jar))
  ex.execute(cmd, project.root, 'Agent Run')
  vim.notify('[GraalVM] Agent config will be written to: ' .. agent_dir, vim.log.levels.INFO)
end

--- Show a quick GraalVM info/status floating window.
function M.show_info()
  local lines       = { '', '  GraalVM Status', '  ' .. string.rep('─', 32), '' }
  local ni_bin      = M.native_image_bin()
  local gu_b        = M.gu_bin()
  local gvm         = M.is_graalvm()
  local home        = M.graalvm_home()

  lines[#lines + 1] = string.format('  %-22s %s', 'Active GraalVM:', gvm and '✔' or '✗ (not detected)')
  lines[#lines + 1] = string.format('  %-22s %s', 'GRAALVM_HOME:', home ~= '' and home or '(not set)')
  lines[#lines + 1] = string.format('  %-22s %s', 'native-image:', ni_bin or '✗ not installed')
  lines[#lines + 1] = string.format('  %-22s %s', 'gu (updater):', gu_b or '✗ not found')
  lines[#lines + 1] = ''

  if not ni_bin then
    lines[#lines + 1] = '  To install native-image:'
    lines[#lines + 1] = '    gu install native-image'
    lines[#lines + 1] = '  or with SDKMAN:'
    lines[#lines + 1] = '    sdk install java <graalvm-version>'
    lines[#lines + 1] = ''
  end

  local cfg = M.get_config()
  lines[#lines + 1] = '  Config'
  lines[#lines + 1] = '  ' .. string.rep('─', 32)
  lines[#lines + 1] = string.format('  %-22s %s', 'no_fallback:', tostring(cfg.no_fallback))
  lines[#lines + 1] = string.format('  %-22s %s', 'pgo:', cfg.pgo)
  lines[#lines + 1] = string.format('  %-22s %s', 'g1gc:', tostring(cfg.g1gc))
  lines[#lines + 1] = string.format('  %-22s %s', 'output_dir:', cfg.output_dir)
  lines[#lines + 1] = string.format('  %-22s %s', 'agent_output_dir:', cfg.agent_output_dir)
  lines[#lines + 1] = ''

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

--- Install native-image via gu.
function M.install_native_image(project)
  local ex = require('jason.executor')
  local gu = M.gu_bin()
  if not gu then
    vim.notify('[GraalVM] gu not found – is GraalVM in PATH?', vim.log.levels.ERROR)
    return
  end
  ex.execute(gu .. ' install native-image', project and project.root or vim.fn.getcwd(),
    'Install native-image')
end

return M
