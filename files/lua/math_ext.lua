--- Additions to the math module.
module ("math", package.seeall)


local _floor = floor

--- Extend <code>math.floor</code> to take the number of decimal places.
-- @param n number
-- @param p number of decimal places to truncate to (default: 0)
-- @return <code>n</code> truncated to <code>p</code> decimal places
function floor (n, p)
  if p and p ~= 0 then
    local e = 10 ^ p
    return _floor (n * e) / e
  else
    return _floor (n)
  end
end

--- Round a number to a given number of decimal places
-- @param n number
-- @param p number of decimal places to round to (default: 0)
-- @return <code>n</code> rounded to <code>p</code> decimal places
function round (n, p)
  local e = 10 ^ (p or 0)
  return _floor (n * e + 0.5) / e
end
