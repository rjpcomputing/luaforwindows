*Moses: a utility-belt library for Lua*

__Moses__ is a Lua utility library which provides support for functional programming. 
It complements built-in Lua functions, making easier common operations on tables, arrays, lists, collections, objects, and a lot more.<br/>
__Moses__ was deeply inspired by [Underscore.js](http://documentcloud.github.com/underscore/). 

# <a name='TOC'>Table of Contents</a>

* [Adding *Moses* to your project](#adding)
* [*Moses*' API](#API)
	* [Table functions](#table)
	* [Array functions](#array)
	* [Utility functions](#utility)
	* [Object functions](#object)
	* [Chaining](#chaining)
	* [Import](#import)

# <a name='adding'>Adding *Moses* to your project</a>

Drop the file [moses.lua](http://github.com/Yonaba/Moses/blob/master/moses.lua) into your project and add it to your code with the *require* function:

```lua
local _ = require ("moses")
````

*Note: Lua purists tend to use "\_" to design a "dummy variable". Here, the usage of this underscore is quite idiomatic and refers to the name [Underscore](http://documentcloud.github.com/underscore/), the JS library from which *Moses* takes inspiration*.

**[[⬆]](#TOC)**

# <a name='API'>*Moses*' API</a>

*Moses*' consists of a large set of functions that can be classified into four categories:

* __Table functions__, which are mostly meant for tables, i.e Lua tables which contains both an array-part and/or a map-part,
* __Array functions__, meant for array lists (or sequences),
* __Utility functions__,
* __Object functions__, meant for instances/classes.

**[[⬆]](#TOC)**

## <a name='table'>Table functions</a>


### each (t, f, ...)
*Aliases: `_.forEach`*.

Iterates over each key-value pair in table.

```lua
_.each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
````

The table can be map-like (array part and hash-part).

```lua
_.each({one = 1, two = 2, three = 3},print)

-- => one 1
-- => two 2
-- => three 3
````

Can index and assign in an outer table or in the passed-in table:

```lua
t = {'a','b','c'}
_.each(t,function(i,v)
  t[i] = v:rep(2)
  print(t[i])
end)

-- => 1 aa
-- => 2 bb
-- => 3 cc
````

### eachi (t, f, ...)
*Aliases: `_.forEachi`*.

Iterates only on integer keys in a sparse array table.

```lua
_.eachi({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
````

The given array can be sparse, or even have a hash-like part.

```lua
local t = {a = 1, b = 2, [0] = 1, [-1] = 6, 3, x = 4, 5}
_.eachi(t,function(i,v)
  print(i,v)
end)

-- => -1 6
-- => 0	1
-- => 1	3
-- => 2	5
````

### at (t, ...)

Collects all values at some specific keys and returns them in an array.

```lua
local t = {4,5,6}
_.at(t,1,3) -- => "{4,6}"

local t = {a = 4, bb = true, ccc = false}
_.at(t,'a', 'ccc') -- => "{4, false}"
````

### count (t, value)

Counts the number of occurences of a given value in a table.

```lua
_.count({1,1,2,3,3,3,2,4,3,2},1) -- => 2
_.count({1,1,2,3,3,3,2,4,3,2},2) -- => 2
_.count({1,1,2,3,3,3,2,4,3,2},3) -- => 4
_.count({false, false, true},false) -- => 2
_.count({false, false, true},true) -- => 1
````

Returns the size of the list in case no value was provided.

```lua
_.count({1,1,2,3,3}) -- => 5
````

### countf (t, f, ...)

Count the number of occurences of all values passing an iterator test.

```lua
_.countf({1,2,3,4,5,6}, function(i,v)
  return v%2==0
end) -- => 3

_.countf({print, pairs, os, assert, ipairs}, function(i,v)
  return type(v)=='function'
end) -- => 4
````

### cycle (t, n)
*Aliases: `_.loop`*.

Returns a function which iterates on each key-value pair in a given table (similarly to `_.each`), except that it restarts iterating again `n` times.
If `n` is not provided, it defaults to 1.

```lua
local t = {'a,'b','c'}
for k,v in _.cycle(t, 2) do
  print(k,v)
end

-- => 1 'a'
-- => 2 'b'
-- => 3 'c'
-- => 1 'a'
-- => 2 'b'
-- => 3 'c'
````

Supports array-like tables and map-like tables.

```lua
local t = {x = 1, y = 2, z = 3}
for k,v in _.cycle(t) do
  print(k,v)
end

-- => y	2
-- => x	1
-- => z	3
````

### map (t, f, ...)
*Aliases: `_.collect`*.

Executes a function on each key-value pairs.

```lua
_.map({1,2,3},function(i,v) 
  return v+10 
end)) -- => "{11,12,13}"
````

```lua
_.map({a = 1, b = 2},function(k,v) 
  return k..v 
end) -- => "{a = 'a1', b = 'b2'}"
````

### reduce (t, f, state)
*Aliases: `_.inject`, `_.foldl`*.

Can sums all values in a table.

```lua
_.reduce({1,2,3,4},function(memo,v)
  return memo+v 
end) -- => 10
````

Or concatenates all values.

```lua	
_.reduce({'a','b','c','d'},function(memo,v) 
  return memo..v 
end) -- => abcd	 
````

### reduceRight (t, f, state)
*Aliases: `_.injectr`, `_.foldr`*.

Similar to `_.reduce`, but performs from right to left.

```lua
local initial_state = 256
_.reduceRight({1,2,4,16},function(memo,v) 
  return memo/v 
end,initial_state) -- => 2
````

### mapReduce (t, f, state)
*Aliases: `_.mapr`*.

Reduces while saving intermediate states.

```lua
_.mapReduce({'a','b','c'},function(memo,v) 
  return memo..v 
end) -- => "{'a', 'ab', 'abc'}"
````

### mapReduceRight (t, f, state)
*Aliases: `_.maprr`*.

Reduces from right to left, while saving intermediate states.

```lua
_.mapReduceRight({'a','b','c'},function(memo,v) 
  return memo..v 
end) -- => "{'c', 'cb', 'cba'}"
````

### include (t, value)
*Aliases: `_.any`, `_.some`*.

Looks for a value in a table.

```lua
_.include({6,8,10,16,29},16) -- => true
_.include({6,8,10,16,29},1) -- => false

local complex_table = {18,{2,{3}}}
local collection = {6,{18,{2,6}},10,{18,{2,{3}}},29}
_.include(collection, complex_table) -- => true
````

Handles iterator functions.

```lua
local function isUpper(v) return v:upper()== v end
_.include({'a','B','c'},isUpper) -- => true
````

### detect (t, value)

Returns the index of a value in a table.

```lua
_.detect({6,8,10,16},8) -- => 2
_.detect({nil,true,0,true,true},false) -- => nil

local complex_table = {18,{2,6}}
local collection = {6,{18,{2,6}},10,{18,{2,{3}}},29}
_.detect(collection, complex_table) -- => 2
````

Handles iterator functions.

```lua
local function isUpper(v)
  return v:upper()==v
end
_.detect({'a','B','c'},isUpper) -- => 2
````

### contains (t, value)

Returns true if the passed-in value was found in a given table.

```lua
_.contains({6,8,10,16},8) -- => true
_.contains({nil,true,0,true,true},false) -- => false
````

It can lookup for objects, and accepts iterator functions aswell:

```lua
_.contains({6,{18,{2,6}},10,{18,{2,{3}}},29},{18,{2,6}}) -- => true

_.contains({'a','B','c'}, function(array_value)
  return (array_value:upper() == array_value)
end) -- => true
````	

### findWhere (t, props)

Looks through a table and returns the first value that matches all of the key-value pairs listed in properties. 

```lua
local a = {a = 1, b = 2, c = 3}
local b = {a = 2, b = 3, d = 4}
local c = {a = 3, b = 4, e = 5}
_.findWhere({a, b, c}, {a = 3, b = 4}) == c -- => true
````

### select (t, f, ...)
*Aliases: `_.filte`*.

Collects values passing a validation test.

```lua
-- Even values
_.select({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2==0)
end) -- => "{2,4,6}"

-- Odd values
_.select({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2~=0)
end) -- => "{1,3,5,7}"
````

### reject (t, f, ...)
*Aliases: `_.reject`*.

Removes all values failing a validation test:

```lua
_.reject({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2==0)
end) -- => "{1,3,5,7}"

_.reject({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2~=0)
end) -- => "{2,4,6}"
````

### all (t, f, ...)
*Aliases: `_.every`*.

Checks whether or not all elements pass a validation test.

```lua
_.all({2,4,6}, function(key,value) 
  return (value%2==0)
end) -- => true
````

### invoke (t, method, ...)

Invokes a given function on each value in a table

```lua
_.invoke({'a','bea','cdhza'},string.len) -- => "{1,3,5}"
````

Can reference the method of the same name in each value.

```lua
local a = {}
function a:call() return 'a' end
local b, c, d = {}, {}, {}
b.call, c.call, d.call = a.call, a.call, a.call

_.invoke({a,b,c,d},'call') -- => "{'a','a','a','a'}"
````

### pluck (t, property)

Fetches all values indxed with specific key in a table of objects.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}

_.pluck(peoples,'age') -- => "{23,17,15,33}"
_.pluck(peoples,'name') -- => "{'John', 'Peter', 'Steve'}"
````

### max (t, transform, ...)

Returns the maximum value in a collection.

```lua
_.max {1,2,3} -- => 3
_.max {'a','b','c'} -- => 'c'
````

Can take an iterator function to extract a specific property.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}
_.max(peoples,function(people) return people.age end) -- => 33
````

### min (t, transform, ...)

Returns the minimum value in a collection.

```lua
_.min {1,2,3} -- => 1
_.min {'a','b','c'} -- => 'a'
````

Can take an iterator function to extract a specific property.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}
_.min(peoples,function(people) return people.age end) -- => 15
````

### shuffle (t, seed)

Shuffles a collection.

```lua
local list = _.shuffle {1,2,3,4,5,6} -- => "{3,2,6,4,1,5}"
_.each(list,print)
````

### same (a, b)

Tests whether or not all values in each of the passed-in tables exists in both tables.

```lua
local a = {'a','b','c','d'}      
local b = {'b','a','d','c'}
_.same(a,b) -- => true

b[#b+1] = 'e'
_.same(a,b) -- => false
````

### sort (t, comp)

Sorts a collection.

```lua
_.sort({'b','a','d','c'}) -- => "{'a','b','c','d'}"
````

Handles custom comparison functions.

```lua
_.sort({'b','a','d','c'}, function(a,b) 
  return a:byte() > b:byte() 
end) -- => "{'d','c','b','a'}"
````

### groupBy (t, iter, ...)

Groups values in a collection depending on their return value when passed to a predicate test.

```lua
_.groupBy({0,1,2,3,4,5,6},function(i,value) 
  return value%2==0 and 'even' or 'odd'
end) -- => "{odd = {1,3,5}, even = {0,2,4,6}}"

_.groupBy({0,'a',true, false,nil,b,0.5},function(i,value) 
  return type(value) 
end) -- => "{number = {0,0.5}, string = {'a'}, boolean = {true, false}}"		
````

### countBy (t, iter, ...)

Splits a table in subsets and provide the count for each subset.

```lua
_.countBy({0,1,2,3,4,5,6},function(i,value) 
  return value%2==0 and 'even' or 'odd'
end) -- => "{odd = 3, even = 4}"
````

### size (...)

When given a table, provides the count for the very number of values in that table.

```lua
_.size {1,2,3} -- => 3
_.size {one = 1, two = 2} -- => 2
````

When given a vararg list of argument, returns the count of these arguments.

```lua
_.size(1,2,3) -- => 3
_.size('a','b',{}, function() end) -- => 4
````

### containsKeys (t, other)

Checks whether a table has all the keys existing in another table.

```lua
_.contains({1,2,3,4},{1,2,3}) -- => true
_.contains({1,2,'d','b'},{1,2,3,5}) -- => true
_.contains({x = 1, y = 2, z = 3},{x = 1, y = 2}) -- => true
````

### sameKeys (tA, tB)

Checks whether both tables features the same keys:

```lua
_.sameKeys({1,2,3,4},{1,2,3}) -- => false
_.sameKeys({1,2,'d','b'},{1,2,3,5}) -- => true
_.sameKeys({x = 1, y = 2, z = 3},{x = 1, y = 2}) -- => false
````

**[[⬆]](#TOC)**

## <a name='array'>Array functions</a>

### toArray (...)

Converts a vararg list of arguments to an array.

```lua
_.toArray(1,2,8,'d','a',0) -- => "{1,2,8,'d','a',0}"
````

### find (array, value, from)

Looks for a value in a given array and returns the position of the first occurence.

```lua
_.find({{4},{3},{2},{1}},{3}) -- => 2
````

It can also start the search at a specific position in the array:

```lua
-- search value 4 starting from index 3
_.find({1,4,2,3,4,5},4,3) -- => 5
````

### reverse (array)

Reverses an array.

```lua
_.reverse({1,2,3,'d'}) -- => "{'d',3,2,1}"
````

### selectWhile (array, f, ...
*Aliases: `_.takeWhile`*.

Collects values as long as they pass a given test. Stops on the first non-passing test.

```lua
_.selectWhile({2,4,5,8}, function(i,v)
  return v%2==0
end) -- => "{2,4}"
````

### dropWhile (array, f, ...
*Aliases: `_.rejectWhile`*.

Removes values as long as they pass a given test. Stops on the first non-passing test.

```lua
_.dropWhile({2,4,5,8}, function(i,v)
  return v%2==0
end) -- => "{5,8}"
````

### sortedIndex (array, value, comp, sort)

Returns the index at which a value should be inserted to preserve order.

```lua
_.sortedIndex({1,2,3},4) -- => 4
````

Can take a custom comparison functions.

```lua
local comp = function(a,b) return a<b end
_.sortedIndex({-5,0,4,4},3,comp) -- => 3
````

### indexOf (array, value)

Returns the index of a value in an array.

```lua
_.indexOf({1,2,3},2) -- => 2
````

### lastIndexOf (array, value)

Returns the index of the last occurence of a given value in an array.

```lua
_.lastIndexOf({1,2,2,3},2) -- => 3
````

### addTop (array, ...)

Adds given values at the top of an array. The latter values bubbles at the top.

```lua
local array = {1}
_.addTop(array,1,2,3,4) -- => "{4,3,2,1,1}"
````

### push (array, ...)

Adds given values at the end of an array.

```lua
local array = {1}
_.push(array,1,2,3,4) -- => "{1,1,2,3,4}"
````

### pop (array, n)
*Aliases: `_.shift`*.

Removes and returns the first value in an array.

```lua
local array = {1,2,3}
local pop = _.pop(array) -- => "pop = 1", "array = {2,3}"
````

### unshift (array, n)

Removes and returns the last value in an array.

```lua
local array = {1,2,3}
local value = _.unshift(array) -- => "value = 3", "array = {1,2}"
````

### pull (array, ...)
*Aliases: `_.remove`*.

Removes all provided values from a given array.

```lua
_.pull({1,2,1,2,3,4,3},1,2,3) -- => "{4}"
````

### removeRange (array, start, finish)
*Aliases: `_.rmRange`, `_.chop`*.

Trims out all values index within a range.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.removeRange(array, 3,8) -- => "{1,2,9}"
````

### chunk (array, f, ...)

Iterates over an array aggregating consecutive values in subsets tables, on the basis of the return
value of `f(key,value,...)`. Consecutive elements which return the same value are aggregated together.

```lua
local t = {1,1,2,3,3,4}
_.chunk(t, function(k,v) return v%2==0 end) -- => "{{1,1},{2},{3,3},{4}}"
````

### slice (array, start, finish)
*Aliases: `_.sub`*.

Slices and returns a part of an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.slice(array, 3,6) -- => "{3,4,5,6}"
````

### first (array, n)
*Aliases: `_.head`, `_.take`*.

Returns the first N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.first(array,3) -- => "{1,2,3}"
````

### initial (array, n)

Excludes the last N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.initial(array,5) -- => "{1,2,3,4}"
````

### last (array, n)
*Aliases: `_.skip`*.

Returns the last N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.last(array,3) -- => "{7,8,9}"
````

### rest (array, index)
*Aliases: `_.tail`*.

Trims out all values indexed before *index*.

```lua
local array = {1,2,3,4,5,6,7,8,9}
_.rest(array,6) -- => "{6,7,8,9}"
````

### compact (array)

Trims out all falsy values.

```lua
_.compact {a,'aa',false,'bb',true} -- => "{'aa','bb',true}"
````

### flatten (array, shallow)

Flattens a nested array.

```lua
_.flatten({1,{2,3},{4,5,{6,7}}}) -- => "{1,2,3,4,5,6,7}"
````

When given arg "shallow", flatten only at the first level.

```lua
_.flatten({1,{2},{{3}}},true) -- => "{1,{2},{{3}}}"
````

### difference (array, array2)
*Aliases: `_.without`, `_.diff`*.

Returns values in the given array not present in a second array.

```lua
local array = {1,2,'a',4,5}
_.difference(array,{1,'a'}) -- => "{2,4,5}"
````

### union (...)

Produces a duplicate-free union of all passed-in arrays.

```lua
local A = {'a'}
local B = {'a',1,2,3}
local C = {2,10}
_.union(A,B,C) -- => "{'a',1,2,3,10}"
````

### intersection (array, ...)

Returns the intersection (common-part) of all passed-in arrays:

```lua
local A = {'a'}
local B = {'a',1,2,3}
local C = {2,10,1,'a'}
_.intersection(A,B,C) -- => "{'a',2,1}"
````

### symmetricDifference (array, array2)
*Aliases: `_.symdiff`,`_.xor`*.

Returns values in the first array not present in the second and also values in the second array not present in the first one.

```lua
local array = {1,2,3}
local array2 = {1,4,5}
_.symmetricDifference(array, array2) -- => "{2,3,4,5}"
````

### unique (array)
*Aliases: `_.uniq`*.

Makes an array duplicate-free.

```lua
_.unique {1,1,2,2,3,3,4,4,4,5} -- => "{1,2,3,4,5}"
````

### isunique (array)
*Aliases: `_.isuniq`*.

Checks if a given array contains no duplicate value.

```lua
_.isunique({1,2,3,4,5}) -- => true
_.isunique({1,2,3,4,4}) -- => false
````

### zip (...)

Zips values from different arrays, on the basis on their common keys.

```lua
local names = {'Bob','Alice','James'}
local ages = {22, 23}
_.zip(names,ages) -- => "{{'Bob',22},{'Alice',23},{'James'}}"
````

### append (array, other)

Appends two arrays.

```lua
_.append({1,2,3},{'a','b'}) -- => "{1,2,3,'a','b'}"
````

### interleave (...)

Interleaves values from passed-in arrays.

```lua
t1 = {1, 2, 3}
t2 = {'a', 'b', 'c'}
_.interleave(t1, t2) -- => "{1,'a',2,'b',3,'c'}"
````

### interpose (value, array)

Interposes a value between consecutive values in an arrays.

```lua
_.interleave('a', {1,2,3}) -- => "{1,'a',2,'a',3}"
````

### range (...)

Generates an arithmetic sequence.

```lua
_.range(1,4) -- => "{1,2,3,4}"
````

In case a single value is provided, it generates a sequence from 0 to that value.

````
_.range(3) -- => "{0,1,2,3}"
````

The incremental step can also be provided as third argument.

```lua
_.range(0,2,0.7) -- => "{0,0.7,1.4}"
````

### rep (value, n)

Generates a list of n repetitions of a value.

```lua
_.rep(4,3) -- => "{4,4,4}"
````

### partition (array, n)
*Aliases: `_.part`*.

Returns an iterator function for partitions of a given array.

```lua
local t = {1,2,3,4,5,6}
for p in _.partition(t,2) do
  print(table.concat(p, ','))
end

-- => 1,2
-- => 3,4
-- => 5,6
````

### permutation (array)
*Aliases: `_.perm`*.

Returns an iterator function for permutations of a given array.

```lua
t = {'a','b','c'}
for p in _.permutation(t) do
  print(table.concat(p))
end

-- => 'bca'
-- => 'cba'
-- => 'cab'
-- => 'acb'
-- => 'bac'
-- => 'abc'
````

### invert (array)
*Aliases: `_.mirror`*.

Switches <tt>key-value</tt> pairs:

```lua
_.invert {'a','b','c'} -- => "{a=1, b=2, c=3}"
````

### concat (array, sep, i, j)
*Aliases: `_.join`*.

Concatenates a given array values:

```lua
_.concat({'a',1,0,1,'b'}) -- => 'a101b'
````

**[[⬆]](#TOC)**

## <a name='utility'>Utility functions</a>

### identity (value)

Returns the passed-in value. <br/>
This function is internally used as a default transformation function.

```lua
_.identity(1)-- => 1
_.identity(false) -- => false
_.identity('hello!') -- => 'hello!'
````

### once (f)

Produces a function that runs only once. Successive calls to this function will still yield the same input.

```lua
local sq = _.once(function(a) return a*a end)
sq(1) -- => 1
sq(2) -- => 1
sq(3) -- => 1
sq(4) -- => 1
sq(5) -- => 1
````

### memoize (f, hash)
*Aliases: `_.cache`*.

Memoizes a slow-running function. It caches the result for a specific input, so that the next time the function is called with the same input, it will lookup the result in its cache, instead of running again the function body.

```lua
local function fibonacci(n)
  return n < 2 and n or fibonacci(n-1)+fibonacci(n-2)
end  
local mem_fibonacci = _.memoize(fibonacci)
fibonacci(20) -- => 6765 (but takes some time)
mem_fibonacci(20) -- => 6765 (takes less time)
````

### after (f, count)

Produces a function that will respond only after a given number of calls.

```lua
local f = _.after(_.identity,3)
f(1) -- => nil
f(2) -- => nil
f(3) -- => 3
f(4) -- => 4
````

### compose (...)

Composes functions. Each function consumes the return value of the one that follows.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
local compositae = _.compose(f,g,h)
compositae(10) -- => 36
compositae(20) -- => 121
````

### pipe (value, ...)

Pipes a value through a series of functions.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
_.pipe(10,f,g,h) -- => 36
_.pipe(20,f,g,h) -- => 121
````

### complement (f)

Returns a function which returns the logical complement of a given function.

```lua
_.complement(function() return true end)() -- => false
````

### juxtapose (value, ...)
*Aliases: `_.juxt`*.

Calls a sequence of functions with the same input.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
_.juxtapose(10, f, g, h) -- => 100, 11, 5
````

### wrap (f, wrapper)

Wraps a function inside a wrapper. Allows the wrapper to execute code before and after function run.

```lua
local greet = function(name) return "hi: " .. name end
local greet_backwards = _.wrap(greet, function(f,arg)
  return f(arg) ..'\nhi: ' .. arg:reverse()
end) 
greet_backwards('John')

-- => hi: John
-- => hi: nhoJ
````

### times (n, iter, ...)

Calls a given function `n` times.

```lua
local f = ('Lua programming'):gmatch('.')
_.times(3,f) -- => {'L','u','a'}
````

### bind (f, v)

Binds a value to be the first argument to a function.

```lua
local sqrt2 = _.bind(math.sqrt,2)
sqrt2() -- => 1.4142135623731
````

### bindn (f, ...)

Binds a variable number of values to be the first arguments to a function.

```lua
local function out(...) return table.concat {...} end
local out = _.bindn(out,'OutPut',':',' ')
out(1,2,3) -- => OutPut: 123
out('a','b','c','d') -- => OutPut: abcd
````

### uniqueId (template, ...)
*Aliases: `_.uid`*.

Returns an unique integer ID.

```lua
_.uniqueId() -- => 1
````

Can handle string templates for formatted output.

```lua
_.uniqueId('ID%s') -- => 'ID2'
````

Or a function, for the same purpose.

```lua
local formatter = function(ID) return '$'..ID..'$' end
_.uniqueId(formatter) -- => '$ID1$'
````

**[[⬆]](#TOC)**

## <a name='object'>Object functions</a>

### keys (obj)

Collects the names of an object attributes.

```lua
_.keys({1,2,3}) -- => "{1,2,3}"
_.keys({x = 0, y = 1}) -- => "{'y','x'}"
````

### values (obj)

Collects the values of an object attributes.

```lua
_.values({1,2,3}) -- => "{1,2,3}"
_.values({x = 0, y = 1}) -- => "{1,0}"
````

### toBoolean (value)

Converts a given value to a boolean.

```lua
_.toBoolean(true) -- => true
_.toBoolean(false) -- => false
_.toBoolean(nil) -- => false
_.toBoolean({}) -- => true
_.toBoolean(1) -- => true
````

### extend (destObj, ...)

Extends a destination object with the properties of some source objects.

```lua
_.extend({},{a = 'b', c = 'd'}) -- => "{a = 'b', c = 'd'}"
````

### functions (obj, recurseMt)
*Aliases: `_.methods`*.

Returns all functions names within an object.

```lua
_.functions(coroutine) -- => "{'create','resume','running','status','wrap','yield'}"
````

### clone (obj, shallow)

Clones a given object.

```lua
local obj = {1,2,3}
local obj2 = _.clone(obj)
print(obj2 == obj) -- => false
print(_.isEqual(obj2, obj)) -- => true
````

### tap (obj, f, ...)

Invokes a given interceptor function on some object, and then returns the object itself. Useful to tap into method chaining to hook intermediate results.
The pased-interceptor is prototyped as `f(obj,...)`.

```lua
local v = _.chain({1,2,3,4,5,6,7,8,9,10)
  :filter(function(k,v) return v%2~=0 end) -- filters even values
  :tap(function(v) print('Max is', _.max(v) end) -- Tap max values 
  :map(function(k,v) return k^2)
  :value() -- =>	 Max is 9
````

### has (obj, key)

Checks if an object has a given attribute.

```lua
_.has(_,'has') -- => true
_.has(coroutine,'resume') -- => true
_.has(math,'random') -- => true
````

### pick (obj, ...)
*Aliases: `_.choose`*.

Collects whilelisted properties of a given object.

```lua
local object = {a = 1, b = 2, c = 3}
_.pick(object,'a','c') -- => "{a = 1, c = 3}"
````

### omit (obj, ...)
*Aliases: `_.drop`*.

Omits blacklisted properties of a given object.

```lua
local object = {a = 1, b = 2, c = 3}
_.omit(object,'a','c') -- => "{b = 2}"
````

### template (obj, template)
*Aliases: `_.defaults`*.

Applies a template on an object, preserving existing properties.

```lua
local obj = {a = 0}
_.template(obj,{a = 1, b = 2, c = 3}) -- => "{a=0, c=3, b=2}"
````

### isEqual (objA, objB, useMt)
*Aliases: `_.compare`*.

Compares objects:

```lua
_.isEqual(1,1) -- => true
_.isEqual(true,false) -- => false
_.isEqual(3.14,math.pi) -- => false
_.isEqual({3,4,5},{3,4,{5}}) -- => false
````

### result (obj, method, ...)

Calls an object method, passing it as a first argument the object itself.

```lua
_.result('abc','len') -- => 3
_.result({'a','b','c'},table.concat) -- => 'abc'
````

### isTable (t)

Is the given argument an object (i.e a table) ?

```lua
_.isTable({}) -- => true
_.isTable(math) -- => true
_.isTable(string) -- => true
````

### isCallable (obj)

Is the given argument callable ?

```lua
_.isCallable(print) -- => true
_.isCallable(function() end) -- => true
_.isCallable(setmetatable({},{__index = string}).upper) -- => true
_.isCallable(setmetatable({},{__call = function() return end})) -- => true
````

### isArray (obj)

Is the given argument an array (i.e. a sequence) ?

```lua
_.isArray({}) -- => true
_.isArray({1,2,3}) -- => true
_.isArray({'a','b','c'}) -- => true
````

### isIterable (obj)

Checks if the given object is iterable with `pairs`.

```lua
_.isIterable({}) -- => true
_.isIterable(function() end) -- => false
_.isIterable(false) -- => false
_.isIterable(1) -- => false
````

### isEmpty (obj)

Is the given argument empty ?

```lua
_.isEmpty('') -- => true
_.isEmpty({})  -- => true
_.isEmpty({'a','b','c'}) -- => false
````

### isString (obj)

Is the given argument a string ?

```lua
_.isString('') -- => true
_.isString('Hello') -- => false
_.isString({}) -- => false
````

### isFunction (obj)

Is the given argument a function ?

```lua
_.isFunction(print) -- => true
_.isFunction(function() end) -- => true
_.isFunction({}) -- => false
````

### isNil (obj)

Is the given argument nil ?

```lua
_.isNil(nil) -- => true
_.isNil() -- => true
_.isNil({}) -- => false
````

### isNumber (obj)

Is the given argument a number ?

```lua
_.isNumber(math.pi) -- => true
_.isNumber(math.huge) -- => true
_.isNumber(0/0) -- => true
_.isNumber() -- => false
````

### isNaN (obj)

Is the given argument NaN ?

```lua
_.isNaN(1) -- => false
_.isNaN(0/0) -- => true
````

### isFinite (obj)

Is the given argument a finite number ?

```lua
_.isFinite(99e99) -- => true
_.isFinite(math.pi) -- => true
_.isFinite(math.huge) -- => false
_.isFinite(1/0) -- => false
_.isFinite(0/0) -- => false
````

### isBoolean (obj)

Is the given argument a boolean ?

```lua
_.isBoolean(true) -- => true
_.isBoolean(false) -- => true
_.isBoolean(1==1) -- => true
_.isBoolean(print) -- => false
````

### isInteger (obj)

Is the given argument an integer ?

```lua
_.isInteger(math.pi) -- => false
_.isInteger(1) -- => true
_.isInteger(-1) -- => true
````

**[[⬆]](#TOC)**

## <a name='chaining'>Chaining</a>

*Method chaining* (also known as *name parameter idiom*), is a technique for invoking consecutively method calls in object-oriented style.
Each method returns an object, and methods calls are chained together.
Moses offers chaining for your perusal. <br/>
Let's use chaining to get the count of evey single word in some lyrics (case won't matter here).


```lua
local lyrics = {
  "I am a lumberjack and I am okay",
  "I sleep all night and I work all day",
  "He is a lumberjack and he is okay",
  "He sleeps all night and he works all day"
}

local stats = _.chain(lyrics)
  :map(function(k,line)
	local t = {}
	for w in line:gmatch('(%w+)') do
	  t[#t+1] = w
	end
	return t
  end)
  :flatten()
  :countBy(function(i,v) return v:lower() end)
  :value() 

-- => "{
-- =>    sleep = 1, night = 2, works = 1, am = 2, is = 2,
-- =>    he = 2, and = 4, I = 4, he = 2, day = 2, a = 2,
-- =>    work = 1, all = 4, okay = 2
-- =>  }"
````

For convenience, you can also use `_(value)` to start chaining methods, instead of `_.chain(value)`.

Note that one can use `:value()` to unwrap a chained object.

```lua
local t = {1,2,3}
print(_(t):value() == t) -- => true
````

**[[⬆]](#TOC)**

## <a name='import'>Import</a>

All library functions can be imported in a context using `import` into a specified context.

```lua
local context = {}
_.import(context)

context.each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
````

When no `context` was provided, it defaults to the global environment `_G`.

```lua
_.import()

each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
````

Passing `noConflict` argument leaves untouched conflicting keys while importing into the context.

```lua
local context = {each = 1}
_.import(context, true)

print(context.each) -- => 1
context.eachi({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
````

**[[⬆]](#TOC)**