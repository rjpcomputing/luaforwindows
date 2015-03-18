require "oil"

orb = oil.init()
orb:loadidl[[
	typedef sequence<string> StringSequence;

	exception CompileError {
		string message;
		string code;
	};

	interface ComponentAdaptor {
		void apply_change(
			in StringSequence triggers,
			in string state_adaptation_code,
			in string code_adaptation_code,
			in string new_interface_def
		) raises (CompileError);
	};
]]
--------------------------------------------------------------------------------
local oo = require "oil.oo"

Adaptor = oo.class()

function Adaptor:__init(class)
	return oo.rawnew(self, { class = class })
end

function Adaptor:apply_change(triggers, state, code, iface)
	local adaptor, errmsg = loadstring("return function(self)\n"..state.."\nend")
	if not adaptor then
		oil.assert.exception{ "IDL:CompileError:1.0",
			message = errmsg,
			code = "function(self)\n"..state.."\nend",
		}
	end
	adaptor = adaptor()

	local original = _G[self.class]
	local adapted = oo.class({}, original)
	_G[self.class] = adapted
	for _, name in ipairs(triggers) do
		local operation = name
		local function trigger(object, ...)
			adaptor(object) -- update object state
			oo.rawnew(adapted, object) -- update object class
			return object[operation](object, unpack(arg))
		end
		original[operation] = trigger
	end

	orb:loadidl(iface)
	
	local updater, errmsg = loadstring(code)
	if not updater then
		oil.assert.exception{ "IDL:CompileError:1.0",
			message = errmsg,
			code = code,
		}
	end
	updater()
end
