--- Longest Common Subsequence algorithm.
-- After pseudo-code in <a
-- href="http://www.ics.uci.edu/~eppstein/161/960229.html">lecture
-- notes</a> by <a href="mailto:eppstein@ics.uci.edu">David Eppstein</a>.
module ("lcs", package.seeall)


-- Find common subsequences.
-- @param a first sequence
-- @param b second sequence
-- @return list of common subsequences
-- @return the length of a
-- @return the length of b
local function commonSubseqs (a, b)
  local l, m, n = {}, #a, #b
  for i = m + 1, 1, -1 do
    l[i] = {}
    for j = n + 1, 1, -1 do
      if i > m or j > n then
        l[i][j] = 0
      elseif a[i] == b[j] then
        l[i][j] = 1 + l[i + 1][j + 1]
      else
        l[i][j] = math.max (l[i + 1][j], l[i][j + 1])
      end
    end
  end
  return l, m, n
end

--- Find the longest common subsequence of two sequences.
-- The sequence objects must have an <code>__append</code> metamethod.
-- This is provided by <code>string_ext</code> for strings, and by
-- <code>list</code> for lists.
-- @param a first sequence
-- @param b second sequence
-- @param s an empty sequence of the same type, to hold the result
-- @return the LCS of a and b
function longestCommonSubseq (a, b, s)
  local l, m, n = commonSubseqs (a, b)
  local i, j = 1, 1
  local f = getmetatable (s).__append
  while i <= m and j <= n do
    if a[i] == b[j] then
      s = f (s, a[i])
      i = i + 1
      j = j + 1
    elseif l[i + 1][j] >= l[i][j + 1] then
      i = i + 1
    else
      j = j + 1
    end
  end
  return s
end
