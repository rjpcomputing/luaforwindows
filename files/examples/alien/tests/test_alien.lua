
pcall(require, "luarocks.require")
require "alien"
require "alien.struct"

local dll = alien.alientest

do
  io.write(".")
  local f = dll._testfunc_i_bhilfd
  f:types("int", "byte", "short", "int", "long",  "float", "double")
  local result = f(string.byte("x"), 1, 3, 4, 5, 6)
  assert(result == 139)
end

do
  io.write(".")
  local f = dll._testfunc_i_bhilfd
  f:types{ ret = "int", "byte", "short", "int", "long",  "float", "double" }
  local result = f(string.byte("x"), 1, 3, 4, 5, 6)
  assert(result == 139)
end

do
  io.write(".")
  local f = dll._testfunc_i_bhilfd
  f:types{ "byte", "short", "int", "long",  "float", "double" }
  local result = f(string.byte("x"), 1, 3, 4, 5, 6)
  assert(result == 139)
end

do
  io.write(".")
  local f = dll._testfunc_p_p
  f:types("pointer", "ref int")
  local result, copy = f(42)
  assert(type(result) == "userdata")
  assert(copy == 42)
end

do
  io.write(".")
  local f = dll._testfunc_callback_i_if
  f:types("int", "int", "callback")
  local args = {}
  local expected = {262144, 131072, 65536, 32768, 16384, 8192, 4096, 2048,
                    1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1}
  local function callback(v)
    table.insert(args, v)
  end
  local cb = alien.callback(callback, "int", "int")
  f(2 ^ 18, cb)
  assert(#args == #expected)
  for i, v in ipairs(args) do assert(args[i] == expected[i]) end
end

do
  io.write(".")
  local f = dll._testfunc_callback_i_if
  f:types("int", "int", "callback")
  local function callback(value)
    return value
  end
  local cb = alien.callback(callback, "int", "int")
  local cb2 = alien.callback(callback, { ret = "int", "int" })
  local cb3 = alien.callback(callback, { "int" })
  local result = f(-10, cb)
  assert(result == -18)
  local result = f(-10, cb2)
  assert(result == -18)
  local result = f(-10, cb3)
  assert(result == -18)
end

do
  io.write(".")
  local integrate = dll.integrate
  integrate:types("double", "double", "double", "callback", "long")
  local function func(x)
    return x ^ 2
  end
  local result = integrate(0, 1, alien.callback(func, "double", "double"), 10)
  local diff = math.abs(result - 1/3)
  assert(diff < 0.01)
end

do
  io.write(".")
  dll.tf_b:types("byte", "byte")
  assert(dll.tf_b(-126) == -42)
end

do
  io.write(".")
  dll.tf_bb:types("byte", "byte", "byte")
  assert(dll.tf_bb(0, -126) == -42)
end

do
  io.write(".")
  dll.tf_B:types("char", "char")
  assert(dll.tf_B(255) == 85)
end

do
  io.write(".")
  dll.tf_bB:types("char", "byte", "char")
  assert(dll.tf_bB(0, 255) == 85)
end

do
  io.write(".")
  dll.tf_h:types("short", "short")
  assert(dll.tf_h(-32766) == -10922)
end

do
  io.write(".")
  dll.tf_bh:types("short", "byte", "short")
  assert(dll.tf_bh(0, -32766) == -10922)
end

do
  io.write(".")
  dll.tf_i:types("int", "int")
  assert(dll.tf_i(-2147483646) ==  -715827882)
end

do
  io.write(".")
  dll.tf_bi:types("int", "byte", "int")
  assert(dll.tf_bi(0, -2147483646) ==  -715827882)
end

do
  io.write(".")
  dll.tf_l:types("long", "long")
  assert(dll.tf_l(-2147483646) ==  -715827882)
end

do
  io.write(".")
  dll.tf_bl:types("long", "byte", "long")
  assert(dll.tf_bl(0, -2147483646) ==  -715827882)
end

do
  io.write(".")
  dll.tf_f:types("float", "float")
  assert(dll.tf_f(-42) == -14)
end

do
  io.write(".")
  dll.tf_bf:types("float", "byte", "float")
  assert(dll.tf_bf(0, -42) == -14)
end

do
  io.write(".")
  dll.tf_d:types("double", "double")
  assert(dll.tf_d(-42) == -14)
end

do
  io.write(".")
  dll.tf_bd:types("double", "byte", "double")
  assert(dll.tf_bd(0, -42) == -14)
end

do
  io.write(".")
  dll.tv_i:types("void", "int")
  assert(dll.tv_i(42) == nil)
  assert(dll.tv_i(-42) == nil)
end

do
  io.write(".")
  local strchr = dll.my_strchr
  strchr:types("pointer", "string", "char")
  assert(alien.tostring(strchr("abcdefghi", string.byte("b"))) == "bcdefghi") 
  assert(strchr("abcdefghi", string.byte("x")) == nil)
end

do
  io.write(".")
  local strtok = dll.my_strtok
  strtok:types("pointer", "string", "string")
  local buf = alien.buffer("a\nb\nc")
  local lb = "\n"
  assert(alien.tostring((strtok(buf, lb))) == "a")
  assert(alien.tostring((strtok(nil, lb))) == "b")
  assert(alien.tostring((strtok(nil, lb))) == "c")
  assert(alien.tostring((strtok(nil, lb))) == nil)
end

do
  io.write(".")
  local f = dll._testfunc_v
  f:types("void", "int", "int", "ref int")
  local r1, r2 = f(1, 2, 0)
  assert(r1 == nil)
  assert(r2 == 3)
end

do
  io.write(".")
  local f = dll._testfunc_i_bhilfd
  f:types("int", "byte", "short", "int", "long", "float", "double")
  local result = f(1, 2, 3, 4, 5, 6)
  assert(result == 21)
  local result = f(-1, -2, -3, -4, -5, -6)
  assert(result == -21)
  f:types("short", "byte", "short", "int", "long", "float", "double")
  local result = f(1, 2, 3, 4, 5, 6)
  assert(result == 21)
  local result = f(1, 2, 3, 0x10004, 5.0, 6.0)
  assert(result == 21)
end

do
  io.write(".")
  local f = dll._testfunc_f_bhilfd
  f:types("float", "byte", "short", "int", "long", "float", "double")
  local result = f(1, 2, 3, 4, 5.0, 6.0)
  assert(result == 21)
  local result = f(-1, -2, -3, -4, -5, -6)
  assert(result == -21)
end

do
  io.write(".")
  local f = dll._testfunc_d_bhilfd
  f:types("double", "byte", "short", "int", "long", "float", "double")
  local result = f(1, 2, 3, 4, 5.0, 6.0)
  assert(result == 21)
  local result = f(-1, -2, -3, -4, -5, -6)
  assert(result == -21)
end

do
  io.write(".")
  local f = dll._testfunc_p_p
  f:types("pointer", "string")
  local result = f("123")
  assert(alien.tostring(result) == "123")
  local result = f(nil)
  assert(result == nil)
end

do
  io.write(".")
  local f = dll.my_sqrt
  f:types("double", "double")
  assert(f(4) == 2)
  assert(f(2) == math.sqrt(2))
end

do
  io.write(".")
  local function sort(a, b)
    return a - b
  end
  local compare = alien.callback(sort, "int", "ref char", "ref char")
  local qsort = dll.my_qsort
  qsort:types("void", "pointer", "int", "int", "callback")
  local chars = alien.buffer("spam, spam, and spam")
  qsort(chars, chars:len(), alien.sizeof("char"), compare)
  assert(chars:tostring() == "   ,,aaaadmmmnpppsss")
end

do
  io.write(".")
  local compare = dll.my_compare
  compare:types("int", "ref char", "ref char")
  local qsort = dll.my_qsort
  qsort:types("void", "pointer", "int", "int", "callback")
  local chars = alien.buffer("spam, spam, and spam")
  qsort(chars, chars:len(), alien.sizeof("char"), compare)
  assert(chars:tostring() == "   ,,aaaadmmmnpppsss")
end

do
  io.write(".")
  local funcs = alien.buffer(2 * alien.sizeof("callback"))
  local res = {}
  local function callback(a, b)
    table.insert(res, a + b)
  end
  local cb1 = alien.callback(callback, { "int", "int" })
  local cb2 = alien.callback(callback, { abi = "stdcall", "int", "int" })
  funcs:set(1, cb1, "callback")
  funcs:set(1 + alien.sizeof("callback"), cb2, "callback")
  local f = dll._testfunc_callfuncp
  f:types("int", "pointer")
  f(funcs)
  assert(#res == 2)
  assert(res[1] == 3)
  assert(res[2] == 7)
end

do
  io.write(".")
  local tag1 = alien.tag("alientest_tag1")
  assert(type(tag1) == "table")
  local tag2 = alien.tag("alientest_tag1")
  assert(tag1 == tag2)
  local tag3 = alien.tag("alientest_tag3")
  assert(tag1 ~= tag3)
  assert(type(tag3) == "table")
end

dll.my_malloc:types("pointer", "int")
dll.my_free:types("void", "pointer")

do
  io.write(".")
  local tag = alien.tag("alientest_tag")
  local ptr = dll.my_malloc(4)
  local obj = alien.wrap("alientest_tag", 1, 2, ptr, 10)
  assert(getmetatable(obj) == tag)
  local x, y, o, z = alien.unwrap("alientest_tag", obj)
  assert(x == 1 and y == 2 and o == ptr and z == 10)
  alien.rewrap("alientest_tag", obj, 3, 4, nil, 5)
  local x, y, o, z = alien.unwrap("alientest_tag", obj)
  assert(x == 3 and y == 4 and o == nil and z == 5)
  dll.my_free(ptr)
end

local types = { "char", "short", "int", "long" }

for _, t in ipairs(types) do
  local buf = alien.buffer(alien.sizeof(t))
  local ptr = buf:topointer()
  buf:set(1, 5, t)
  assert(alien["to" .. t](ptr) == 5)
end

local types = { "float", "double"}

for _, t in ipairs(types) do
  local buf = alien.buffer(alien.sizeof(t))
  local ptr = buf:topointer()
  buf:set(1, 2.5, t)
  assert(alien["to" .. t](ptr) == 2.5)
end

local types = { "char", "short", "int", "long" }

for _, t in ipairs(types) do
  local buf = alien.buffer(alien.sizeof(t) * 4)
  local ptr = buf:topointer()
  for i = 1, alien.sizeof(t) * 4, alien.sizeof(t) do
    buf:set(i, i * 2, t)
  end
  local vals = { alien["to" .. t](ptr, 4) }
  assert(#vals == 4)
  for i = 1, 4 do
    assert(vals[i] == (((i - 1) * alien.sizeof(t)) + 1) * 2)
  end
end

local types = { "float", "double"}

for _, t in ipairs(types) do
  local buf = alien.buffer(alien.sizeof(t) * 4)
  local ptr = buf:topointer()
  for i = 1, alien.sizeof(t) * 4, alien.sizeof(t) do
    buf:set(i, i * 2 + 0.5, t)
  end
  local vals = { alien["to" .. t](ptr, 4) }
  assert(#vals == 4)
  for i = 1, 4 do
    assert(vals[i] == (((i - 1) * alien.sizeof(t)) + 1) * 2 + 0.5)
  end
end

do
  io.write(".")
  local function callback(a, b)
    return a + b
  end
  local cb1 = alien.callback(callback, { "int", "int" })
  local cb2 = alien.callback(callback, { abi = "stdcall", "int", "int" })
  assert(cb1(2, 3) == 5)
  assert(cb2(3, 4) == 7)
  local f = dll._testfunc_p_p
  f:types("pointer", "callback")
  local cb3 = alien.funcptr(f(cb1))
  cb3:types{ "int", "int" }
  assert(cb3(2, 3) == 5)
end

do
  io.write(".")
  local function sort(a, b)
    return a - b
  end
  local compare = alien.callback(sort, "int", "ref char", "ref char")
  local qsort = dll.my_qsort
  qsort:types("void", "pointer", "int", "int", "callback")
  local str = "spam, spam, and spam"
  local chars = alien.array("char", #str, alien.buffer(str))
  qsort(chars.buffer, chars.length, chars.size, compare)
  assert(tostring(chars.buffer) == "   ,,aaaadmmmnpppsss")
end

local types = { "char", "int", "double" }

for _, t in ipairs(types) do
  local function sort(a, b)
    return a - b
  end
  local compare = alien.callback(sort, "int", "ref " .. t, "ref " .. t)
  local qsort = dll.my_qsort
  qsort:types("void", "pointer", "int", "int", "callback")
  local nums = alien.array(t, { 4, 5, 3, 2, 6, 1 })
  qsort(nums.buffer, nums.length, nums.size, compare)
  for i = 1, 6 do assert(nums[i] == i) end
end

do
  io.write(".")
  local function sort(a, b)
     a = alien.buffer(a):get(1, "string")
     b = alien.buffer(b):get(1, "string")
     if a == b then return 0 elseif a < b then return -1 else return 1 end
  end
  local compare = alien.callback(sort, "int", "pointer", "pointer")
  local qsort = dll.my_qsort
  qsort:types("void", "pointer", "int", "int", "callback")
  local strs = alien.array("string", { "Red", "Yellow", "Blue" })
  qsort(strs.buffer, strs.length, strs.size, compare)
  assert(strs[1] == "Blue")
  assert(strs[2] == "Red")
  assert(strs[3] == "Yellow")
end

local types = { "char", "short", "int", "long", "float", "double" }

for _, t in ipairs(types) do
   local arr = alien.array(t, 4)
   assert(arr.length == 4)
   assert(arr.size == alien.sizeof(t))
   assert(arr.type == t)
   for i = 1, arr.length do
      arr[i] = i
   end
   for i = 1, arr.length do
      assert(arr[i] == i)
   end
   local tab = {}
   for i, v in arr:ipairs() do
      tab[i] = v
   end
   assert(#tab == 4)
   for i = 1, 4 do
      assert(tab[i] == i)
   end
   assert(not pcall(function () return arr[0] end))
   assert(not pcall(function () return arr[5] end))
end

do
  io.write(".")
  local rect = alien.defstruct{
    { "left", "long" },
    { "top", "long" },
    { "right", "long" },
    { "bottom", "long" }
  }
  local rect1 = rect:new()
  local getrect = dll.GetRectangle1
  getrect:types("int", "int", "pointer")
  assert(getrect(1, rect1()))
  assert(rect1.left == 1)
  assert(rect1.top == 2)
  assert(rect1.right == 3)
  assert(rect1.bottom == 4)
end

do
  io.write(".")
  local rect = alien.defstruct{
    { "left", "short" },
    { "top", "long" },
    { "right", "short" },
    { "bottom", "long" }
  }
  local rect1 = rect:new()
  local getrect = dll.GetRectangle2
  getrect:types("int", "int", "pointer")
  assert(getrect(1, rect1()))
  assert(rect1.left == 1)
  assert(rect1.top == 2)
  assert(rect1.right == 3)
  assert(rect1.bottom == 4)
end

do
  io.write(".")
  local rect = alien.defstruct{
    { "left", "short" },
    { "top", "long" },
    { "right", "short" },
    { "bottom", "long" }
  }
  local rect1 = rect:new()
  rect1.left, rect1.top, rect1.right, rect1.bottom = 1, 2, 3, 4
  local getrect = dll.GetRectangle3
  getrect:types("int", "pointer")
  assert(getrect(rect1()))
  assert(rect1.left == 2)
  assert(rect1.top == 4)
  assert(rect1.right == 6)
  assert(rect1.bottom == 8)
end

do
  io.write(".")
  local rect = alien.defstruct{
    { "left", "short" },
    { "top", "long" },
    { "right", "short" },
    { "bottom", "long" }
  }
  --local rect1 = rect:new()
  --rect1.left, rect1.top, rect1.right, rect1.bottom = 1, 2, 3, 4
  --local getrect = dll.GetRectangle4
  --getrect:types("int", rect:byval())
  --assert(getrect(alien.byval(rect1())) == 10)
end

do
  io.write(".")
   local struct = alien.struct

   local buf = alien.buffer('123456')
   assert(alien.buffer(buf:topointer(3)):tostring(3,2)=='456')
   
   --buf:set(1,'123abc')
   --assert(alien.buffer(buf:topointer(3)):tostring(3,2)=='abc')

   local S = '>ipbph'
   local ba = alien.buffer('a\0')
   local bb = alien.buffer('b\0')
   local s = struct.pack(S,1,ba,2,bb,3)
   local buf = alien.buffer(s)
   local one,pba,two,pbb,three = struct.unpack(S,buf,struct.size(S))
   assert(one==1) assert(two==2) assert(three==3)
   assert(alien.buffer(pba):tostring()=='a')
   assert(alien.tostring(pbb)=='b')
   
   local pbb,three = struct.unpack('>ph',buf,struct.size(S),struct.offset(S,4))
   assert(alien.buffer(pbb):tostring()=='b')
   assert(three==3)

   --buf:set(struct.offset(S,4),struct.pack('p',ba))
   --assert(alien.buffer(struct.unpack('p',buf,struct.size(S),struct.offset(S,4))):tostring()=='a')

   assert(struct.size('p')==alien.sizeof("pointer"))
   assert(struct.offset(S,1)==1)
   assert(struct.offset(S,4)==6+alien.sizeof("pointer"))
   assert(struct.offset(S,alien.sizeof("pointer")+2)==struct.size(S)+1)
end

local maxushort = 2^(8*alien.sizeof("ushort"))-1
local maxuint = 2^(8*alien.sizeof("uint"))-1
local maxulong = 2^(8*alien.sizeof("ulong"))-1

do
  io.write(".")
   assert(alien.sizeof('ushort')==alien.sizeof('short'))
   assert(alien.sizeof('uint')==alien.sizeof('int'))
   assert(alien.sizeof('ulong')==alien.sizeof('long'))
   local buf = alien.buffer(alien.sizeof('ulong'))
   buf:set(1,maxushort,'ushort')
   assert(buf:get(1,'short')==-1)
   assert(buf:get(1,'ushort')==maxushort)
   assert(alien.toushort(buf:topointer())==maxushort)
   buf:set(1,maxuint,'uint')
   assert(buf:get(1,'int')==-1)
   assert(buf:get(1,'uint')==maxuint)
   assert(alien.touint(buf:topointer())==maxuint)
   if alien.sizeof("long") < 8 then
     buf:set(1,maxulong,'ulong')
     assert(buf:get(1,'long')==-1)
     assert(buf:get(1,'ulong')==maxulong)
     assert(alien.toulong(buf:topointer())==maxulong)
   end
end

do
  io.write(".")
  assert(alien.sizeof('ushort')==alien.sizeof('short'))
  assert(alien.sizeof('uint')==alien.sizeof('int'))
  assert(alien.sizeof('ulong')==alien.sizeof('long'))
  local f = dll._testfunc_L_HIL
  f:types("ulong", "ushort", "uint", "ulong")
  assert(f(maxushort,0,0)==maxushort)
  assert(f(0,maxuint,0)==maxuint)
  if alien.sizeof("long") < 8 then assert(f(0,0,maxulong)==maxulong) end
end

print()
