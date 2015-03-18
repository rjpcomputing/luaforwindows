--- Lua standard library
-- <ul>
-- <li>TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; OO vs non-OO (a thorny problem).</li>
-- <li>TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies.</li>
-- <li>TODO: pre-compile.</li>
-- </ul>
module ("std", package.seeall)

version = "General Lua libraries / 25"

for _, m in ipairs (require "modules") do
  require (m)
end
