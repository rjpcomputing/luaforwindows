#Binary-Heaps#
Implementation of *binary heaps* data structure in pure Lua

	
##Usage##
Add 'binary_heap.lua' file inside your project.
Call it using __require__ function.
It will return a table containing a set of functions, acting as a class.
	
##API##


* __heap:new()__  : Returns a new heap ( a Min-Heap by default).
* __heap()__      : Same as heap:new()	
* __heap:empty()__ : Checks if a heap is empty.
* __heap:getSize()__ : Returns the size of the heap.
* __heap:clear()__ : Clears a heap
* __heap:leftChildIndex(index)__ : Returns the left child index of element at position index in the heap
* __heap:rightChildIndex(index)__ : Returns the right child index of element at position index in the heap
* __heap:parentIndex(index)__ : Returns the parent index of element at position index in the heap
* __heap:insert(value,linkedData)__ : Inserts value with linked data in the heap and percolates it up at its proper place.
* __heap:add(value, linkedData)__ : Alias to <tt>heap.insert</tt>
* __heap:replace(value,linkedData)__ : Saves the top of the heap, adds a new element at the top and reorders the heap. 		
* __heap:pop()__ : Pops the top element, reorders the heap and returns this element unpacked : value first then data linked
* __heap:checkIndex()__ : checks existence of an element at position index in the heap.
* __heap:reset(function)__ : Reorders the current heap regards to the new comparison function given as argument
* __heap:merge(other)__ : merge the current heap with another
* __heap:isValid()__ : Checks if a heap is valid
* __heap:heap(item)__ : Restores the heap property (in case the heap was earlier found non-valid)

##Additionnal features##

```lua
h1+h2 : Returns a new heap with all data stored inside h1 and h2 heaps
tostring(h) : Returns a string representation of heap h
print(h) : Prints current heap h as a string
```
By default, you create Min-heaps. If you do need __Max-heaps__, you can easily create them this way:

```lua
local comp = function(a,b) return a>b end
local myHeap = heap(comp)
```

##Chaining##
Some functions can be chained together, as they return the heap itself:

```lua 
heap:clear()
heap:add() or heap:insert()
heap:reset()	
heap:merge()
heap:heap()
```

Example:

```lua     
h = Heap()
h:add(1):add(2):heap():clear():add(3):add(4):merge(Heap()):reset()
print(h)
```
	
#Documentation used#
* [Algolist.net data structure course][]
* [Victor S.Adamchik's Lecture on Cs.cmu.edu][]
* [RPerrot's Article on Developpez.com][]

##License##
This work is under MIT-LICENSE
Copyright (c) 2012 Roland Yonaba

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Algolist.net data structure course]: http://www.algolist.net/Data_structures/Binary_heap/Array-based_int_repr
[Victor S.Adamchik's Lecture on Cs.cmu.edu]: http://www.cs.cmu.edu/~adamchik/15-121/lectures/Binary%20Heaps/heaps.html
[RPerrot's Article on Developpez.com]: http://rperrot.developpez.com/articles/algo/structures/arbres/
[Lua Class System]: http://yonaba.github.com/Lua-Class-System/

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/binary-heaps/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

