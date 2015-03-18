shared_meters = true

keep_ambiguous = true

require 'classlib'

function say(msg) print(msg and "> " .. msg or "") end

print [[
> class.meter()
> function meter:__init(value)
>	print("meter init " .. (value or 'nil'))
>	self.value = value or 0
> end
> function meter:set(value)
>	self.value = value
> end
> function meter:read()
> 	print("meter read " .. self.value)
> 	return self.value
> end
> function meter:which()
> 	print("meter = " .. tostring(self) ..  " { value = " .. self.value .. " }")
> end
> meter.value = -1
]]

class.meter()
function meter:__init(value)
	print("meter init " .. (value or 'nil'))
	self.value = value or 0
end
function meter:set(value)
	self.value = value
end
function meter:read()
	print("meter read " .. self.value)
	return self.value
end
function meter:which()
	print("meter = " .. tostring(self) ..  " { value = " .. self.value .. " }")
end
meter.value = -1

m = shared_meters and shared(meter) or meter
mm = shared_meters and "shared(meter)" or "meter"

say("class.hygro(" .. mm .. ")")

class.hygro(m)

print [[
> function hygro:read() 
> 	print("humidity " .. self.meter.value)
> end
]]

function hygro:read()
	print("humidity " .. self.meter.value)
end

say("class.therm(" .. mm .. ")")

class.therm(m)

print [[
> function therm:read()
> 	print("temperature " .. self.meter.value)
> end
]]

function therm:read()
	print("temperature " .. self.meter.value)
end

print [[
> class.hygrotherm(hygro, therm)
> function hygrotherm:read()
> 	self.hygro:read()
> 	self.therm:read()
> end
]]

class.hygrotherm(hygro, therm)
function hygrotherm:read()
	self.hygro:read()
	self.therm:read()
end

say('ht = hygrotherm(0)')
ht = hygrotherm(0)

say()
say("ht.therm:set(11)")

ht.therm:set(11)

say("ht.therm:read()")

ht.therm:read()

say()
say("ht.hygro:set(22)")

ht.hygro:set(22)

say("ht.hygro:read()")

ht.hygro:read()

say()
say("ht.therm:read()")

ht.therm:read()

say()
say("ht:read()")

ht:read()

say()
say("ht:which()")

status, msg = pcall(ht.which, ht)
if not status then print(msg) end

function show(t)
	if not t or not t.__type then print("Sorry, cannot show " .. tostring(t)) return end
	print('__type', t.__type)
	for i, v in pairs(t) do
		if type(i) ~= 'string' or i:sub(1, 2) ~= '__' then print(i, v) end
	end
end

print()
print("Class attributes:")
print()
print('meter:') show(meter)
print()
print('therm:') show(therm)
print()
print('hygro:') show(hygro)
print()
print('hygrotherm:') show(hygrotherm)
print()
print("ht is a meter = ", ht:is_a(meter))
print("ht is a therm = ", ht:is_a(therm))
print("ht is a hygro = ", ht:is_a(hygro))
print("ht is a hygrotherm = ", ht:is_a(hygrotherm))


print()
print("Object attributes:")
print()
print("ht:") show(ht)
print()
print("ht.hygro:") show(ht.hygro)
print()
print("ht.therm:") show(ht.therm)
print()
print("ht.hygro.meter:") show(ht.hygro.meter)
print()
print("ht.therm.meter:") show(ht.therm.meter)
print()
print("ht.meter:")

status, msg = pcall(show, ht.meter)
if not status then print(msg)end


