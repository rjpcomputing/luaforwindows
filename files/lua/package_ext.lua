-- Additions to the package module.
module ("package", package.seeall)


--- Make named constants for <code>package.config</code> (undocumented
-- in 5.1; see luaconf.h for C equivalents).
-- @class table
-- @name package
-- @field dirsep directory separator
-- @field pathsep path separator
-- @field path_mark string that marks substitution points in a path template
-- @field execdir (Windows only) replaced by the executable's directory in a path
-- @field igmark Mark to ignore all before it when building <code>luaopen_</code> function name.
dirsep, pathsep, path_mark, execdir, igmark =
  string.match (package.config, "^([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)")
