local assert, pairs, type, tostring, setmetatable = assert, pairs, type, tostring, setmetatable
local baseMt, _instances, _classes, _class = {}, setmetatable({},{__mode='k'}), setmetatable({},{__mode='k'})
local function assert_class(class, method) assert(_classes[class], ('Wrong method call. Expected class:%s.'):format(method)) end
local function deep_copy(t, dest, aType) t = t or {}; local r = dest or {}
  for k,v in pairs(t) do
    if aType and type(v)==aType then r[k] = v elseif not aType then
      if type(v) == 'table' and k ~= "__index" then r[k] = deep_copy(v) else r[k] = v end
    end
  end; return r
end
local function instantiate(self,...)
  assert_class(self, 'new(...) or class(...)'); local instance = {class = self}; _instances[instance] = tostring(instance); setmetatable(instance,self)
  if self.init then if type(self.init) == 'table' then deep_copy(self.init, instance) else self.init(instance, ...) end; end; return instance
end
local function extend(self, name, extra_params)
  assert_class(self, 'extend(...)'); local heir = {}; _classes[heir] = tostring(heir); deep_copy(extra_params, deep_copy(self, heir));
  heir.name, heir.__index, heir.super = extra_params and extra_params.name or name, heir, self; return setmetatable(heir,self)
end
baseMt = { __call = function (self,...) return self:new(...) end, __tostring = function(self,...)
  if _instances[self] then return ("instance of '%s' (%s)"):format(rawget(self.class,'name') or '?', _instances[self]) end
  return _classes[self] and ("class '%s' (%s)"):format(rawget(self,'name') or '?',_classes[self]) or self
end}; _classes[baseMt] = tostring(baseMt); setmetatable(baseMt, {__tostring = baseMt.__tostring})
local class = {isClass = function(class, ofsuper) local isclass = not not _classes[class]; if ofsuper then return isclass and (class.super == ofsuper) end; return isclass end, isInstance = function(instance, ofclass) 
	local isinstance = not not _instances[instance]; if ofclass then return isinstance and (instance.class == ofclass) end; return isinstance end}; _class = function(name, attr)
  local c = deep_copy(attr); c.mixins=setmetatable({},{__mode='k'}); _classes[c] = tostring(c); c.name, c.__tostring, c.__call = name or c.name, baseMt.__tostring, baseMt.__call
  c.include = function(self,mixin) assert_class(self, 'include(mixin)'); self.mixins[mixin] = true; return deep_copy(mixin, self, 'function') end
  c.new, c.extend, c.__index, c.includes = instantiate, extend, c, function(self,mixin) assert_class(self,'includes(mixin)') return not not (self.mixins[mixin] or (self.super and self.super:includes(mixin))) end
  c.extends = function(self, class) assert_class(self, 'extends(class)') local super = self; repeat super = super.super until (super == class or super == nil); return class and (super == class) end
	return setmetatable(c, baseMt) end; class._DESCRIPTION = '30 lines library for object orientation in Lua'; class._VERSION = '30log v1.0.0'; class._URL = 'http://github.com/Yonaba/30log'; class._LICENSE = 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>'
return setmetatable(class,{__call = function(_,...) return _class(...) end })