#!/usr/local/bin/lua50

-- Testing MD5

require"md5"


assert(md5.exor('', '') == '')
assert(md5.exor('alo alo', '\0\0\0\0\0\0\0') == 'alo alo')

local function invert (s)
  return md5.exor(s, string.rep('\255', string.len(s)))
end

x = string.rep('0123456789', 1000)
assert(md5.exor(x,x) == string.rep('\0', 10000))
assert(md5.exor(x,invert(x)) == string.rep('\255', 10000))

assert(invert(invert('alo alo')) == 'alo alo')

assert(invert(invert(invert('alo\0\255alo'))) == invert('alo\0\255alo'))

-- test some known sums
assert(md5.sumhexa("") == "d41d8cd98f00b204e9800998ecf8427e")
assert(md5.sumhexa("a") == "0cc175b9c0f1b6a831c399e269772661")
assert(md5.sumhexa("abc") == "900150983cd24fb0d6963f7d28e17f72")
assert(md5.sumhexa("message digest") == "f96b697d7cb7938d525a2f31aaf161d0")
assert(md5.sumhexa("abcdefghijklmnopqrstuvwxyz") == "c3fcd3d76192e4007dfb496cca67e13b")
assert(md5.sumhexa("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
 == "d174ab98d277d9f5a5611c2c9f419d9f")


-- test padding borders
assert(md5.sumhexa(string.rep('a',53)) == "e9e7e260dce84ffa6e0e7eb5fd9d37fc")
assert(md5.sumhexa(string.rep('a',54)) == "eced9e0b81ef2bba605cbc5e2e76a1d0")
assert(md5.sumhexa(string.rep('a',55)) == "ef1772b6dff9a122358552954ad0df65")
assert(md5.sumhexa(string.rep('a',56)) == "3b0c8ac703f828b04c6c197006d17218")
assert(md5.sumhexa(string.rep('a',57)) == "652b906d60af96844ebd21b674f35e93")
assert(md5.sumhexa(string.rep('a',63)) == "b06521f39153d618550606be297466d5")
assert(md5.sumhexa(string.rep('a',64)) == "014842d480b571495a4a0363793f7367")
assert(md5.sumhexa(string.rep('a',65)) == "c743a45e0d2e6a95cb859adae0248435")
assert(md5.sumhexa(string.rep('a',255)) == "46bc249a5a8fc5d622cf12c42c463ae0")
assert(md5.sumhexa(string.rep('a',256)) == "81109eec5aa1a284fb5327b10e9c16b9")

assert(md5.sumhexa(
"12345678901234567890123456789012345678901234567890123456789012345678901234567890")
   == "57edf4a22be3c955ac49da2e2107b67a")

print '+'



local tolerance = 1.12

local function contchars (s)
  local a = {}
  for i=0,255 do a[string.char(i)] = 0 end
  for c in string.gfind(s, '.') do
    a[c] = a[c] + 1
  end
  local av = string.len(s)/256
  for i=0,255 do
    local c = string.char(i)
    assert(a[c] < av*tolerance and a[c] > av/tolerance, i)
  end
end


local key = 'xuxu bacana'
assert(md5.decrypt(md5.crypt('', key), key) == '')
assert(md5.decrypt(md5.crypt('', key, '\0\0seed\0'), key) == '')
assert(md5.decrypt(md5.crypt('a', key), key) == 'a')
local msg = string.rep("1233456789\0\1\2\3\0\255", 10000)
local code = md5.crypt(msg, key, "seed")
assert(md5.decrypt(code, key) == msg)
contchars(code)

assert(md5.crypt('a', 'a') ~= md5.crypt('a', 'b'))

print"MD5 OK"


-- Testing DES 56
require 'des56'

local key = '&3g4&gs*&3'

assert(des56.decrypt(des56.crypt('', key), key) == '')
assert(des56.decrypt(des56.crypt('', key), key) == '')
assert(des56.decrypt(des56.crypt('a', key), key) == 'a')
assert(des56.decrypt(des56.crypt('1234567890', key), key) == '1234567890')

local msg = string.rep("1233456789\0\1\2\3\0\255", 10000)
local code = des56.crypt(msg, key)

assert(des56.decrypt(code, key) == msg)
assert(des56.crypt('a', '12345678') ~= des56.crypt('a', '87654321'))

local ascii = ""

for i = 0, 255 do
	ascii = ascii..string.char(i)
end

assert(des56.decrypt(des56.crypt(ascii, key), key) == ascii)
key = string.sub(ascii, 2)
assert(des56.decrypt(des56.crypt(ascii, key), key) == ascii)

print"DES56 OK"