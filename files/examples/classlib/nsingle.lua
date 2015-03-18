require 'classlib'

print [[
> class.A()
> function A:__init(s) self.s = s end
> function A:ps() print(self.s) end

> class.B(A)
> function B:__init(s, s1)
> 	self.A:__init(s)
> 	self.s1 = s1
> end
> function B:ps1() print(self.s1) end

> class.C(B)
> function C:__init(s, s1, s2)
> 	self[B]:__init(s, s1)
> 	self.s2 = s2
> end
> function C:ps2() print(self.s2) end

> class.D(A)	-- no constructor, initialize A by default constructor.
]]

class.A()
function A:__init(s) self.s = s end
function A:ps() print(self.s) end

class.B(A)
function B:__init(s, s1)
	self.A:__init(s)
	self.s1 = s1
end
function B:ps1() print(self.s1) end

class.C(B)
function C:__init(s, s1, s2)
	self.B:__init(s, s1)
	self.s2 = s2
end
function C:ps2() print(self.s2) end

class.D(A)	-- no constructor, initialize A by default constructor.

print [[
> a = A("a")
> a:ps()
> print(a:is_a(A))
> print(a:is_a(B))
> print(a:is_a(C))
> print(a:is_a(D))
]]

a = A("a")
a:ps()
print(a:is_a(A))
print(a:is_a(B))
print(a:is_a(C))
print(a:is_a(D))

print [[

> b = B("b", "b1")
> b:ps()
> b:ps1()
> print(b:is_a(A))
> print(b:is_a(B))
> print(b:is_a(C))
> print(b:is_a(D))
]]

b = B("b", "b1")
b:ps()
b:ps1()
print(b:is_a(A))
print(b:is_a(B))
print(b:is_a(C))
print(b:is_a(D))

print [[

> c = C("c", "c1", "c2")
> c:ps()
> c:ps1()
> c:ps2()
> print(c:is_a(A))
> print(c:is_a(B))
> print(c:is_a(C))
> print(c:is_a(D))
]]

c = C("c", "c1", "c2")
c:ps()
c:ps1()
c:ps2()
print(c:is_a(A))
print(c:is_a(B))
print(c:is_a(C))
print(c:is_a(D))

print [[

> d = D("d", "extra")
> d:ps()
> print(d:is_a(A))
> print(d:is_a(B))
> print(d:is_a(C))
> print(d:is_a(D))
]]

d = D("d", "extra")
d:ps()
print(d:is_a(A))
print(d:is_a(B))
print(d:is_a(C))
print(d:is_a(D))
