require 'pl'

norm = path.normpath

p = norm '/a/b'

assert(norm '/a/fred/../b' == p)
assert(norm '/a//b' == p)

if path.is_windows then
  assert(norm [[\a\.\b]] == p)
end

