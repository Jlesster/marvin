-- lua/marvin/creator/java.lua
-- Alias: the Java creator lives at marvin.java_creator (unchanged from original).
-- This shim lets lang/java.lua use the consistent  require('marvin.creator.java')  path.
return require('marvin.java_creator')
