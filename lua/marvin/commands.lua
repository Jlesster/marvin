-- lua/marvin/commands.lua

local M = {}

function M.register()
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end

  -- Dashboard
  cmd('Marvin', function() require('marvin.dashboard').show() end, { desc = 'Open Marvin dashboard' })
  cmd('MarvinDashboard', function() require('marvin.dashboard').show() end, { desc = 'Open Marvin dashboard' })

  -- Maven lifecycle
  cmd('MavenCompile', function() require('marvin.executor').run('compile') end, { desc = 'mvn compile' })
  cmd('MavenTest', function() require('marvin.executor').run('test') end, { desc = 'mvn test' })
  cmd('MavenPackage', function() require('marvin.executor').run('package') end, { desc = 'mvn package' })
  cmd('MavenInstall', function() require('marvin.executor').run('install') end, { desc = 'mvn install' })
  cmd('MavenVerify', function() require('marvin.executor').run('verify') end, { desc = 'mvn verify' })
  cmd('MavenClean', function() require('marvin.executor').run('clean') end, { desc = 'mvn clean' })
  cmd('MavenCleanInstall', function() require('marvin.executor').run('clean install') end, { desc = 'mvn clean install' })

  -- Arbitrary goal
  cmd('MavenExec', function(o)
    require('marvin.executor').run(o.args)
  end, { nargs = '+', complete = M.complete_goals, desc = 'Run any Maven goal' })

  -- Inspect
  cmd('MavenDepTree', function() require('marvin.executor').run('dependency:tree') end, { desc = 'mvn dependency:tree' })
  cmd('MavenDepAnalyze', function() require('marvin.executor').run('dependency:analyze') end,
    { desc = 'mvn dependency:analyze' })
  cmd('MavenEffectivePom', function() require('marvin.executor').run('help:effective-pom') end,
    { desc = 'mvn help:effective-pom' })

  -- File creation
  cmd('JavaNew', function() require('marvin.dashboard').show() end, { desc = 'Open Marvin (create Java file)' })
  cmd('MavenNew', function() require('marvin.generator').create_project() end,
    { desc = 'New Maven project from archetype' })

  -- Stop
  cmd('MavenStop', function() require('marvin.executor').stop() end, { desc = 'Stop running Maven job' })
end

function M.complete_goals()
  return {
    'clean', 'compile', 'test', 'package', 'verify', 'install', 'deploy',
    'clean install', 'clean package',
    'dependency:tree', 'dependency:analyze', 'dependency:resolve',
    'help:effective-pom', 'help:effective-settings', 'help:describe',
    'versions:display-dependency-updates',
    'spotless:apply', 'spotless:check',
    'checkstyle:check', 'pmd:check',
    'spring-boot:run',
    'native:compile',
  }
end

return M
