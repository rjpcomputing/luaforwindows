--- Prototype-based objects
-- <ul>
-- <li>Create an object/class:</li>
-- <ul>
-- <li><code>object/class = prototype {value, ...; field = value ...}</code></li>
-- <li>An object's metatable is itself.</li>
-- <li>In the initialiser, unnamed values are assigned to the fields
-- given by <code>_init</code> (assuming the default
-- <code>_clone</code>).</li>
-- <li>Private fields and methods start with "<code>_</code>".</li>
-- </ul>
-- <li>Access an object field: <code>object.field</code></li>
-- <li>Call an object method: <code>object:method (...)</code></li>
-- <li>Call a class method: <code>Class.method (object, ...)</li>
-- <li>Add a field: <code>object.field = x</code></li>
-- <li>Add a method: <code>function object:method (...) ... end</code></li>
-- </li>
module ("object", package.seeall)

require "table_ext"


--- Root object
-- @class table
-- @name Object
-- @field _init list of fields to be initialised by the
-- constructor: assuming the default _clone, the
-- numbered values in an object constructor are
-- assigned to the fields given in <code>_init</code>
-- @field _clone object constructor which takes initial values for
-- fields in <code>_init</code>
_G.Object = {
  _init = {},

  _clone = function (self, values)
             local object = table.merge (self, table.rearrange (self._init, values))
             return setmetatable (object, object)
           end,

  -- Sugar instance creation
  __call = function (...)
             -- First (...) gets first element of list
             return (...)._clone (...)
           end,
}
setmetatable (Object, Object)
