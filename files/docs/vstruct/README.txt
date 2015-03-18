Contents
========
1.	Overview
2.	API
3.	Warning!
4.	The Format String
		Naming
		Grouping
		Repetition
5.	Format Specifiers
6.	Credits


1. Overview
===========
VStruct is a library for Lua 5.1. It provides functions for manipulating binary
data, in particular for unpacking binary files or byte buffers into Lua values
and for packing Lua values back into files or buffers. Supported data types
include:
	- signed and unsigned integers of arbitrary byte width
	- booleans and bitmasks
	- plain and null-terminated strings
	- fixed and floating point reals (the latter requires C module support)
In addition, the library supports seeking, alignment, and byte order controls,
repetition, grouping of data into tables, and naming of values within tables.



2. API
======	
exports:
	vstruct.pack(fmt, [fd], data)
	vstruct.unpack(fmt, <fd or string>, [unpacked])
	vstruct.explode(int)
	vstruct.implode(table)
	vstruct.cursor(string)
	vstruct.compile.read(format)
	vstruct.compile.write(format)

pack takes a format string and a table of data and packs the contents into a
buffer. If the fd argument is present, it will write the data directly to it
using standard file io methods (write and seek), and return the fd; otherwise
it will construct and return a string. In either case it also returns (as a
second value) the number of bytes written - note that if the format involved
seeks, this is not the same as the amount by which the write pointer moved
or the size of the packed string.

unpack takes a format string and a buffer or file to unpack from, and returns
the unpacked data as a table. It also returns (as a second value) the number of
bytes read - note that if the format string involved seeks, this is not the same
as the difference between read pointer positions. If the _unpacked_ argument is
true, it will return the unpacked data as a series of values rather than as a
table, equivalent to using the standard Lua function unpack() on the return
value. Note that this means it will not return the number of bytes read as an
additional value.

explode converts a bitmask into a list of booleans, and implode does the
converse. In such lists, list[1] is the least significant bit, and list[n] the
most significant.

cursor wraps a string in something that looks, at first glance, like a file.
This permits strings to be wrapped and passed to the vstruct IO functions. The
wrapped string supports :seek, and has limited support for :read (the only
supported calling mode is :read(num_bytes)) and :write (as :write(buffer)).

compile.read takes a format string and returns a function, which can later be
passed a file (or file-like object - see vstruct.cursor) to perform a read
operation. In effect, the following code:
	f = vstruct.compile.read(fmt)
	d = f(fd)
Is equivalent to:
	d = vstruct.unpack(fd, fmt)
f can of course be called repeatedly, with different or the same fds each time.

compile.write is the converse of compile.read. The emitted function expects a
file and a table of data elements, so that:
	f = vstruct.compile.write(fmt)
	f(fd, data)
Is equivalent to:
	vstruct.pack(fd, fmt, data)
As with compile.read, the emitted function is fully re-usable.


3. Warning!
===========
When reading and writing numeric formats, vstruct is inherently limited by lua's
number format, which is by default the IEEE 754 double. What this means in
practice is that formats cipPu may be subject to data loss when read in widths
of 7 bytes or more, if they contain more than 52 significant bits. (The same is
true of numeric constants declared in Lua itself, of course, and other libraries
which store values in lua numbers).
Formats bfmsxz are unaffected by this, as they either do not use lua numbers or
are guaranteed to fit inside them.

4. The Format String
====================
The format string contains any number of endianness controls, seek controls,
format specifiers, and grouping/naming sequences, seperated by whitespace,
commas, or semicolons (or any mix thereof, although you are encouraged to choose
one and stick to it for the sake of consistency). Each of these is detailed
below.

In the documentation below, the convention is that A represents an address and W
a width in bytes. At present only base-10 numerals are supported.


Naming
------
Under normal operation, when unpacking, the library simply stores unpacked
values sequentially into a list, which is returned. Similarly, when packing, it
expects a list of values which will be packed in order. However, values can be
named, in which case the unpacked value will be stored in a field with that
name, and when packing, it will use the value stored with that key. This is done
by prefixing the format specifier with the name (which can be any sequence of
letters, numbers, and _, provided it does not start with a number) followed by a
':'. For example, the following format would generate a table with three keys,
'x', 'y', and 'z':
	"x:u4 y:u4 z:u4"
And, when packing, would expect a table with those three keys and store their
corresponding values.

If the same name is specified multiple times, or is combined with repetition
(see below), only the last read value is stored there.

Named and anonymous values can be freely mixed; the named values will be
assigned to their given fields and the anonymous ones to sequential indices.

Grouping
--------
Rather than generating or expecting a flat table, the library can be instructed to
create or read from a table containing subtables. This is done by surrounding the
group of values you wish to be packed with '{' and '}' in the format string. For example,
the following format string:
	"{ u4 i4 } { s32 u4 }"
Would, rather than generating a list of four values, generate a list containing two
lists of two values each.
Similarly, when packing, it would expect not a flat list, but a list of sublists, from
which the values to be packed will be drawn.

Groups can be named, so formats like:
	"flags:m1 coords:{ x:u4 y:u4 z:u4 }"
Are permitted and meaningful.


Repetition
----------
A {} group can be repeated by prefixing or suffixing it with a count, seperated
from the group by a '*'. For example:
	"4 * { u4 }"
	"{ u4 } * 4"
	"{ u4 } { u4 } { u4 } { u4 }"
Are all equivalent. Note that the whitespace in the above examples is optional.
In cases where you want to repeat format specifiers without implying a grouping,
you can use (). For example:
	"4 * (u4 b1)"
Is equivalent to:
	"u4 b1 u4 b1 u4 b1 u4"
Like grouping, these can be nested.


5. Format Specifiers
====================

Endianness Controls
-------------------
The formats i, m, and u are affected by the endianness setting, which controls
the order in which bytes are read and written within a field. The following
characters in a format string adjust the endianness setting:

<
	Sets the endianness to little-endian (eg, Intel processors)
>
	Sets the endianness to big-endian (eg, PPC and Motorola processors)
=
	Sets the endianness to the native endianness.


Seek Controls
-------------
These characters are used to seek to specific locations in the input or output.
Note that they only work on buffers or file-like objects that support the seek()
method; for streams which cannot be sought on, use the 'x' (skip/null-pad)
data format instead.

@A
	Seek to absolute address A.
+A
	Seek forward A bytes.
-A
	Seek backwards A bytes.
aW
	Align to word width W (ie, seek to the next address which is a multiple of W)


Data Format Specifiers
----------------------
bW	Boolean.
	Read: as uW, but returns true if the result is non-zero and false otherwise.
	Write: as uW with input 1 if true and 0 otherwise.

cW	Counted string.
	Read: uW to determine the length of the string W', followed by sW'.
	Write: the length of the string as uW, followed by the string itself.
	The counted string is a common idiom where a string is immediately prefixed
	with its length, as in:
		size_t len;
		char[] str;
	The counted string format can be used to easily read and write these. The
	width provided is the width of the len field, which is treated as an
	unsigned int. Only the string itself is returned (when unpacking) or
	required (when packing).
	The len field is affected by endianness, as in format u.

fW	IEEE 754 floating point.
	Valid widths are 4 (float) and 8 (double). No quads yet, sorry!
	Affected by endianness.

iW	Signed integer.
	Read: a signed integer of width W bytes.
	Write: a signed integer of width W bytes.
	Floating point values will be truncated.
	Affected by endianness.

mW	Bitmask.
	Read: as uW, but explodes the result into a list of booleans, one per bit.
	Write: implodes the input value, then writes it as uW.
	Affected by endianness.
	See also: vstruct.implode, vstruct.explode.

pW	Signed fixed point rational.
	Width is in the format "I.F"; the value before the dot is the number of
	bytes in the integer part, and the value after, in the fractional part.
	Read: a fixed point rational of I+F bytes.
	Write: a fixed point rational of I+F bytes. Values which cannot be exactly
	represented in the specified width are truncated.
	Affected by endianness.

PW	Signed fixed point rational with bit-aligned subfields
	Equivalent to pW, except that the decimal point does not need to be byte
	aligned; for example, formats such as P20.12 are possible.
	Note that underlying reads must still occur in byte multiples. Using a W
	such that I+F is not a multiple of 8 is an error.

sW	String.
	Read: reads exactly W bytes and returns them as a string. If W is omitted,
      reads until EOF.
	Write:
	  If W is omitted, uses the string length.
	  If W is shorter than the string length, truncates the string.
	  If W is greater than the string length, null pads the string.

uW	Unsigned integer.
	Read: an unsigned integer of width W bytes.
	Write: an unsigned integer of width W bytes.
	Floating point values will be truncated.
	Negative values will be taken absolute.
	Affected by endianness.

xW	Skip/pad.
	Read: read and discard the next W bytes.
	Write: write W zero bytes.

zW	Null terminated string.
	Read: reads exactly W bytes. Returns everything up to the first zero byte.
	If W is omitted, reads up to the next zero byte.
	Write: writes exactly W bytes.
	If the input is shorter than W, zero pads the output.
	If as long or longer, truncates to W-1 and writes a zero byte at the end.
	If W is omitted, uses the string length plus one (ie, writes the string
	out entire and then null terminates it).



6. Credits
==========
	While most of the library code was written by me (Ben Kelly), the existence
of this library owes itself to many others:
	The floating point code was contributed by Peter Cawley on lua-l.
	The original inspiration came from Roberto Ierusalimschy's "struct" library
and Luiz Henrique de Figueiredo's "lpack" library, as well as the "struct"
available in Python.
	sanooj, from #lua, has done so much testing and bug reporting that at this
point he's practically a co-author.
	The overall library design and  interface are the result of much discussion
with rici, sanooj, Keffo, snogglethorpe, Spark, kozure, Vornicus, McMartin, and
probably several others I've forgotten about on IRC (#lua on freenode and #code
on nightstar).
	Finally, without Looking Glass Studios to make System Shock, and Team TSSHP
(in particular Jim "hairyjim" Cameron) to reverse engineer it, I wouldn't have
had a reason to write this library in the first place.
