local M = {}

M.current_project = nil

function M.detect()
  local pom_path = M.find_pom()

  if pom_path then
    M.current_project = {
      root = vim.fn.fnamemodify(pom_path, ':h'),
      pom_path = pom_path,
      info = M.parse_pom(pom_path),
    }
    return true
  end

  M.current_project = nil
  return false
end

function M.find_pom()
  local curr_file = vim.api.nvim_buf_get_name(0)
  local curr_dir = vim.fn.fnamemodify(curr_file, ':h')

  while curr_dir ~= '/' do
    local pom_path = curr_dir .. '/pom.xml'
    if vim.fn.filereadable(pom_path) == 1 then
      return pom_path
    end
    curr_dir = vim.fn.fnamemodify(curr_dir, ':h')
  end

  return nil
end

function M.get_project()
  if not M.current_project then
    M.detect()
  end
  return M.current_project
end

function M.parse_pom(pom_path)
  local content = M.read_file(pom_path)
  if not content then
    return nil
  end

  return {
    group_id = M.extract_xml_tag(content, 'groupId'),
    artifact_id = M.extract_xml_tag(content, 'artifactId'),
    version = M.extract_xml_tag(content, 'version'),
    packaging = M.extract_xml_tag(content, 'packaging') or 'jar',
    profiles = M.extract_profiles(content),
  }
end

-- FIXED: Added missing read_file function
function M.read_file(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local content = file:read('*all')
  file:close()
  return content
end

function M.extract_xml_tag(content, tag)
  local pattern = '<' .. tag .. '>(.-)</' .. tag .. '>'
  local match = content:match(pattern)
  return match
end

function M.extract_profiles(content)
  local profiles = {}

  for profile_block in content:gmatch('<profile>(.-)</profile>') do
    local id = profile_block:match('<id>(.-)</id>')
    if id then
      table.insert(profiles, id)
    end
  end

  return profiles
end

function M.is_maven_available()
  local config = require('marvin.config')
  local maven_cmd = config.defaults.maven_command
  local handle = io.popen(maven_cmd .. ' --version 2>&1')

  if not handle then
    return false
  end

  local result = handle:read('*all')
  handle:close()

  return result:match('Apache Maven') ~= nil
end

function M.validate_environment()
  if not M.is_maven_available() then
    vim.notify('Maven is not installed', vim.log.levels.ERROR)
    return false
  end

  if not M.get_project() then
    vim.notify('Not in a maven project (pom.xml not found)', vim.log.levels.WARN)
    return false
  end

  return true
end

return M
