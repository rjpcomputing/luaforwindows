------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net
module( 'lemock', package.seeall )
_VERSION   = "LeMock 0.6"
_COPYRIGHT = "Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>"
local class, object, qtostring, sfmt, add_to_set
local elements_of_set, value_equal
function object (class)
	return setmetatable( {}, class )
end
function class (parent)
	local c = object(parent)
	c.__index = c
	return c
end
sfmt = string.format
function qtostring (v)
	if type(v) == 'string' then
		return sfmt( '%q', v )
	else
		return tostring( v )
	end
end
function add_to_set (o, setname, element)
	if not o[setname] then
		o[setname] = {}
	end
	local l = o[setname]
	for i = 1, #l do
		if l[i] == element then return end
	end
	l[#l+1] = element
end
function elements_of_set (o, setname)
	local l = o[setname]
	local i = l and #l+1 or 0
	return function ()
		i = i - 1
		if i > 0 then return l[i] end
	end
end
function value_equal (a, b)
	if a == b then return true end
	if a ~= a and b ~= b then return true end -- NaN == NaN
	return false
end
local mock_controller_map = setmetatable( {}, {__mode='k'} )
-- All the classes are private
local Action, Argv, Callable, Controller, Mock
Action = {}
-- abstract
Action.generic = class()
function Action.generic:add_close (label)
	add_to_set( self, 'closelist', label )
end
function Action.generic:add_depend (d)
	add_to_set( self, 'dependlist', d )
end
function Action.generic:add_label (label)
	add_to_set( self, 'labellist', label )
end
function Action.generic:assert_satisfied ()
	assert( self.replay_count <= self.max_replays, "lemock internal error" )
	if not (
self.min_replays <= self.replay_count
                                  ) then
		error( sfmt( "Wrong replay count %d (expected %d..%d) for %s"
		             , self.replay_count
		             , self.min_replays, self.max_replays
		             , self:tostring()
		       )
		       , 0
		)
	end
end
function Action.generic:blocks ()
	if self:is_satisfied() then
		return function () end
	end
	return elements_of_set( self, 'labellist' )
end
function Action.generic:closes ()
	return elements_of_set( self, 'closelist' )
end
function Action.generic:depends ()
	return elements_of_set( self, 'dependlist' )
end
function Action.generic:has_label (l)
	for x in elements_of_set( self, 'labellist' ) do
		if x == l then return true end
	end
	return false
end
function Action.generic:is_expected ()
	return self.replay_count < self.max_replays
	   and not self.is_blocked
	   and not self.is_closed
end
function Action.generic:is_satisfied ()
	return 
self.min_replays <= self.replay_count
end
function Action.generic:match (key)
	if getmetatable(self) ~= getmetatable(key)  then return false end
	if self.mock ~= key.mock                    then return false end
	return self:is_expected()
end
function Action.generic:new (mock)
	local a = object( self )
	a.mock         = mock
	a.replay_count = 0
	a.min_replays  = 1
	a.max_replays  = 1
	return a
end
function Action.generic:set_times (a, b)
	min = a or 1
	max = b or min
	min, max = tonumber(min), tonumber(max)
	if (not min) or (not max) or (min >= math.huge)
	             or (min ~= min) or (max ~= max) -- NaN
	             or (min < 0) or (max <= 0) or (min > max) then
		error( sfmt( "Unrealistic time arguments (%s, %s)"
		           , qtostring( min )
		           , qtostring( max )
		           )
		     , 0
		     )
	end
	self.min_replays = min
	self.max_replays = max
end
Action.generic_call = class( Action.generic )
Action.generic_call.can_return = true
function Action.generic_call:get_returnvalue ()
	if self.has_returnvalue then
		return self.returnvalue:unpack()
	end
end
function Action.generic_call:set_returnvalue (...)
	self.returnvalue = Argv:new(...)
	self.has_returnvalue = true
end
function Action.generic_call:match (q)
	if not Action.generic.match( self, q )  then return false end
	if not self.argv:equal( q.argv )        then return false end
	return true
end
function Action.generic_call:new (m, ...)
	local a = Action.generic.new( self, m )
	a.argv   = Argv:new(...)
	return a
end
-- concrete
Action.call = class( Action.generic_call )
function Action.call:match (q)
	if not Action.generic_call.match( self, q )  then return false end
	if self.key ~= q.key                         then return false end
	return true
end
function Action.call:new (m, key, ...)
	local a = Action.generic_call.new( self, m, ... )
	a.key = key
	return a
end
function Action.call:tostring ()
	if self.has_returnvalue then
		return sfmt( "call %s(%s) => %s"
		             , tostring(self.key)
		             , self.argv:tostring()
		             , self.returnvalue:tostring()
		       )
	else
		return sfmt( "call %s(%s)"
		             , tostring(self.key)
		             , self.argv:tostring()
		       )
	end
end
Action.index = class( Action.generic )
Action.index.can_return = true
function Action.index:get_returnvalue ()
	return self.returnvalue
end
function Action.index:set_returnvalue (v)
	self.returnvalue = v
	self.has_returnvalue = true
end
function Action.index:match (q)
	if not Action.generic.match( self, q )  then return false end
	if self.key ~= q.key                    then return false end
	return true
end
function Action.index:new (m, key)
	local a = Action.generic.new( self, m )
	a.key = key
	return a
end
function Action.index:tostring ()
	local key = 'index '..tostring( self.key )
	if self.has_returnvalue then
		return sfmt( "index %s => %s"
		             , tostring( self.key )
		             , qtostring( self.returnvalue )
		       )
	elseif self.is_callable then
		return sfmt( "index %s()"
		             , tostring( self.key )
		       )
	else
		return sfmt( "index %s"
		             , tostring( self.key )
		       )
	end
end
Action.newindex = class( Action.generic )
function Action.newindex:match (q)
	if not Action.generic.match( self, q )  then return false end
	if self.key ~= q.key                    then return false end
	if not value_equal( self.val, q.val )
	   and self.val ~= Argv.ANYARG
	   and q.val    ~= Argv.ANYARG          then return false end
	return true
end
function Action.newindex:new (m, key, val)
	local a = Action.generic.new( self, m )
	a.key    = key
	a.val    = val
	return a
end
function Action.newindex:tostring ()
	return sfmt( "newindex %s = %s"
	             , tostring(self.key)
	             , qtostring(self.val)
	       )
end
Action.selfcall = class( Action.generic_call )
function Action.selfcall:match (q)
	return Action.generic_call.match( self, q )
end
function Action.selfcall:new (m, ...)
	local a = Action.generic_call.new( self, m, ... )
	return a
end
function Action.selfcall:tostring ()
	if self.has_returnvalue then
		return sfmt( "selfcall (%s) => %s"
		             , self.argv:tostring()
		             , self.returnvalue:tostring()
		       )
	else
		return sfmt( "selfcall (%s)"
		             , self.argv:tostring()
		       )
	end
end
Argv = class()
Argv.ANYARGS = newproxy()  local ANYARGS = Argv.ANYARGS
Argv.ANYARG  = newproxy()  local ANYARG  = Argv.ANYARG
function Argv:equal (other)
	local a1, n1 = self.v,  self.len
	local a2, n2 = other.v, other.len
	if n1-1 <= n2 and a1[n1] == ANYARGS then
		n1 = n1-1
		n2 = n1
	elseif n2-1 <= n1 and a2[n2] == ANYARGS then
		n2 = n2-1
		n1 = n2
	end
	if n1 ~= n2 then
		return false
	end
	for i = 1, n1 do
		local v1, v2 = a1[i], a2[i]
		if not value_equal(v1,v2) and v1 ~= ANYARG and v2 ~= ANYARG then
			return false
		end
	end
	return true
end
function Argv:new (...)
	local av = object( self )
	av.v = {...}
	av.len = select('#',...)
	for i = 1, av.len - 1 do
		if av.v[i] == Argv.ANYARGS then
			error( "ANYARGS not at end.", 0 )
		end
	end
	return av
end
function Argv:tostring ()
	local res = {}
	local function w (v)
		res[#res+1] = qtostring( v )
	end
	local av, ac = self.v, self.len
	for i = 1, ac do
		if av[i] == Argv.ANYARG then
			res[#res+1] = 'ANYARG'
		elseif av[i] == Argv.ANYARGS then
			res[#res+1] = 'ANYARGS'
		else
			w( av[i] )
		end
		if i < ac then
			res[#res+1] = ',' -- can not use qtostring in w()
		end
	end
	return table.concat( res )
end
function Argv:unpack ()
	return unpack( self.v, 1, self.len )
end
Callable = {}
Callable.generic = class()
Callable.record  = class( Callable.generic )
Callable.replay  = class( Callable.generic )
function Callable.generic:new ( index_action )
	local f = object( self )
	f.action = index_action
	return f
end
function Callable.record:__call (...)
	local index_action = self.action
	local m = index_action.mock
	local mc = mock_controller_map[m]
	assert( mc.is_recording, "client uses cached callable from recording" )
	mc:make_callable( index_action )
	mc:add_action( Action.call:new( m, index_action.key, ... ))
end
function Callable.replay:__call (...)
	local index_action = self.action
	local m = index_action.mock
	local mc = mock_controller_map[m]
	local call_action = mc:lookup( Action.call:new( m, index_action.key, ... ))
	mc:replay_action( call_action )
	if call_action.throws_error then
		error( call_action.errorvalue, 2 )
	end
	return call_action:get_returnvalue()
end
Controller = class()
-- Exported methods
function Controller:close (...)
	if not self.is_recording then
		error( "Can not insert close in replay mode.", 2 )
	end
	local action = self:get_last_action()
	for _, close in ipairs{ ... } do
		action:add_close( close )
	end
	return self -- for chaining
end
function Controller:depend (...)
	if not self.is_recording then
		error( "Can not add dependency in replay mode.", 2 )
	end
	local action = self:get_last_action()
	for _, dependency in ipairs{ ... } do
		action:add_depend( dependency )
	end
	return self -- for chaining
end
function Controller:error (value)
	if not self.is_recording then
		error( "Error called during replay.", 2 )
	end
	local action = self:get_last_action()
	if action.has_returnvalue or action.throws_error then
		error( "Returns and/or Error called twice for same action.", 2 )
	end
	action.throws_error = true
	action.errorvalue = value
	return self -- for chaining
end
function Controller:label (...)
if not self.is_recording then
	error( "Can not add labels in replay mode.", 2 )
end
local action = self:get_last_action()
for _, label in ipairs{ ... } do
	action:add_label( label )
end
return self -- for chaining
end
function Controller:mock ()
	if not self.is_recording then
		error( "New mock during replay.", 2 )
	end
	local m = object( Mock.record )
	mock_controller_map[m] = self
	return m
end
function Controller:new ()
	local mc = object( self )
	mc.actionlist   = {}
	mc.is_recording = true
	return mc
end
function Controller:replay ()
	if not self.is_recording then
		error( "Replay called twice.", 2 )
	end
	self.is_recording = false
	for m, mc in pairs( mock_controller_map ) do
		if mc == self then
			setmetatable( m, Mock.replay )
		end
	end
	self:update_dependencies()
	self:assert_no_dependency_cycles()
end
function Controller:returns (...)
	if not self.is_recording then
		error( "Returns called during replay.", 2 )
	end
	local action = self:get_last_action()
	assert( not action.is_callable, "lemock internal error" )
	if not action.can_return then
		error( "Previous action can not return anything.", 2 )
	end
	if action.has_returnvalue or action.throws_error then
		error( "Returns and/or Error called twice for same action.", 2 )
	end
	action:set_returnvalue(...)
	return self -- for chaining
end
function Controller:times (min, max)
	if not self.is_recording then
		error( "Can not set times in replay mode.", 0 )
	end
	self:get_last_action():set_times( min, max )
	return self -- for chaining
end
-- convenience functions
function Controller:anytimes()    return self:times( 0, math.huge ) end
function Controller:atleastonce() return self:times( 1, math.huge ) end
function Controller:verify ()
	if self.is_recording then
		error( "Verify called during record.", 2 )
	end
	for a in self:actions() do
		a:assert_satisfied()
	end
end
-- Protected methods
function Controller:actions (q)
	local l = self.actionlist
	local i = 0
	return function ()
		i = i + 1
		return l[i]
	end				
end
function Controller:add_action (a)
	assert( a ~= nil, "lemock internal error" ) -- breaks array property
	table.insert( self.actionlist, a )
end
function Controller:assert_no_dependency_cycles ()
	local function is_in_path (label, path)
		if not path then return false end -- is root
		for _, l in ipairs( path ) do
			if l == label then return true end
		end
		if path.prev then return is_in_path( label, path.prev ) end
		return false
	end
	local function can_block (action, node)
		for _, label in ipairs( node ) do
			if action:has_label( label ) then return true end
		end
		return false
	end
	local function step (action, path)
		local new_head
		for label in action:depends() do
			if is_in_path( label, path ) then
				error( "Detected dependency cycle", 0 )
			end
			-- only create table if needed to reduce garbage
			if not new_head then new_head = { prev=path } end
			new_head[#new_head+1] = label
		end
		return new_head
	end
	local function search_depth_first (path)
		for action in self:actions() do
			if can_block( action, path ) then
				local new_head = step( action, path )
				if new_head then
					search_depth_first( new_head )
				end
			end
		end
	end
	for action in self:actions() do
		local root = step( action, nil )
		if root then search_depth_first( root ) end
	end
end
function Controller:close_actions( ... ) -- takes iterator
	for label in ... do
		for candidate in self:actions() do
			if candidate:has_label( label ) then
				if not candidate:is_satisfied() then
					error( "Closes unsatisfied action: "..candidate:tostring(), 0 )
				end
				candidate.is_closed = true
			end
		end
	end
end
function Controller:get_last_action ()
	local l = self.actionlist
	if #l == 0 then
		error( "No action is recorded yet.", 0 )
	end
	return l[#l]
end
function Controller:lookup (actual)
	for action in self:actions() do
		if action:match( actual ) then
			return action
		end
	end
local expected = {}
for _, a in ipairs( self.actionlist ) do
	if a:is_expected() and not a.is_callable then
		expected[#expected+1] = a:tostring()
	end
end
table.sort( expected )
if #expected == 0 then
	expected[1] = "(Nothing)"
end
	error( sfmt( "Unexpected action %s, expected:\n%s\n"
	             , actual:tostring()
	             , table.concat(expected,'\n')
	       )
	       , 0
	)
end
function Controller:make_callable (action)
	if action.has_returnvalue then
		error( "Can not call "..action.key..". It has a returnvalue.", 0 )
	end
	action.is_callable = true
	action.min_replays = 0
	action.max_replays = math.huge
end
function Controller:new ()
	local mc = object( self )
	mc.actionlist   = {}
	mc.is_recording = true
	return mc
end
function Controller:replay_action ( action )
	assert( action:is_expected(), "lemock internal error" )
	assert( action.replay_count < action.max_replays, "lemock internal error" )
	local was_satisfied = action:is_satisfied()
	action.replay_count = action.replay_count + 1
	if not was_satisfied and action.labellist and action:is_satisfied() then
		self:update_dependencies()
	end
	if action.closelist then
		self:close_actions( action:closes() )
	end
end
function Controller:update_dependencies ()
	local blocked = {}
	for action in self:actions() do
		for label in action:blocks() do
			blocked[label] = true
		end
	end
	local function is_blocked (action)
		for label in action:depends() do
			if blocked[label] then return true end
		end
		return false
	end
	for action in self:actions() do
		action.is_blocked = is_blocked( action )
	end
end
Mock = { record={}, replay={} } -- no self-referencing __index!
function Mock.record:__index (key)
	local mc = mock_controller_map[self]
	local action = Action.index:new( self, key )
	mc:add_action( action )
	return Callable.record:new( action )
end
function Mock.record:__newindex (key, val)
	local mc = mock_controller_map[self]
	mc:add_action( Action.newindex:new( self, key, val ))
end
function Mock.record:__call (...)
	local mc = mock_controller_map[self]
	mc:add_action( Action.selfcall:new( self, ... ))
end
function Mock.replay:__index (key)
	local mc = mock_controller_map[self]
	local index_action = mc:lookup( Action.index:new( self, key ))
	mc:replay_action( index_action )
	if index_action.throws_error then
		error( index_action.errorvalue, 2 )
	end
	if index_action.is_callable then
		return Callable.replay:new( index_action )
	else
		return index_action:get_returnvalue()
	end
end
function Mock.replay:__newindex (key, val)
	local mc = mock_controller_map[self]
	local newindex_action = mc:lookup( Action.newindex:new( self, key, val ))
	mc:replay_action( newindex_action )
	if newindex_action.throws_error then
		error( newindex_action.errorvalue, 2 )
	end
end
function Mock.replay:__call (...)
	local mc = mock_controller_map[self]
	local selfcall_action = mc:lookup( Action.selfcall:new( self, ... ))
	mc:replay_action( selfcall_action )
	if selfcall_action.throws_error then
		error( selfcall_action.errorvalue, 2 )
	end
	return selfcall_action:get_returnvalue()
end
function controller ()
	local exported_methods = {
		'anytimes',
		'atleastonce',
		'close',
		'depend',
		'error',
		'label',
		'mock',
		'new',
		'replay',
		'returns',
		'times',
		'verify',
	}
	local mc = Controller:new()
	local wrapper = {}
	for _, method in ipairs( exported_methods ) do
		wrapper[ method ] = function (self, ...)
			return mc[ method ]( mc, ... )
		end
	end
	wrapper.ANYARG  = Argv.ANYARG
	wrapper.ANYARGS = Argv.ANYARGS
	return wrapper
end
return _M
