-- floating point module
-- Copyright © 2008 Peter "Corsix" Cawley and Ben "ToxicFrog" Kelly; see COPYING

local fp = {}
local name = (...):gsub('%.[^%.]+$', '')
local struct = require (name)
local common = require (name..".common")

local function reader(data, size_exp, size_fraction)
	local fraction, exponent, sign
	local endian = common.is_bigendian and ">" or "<"
	
	-- Split the unsigned integer into the 3 IEEE fields
	local bits = struct.unpack(endian.."m"..#data, data, true)
	local fraction = struct.implode({unpack(bits, 1, size_fraction)}, size_fraction)
	local exponent = struct.implode({unpack(bits, size_fraction+1, size_fraction+size_exp)}, size_exp)
	local sign = bits[#bits] and -1 or 1
    
	-- special case: exponent is all 1s
	if exponent == 2^size_exp-1 then
		-- significand is 0? +- infinity
		if fraction == 0 then
			return sign * math.huge
		
		-- otherwise it's NaN
		else
			return 0/0
		end
	end
			
	-- restore the MSB of the significand, unless it's a subnormal number
	if exponent ~= 0 then
		fraction = fraction + (2 ^ size_fraction)
	else
        exponent = 1
    end
	
	-- remove the exponent bias
	exponent = exponent - 2 ^ (size_exp - 1) + 1

	-- Decrease the size of the exponent rather than make the fraction (0.5, 1]
	exponent = exponent - size_fraction
    
	return sign * math.ldexp(fraction, exponent)
end

local function writer(value, size_exp, size_fraction)
	local fraction, exponent, sign
	local width = (size_exp + size_fraction + 1)/8
	local endian = common.is_bigendian and ">" or "<"
    local bias = 2^(size_exp-1)-1
	
	if value < 0 
    or 1/value == -math.huge then -- handle the case of -0
		sign = true
		value = -value
	else
		sign = false
	end

	-- special case: value is infinite
	if value == math.huge then
		exponent = bias+1
		fraction = 0
	
	-- special case: value is NaN
	elseif value ~= value then
		exponent = bias+1
		fraction = 2^(size_fraction-1)

    --special case: value is 0
    elseif value == 0 then
        exponent = -bias
        fraction = 0
        
	else
		fraction,exponent = math.frexp(value)
        
        -- subnormal number
        if exponent+bias <= 1 then
            fraction = fraction * 2^(size_fraction+(exponent+bias)-1)
            exponent = -bias

        else
            -- remove the most significant bit from the fraction and adjust exponent
            fraction = fraction - 0.5
            exponent = exponent - 1
            
            -- turn the fraction into an integer
            fraction = fraction * 2^(size_fraction+1)
        end
	end
	
    
    -- add the exponent bias
    exponent = exponent + bias

	local bits = struct.explode(fraction)
	local bits_exp = struct.explode(exponent)
	for i=1,size_exp do
		bits[size_fraction+i] = bits_exp[i]
	end
	bits[size_fraction+size_exp+1] = sign
    
	return struct.pack(endian.."m"..width, {bits})
end

-- Create readers and writers for the IEEE sizes
fp.sizes = {
	[4] = {1,  8, 23},
	[8] = {1, 11, 52},
}

fp.r = {}
fp.w = {}
for width, sizes in pairs(fp.sizes) do
	fp.r[width] = function(uint) return reader(uint, sizes[2], sizes[3]) end
	fp.w[width] = function(valu) return writer(valu, sizes[2], sizes[3]) end
end

return fp
