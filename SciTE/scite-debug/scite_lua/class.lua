-- class.lua
function class(base,ctor)
  local c = {}     -- a new class instance
  if not ctor and type(base) == 'function' then
	  ctor = base
	  base = nil
  elseif type(base) == 'table' then
   -- our new class is a shallow copy of the base class!
	  for i,v in pairs(base) do
		  c[i] = v
	  end
	  c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c

  -- expose a ctor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl,...)
	local obj = {}
	setmetatable(obj,c)
	if ctor then
	   ctor(obj,unpack(arg))
	else 
	-- make sure that any stuff from the base class is initialized!
	   if base and base.init then
		 base.init(obj,unpack(arg))
	   end
	end
	return obj
  end
  c.init = ctor
  c.is_a = function(self,klass)
	  local m = getmetatable(self)
	  while m do 
		 if m == klass then return true end
		 m = m._base
	  end
	  return false
	end
  setmetatable(c,mt)
  return c
end

List = {}
List.__index = List
List.__call = function()
	return create_list()
end

function create_list()
	res = {}
	setmetatable(res,List)
	return res
end

function List:append(obj)
	table.insert(self,obj)
end

--- some aliases for append
List.add = List.append
List.push = List.append

function List:index(obj)
	for i,m in ipairs(self) do
		if m == obj then			
			return i
		end
	end
end

function List:remove(obj)
	local idx =  self:index(obj)
	if idx then
		table.remove(self,idx)
		return true
	end
end

function List:iter()
    local i = 0
    local n = table.getn(self)
    return function ()
               i = i + 1
               if i <= n then return self[i] end
             end
end

function List:apply(func)
	for i,m in pairs(self) do
		func(m)
	end
end

function List:length()
	return table.getn(self)
end

-- stack-like interface
function List:pop()
	return table.remove(self)
end

-- queue-like interface
function List:get()
	return table.remove(self,1)
end
