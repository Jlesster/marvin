-- Class template
function M.class_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  -- Only add javadoc if enabled in config (unless explicitly overridden in options)
  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local modifier = options.modifier or "public"
  local extends = options.extends and (" extends " .. options.extends) or ""
  local implements = ""
  if options.implements and #options.implements > 0 then
    implements = " implements " .. table.concat(options.implements, ", ")
  end

  table.insert(lines, modifier .. " class " .. name .. extends .. implements .. " {")
  table.insert(lines, "")

  if options.main then
    table.insert(lines, "  public static void main(String[] args) {")
    table.insert(lines, "    // TODO: Implementation")
    table.insert(lines, "  }")
  else
    table.insert(lines, "  // TODO: Implementation")
  end

  table.insert(lines, "}")

  return lines
end

-- Interface template
function M.interface_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local extends = ""
  if options.extends and #options.extends > 0 then
    extends = " extends " .. table.concat(options.extends, ", ")
  end

  table.insert(lines, "public interface " .. name .. extends .. " {")
  table.insert(lines, "")
  table.insert(lines, "  // TODO: Define methods")
  table.insert(lines, "}")

  return lines
end

-- Enum template
function M.enum_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public enum " .. name .. " {")

  local values = options.values or { "VALUE1", "VALUE2", "VALUE3" }
  for i, value in ipairs(values) do
    local comma = i < #values and "," or ";"
    table.insert(lines, "  " .. value .. comma)
  end

  table.insert(lines, "}")

  return lines
end

-- Record template (Java 14+)
function M.record_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local fields = options.fields or {
    { type = "String", name = "name" },
    { type = "int",    name = "value" }
  }

  local field_list = {}
  for _, field in ipairs(fields) do
    table.insert(field_list, field.type .. " " .. field.name)
  end

  table.insert(lines, "public record " .. name .. "(" .. table.concat(field_list, ", ") .. ") {")
  table.insert(lines, "}")

  return lines
end

-- Exception template
function M.exception_template(name, package, options)
  options = options or {}
  options.extends = options.extends or "Exception"
  options.imports = options.imports or {}

  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public class " .. name .. " extends " .. options.extends .. " {")
  table.insert(lines, "")
  table.insert(lines, "  public " .. name .. "() {")
  table.insert(lines, "    super();")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  public " .. name .. "(String message) {")
  table.insert(lines, "    super(message);")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  public " .. name .. "(String message, Throwable cause) {")
  table.insert(lines, "    super(message, cause);")
  table.insert(lines, "  }")
  table.insert(lines, "}")

  return lines
end

-- Builder pattern template
function M.builder_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  local fields = options.fields or {
    { type = "String", name = "name",  required = true },
    { type = "int",    name = "value", required = false }
  }

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public class " .. name .. " {")
  table.insert(lines, "")

  -- Fields
  for _, field in ipairs(fields) do
    table.insert(lines, "  private final " .. field.type .. " " .. field.name .. ";")
  end
  table.insert(lines, "")

  -- Private constructor
  table.insert(lines, "  private " .. name .. "(Builder builder) {")
  for _, field in ipairs(fields) do
    table.insert(lines, "    this." .. field.name .. " = builder." .. field.name .. ";")
  end
  table.insert(lines, "  }")
  table.insert(lines, "")

  -- Getters
  for _, field in ipairs(fields) do
    local getter_name = "get" .. field.name:sub(1, 1):upper() .. field.name:sub(2)
    table.insert(lines, "  public " .. field.type .. " " .. getter_name .. "() {")
    table.insert(lines, "    return " .. field.name .. ";")
    table.insert(lines, "  }")
    table.insert(lines, "")
  end

  -- Builder class
  table.insert(lines, "  public static class Builder {")
  for _, field in ipairs(fields) do
    table.insert(lines, "    private " .. field.type .. " " .. field.name .. ";")
  end
  table.insert(lines, "")

  -- Builder methods
  for _, field in ipairs(fields) do
    table.insert(lines, "    public Builder " .. field.name .. "(" .. field.type .. " " .. field.name .. ") {")
    table.insert(lines, "      this." .. field.name .. " = " .. field.name .. ";")
    table.insert(lines, "      return this;")
    table.insert(lines, "    }")
    table.insert(lines, "")
  end

  table.insert(lines, "    public " .. name .. " build() {")
  -- Add validation for required fields
  for _, field in ipairs(fields) do
    if field.required then
      table.insert(lines, "      if (" .. field.name .. " == null) {")
      table.insert(lines, "        throw new IllegalStateException(\"" .. field.name .. " is required\");")
      table.insert(lines, "      }")
    end
  end
  table.insert(lines, "      return new " .. name .. "(this);")
  table.insert(lines, "    }")
  table.insert(lines, "  }")
  table.insert(lines, "}")

  return lines
end
