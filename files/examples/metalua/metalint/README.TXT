Metalint 0.2 - README.TXT
=========================

Metalint is a utility that checks Lua and Metalua source files for global
variables usage. Beyond checking toplevel global variables, it also checks
fields in modules: for instance, it will catch typos such as taable.insert(),
both also table.iinsert().

Metalint works with declaration files, which list which globals are declared,
and what can be done with them. The syntax is:

DECL      ::= (DECL_ELEM ";"?) *
DECL_ELEM ::= NAME | "module" NAME DECL "end" | "free" NAME | "private" DECL_ELEM
NAME      ::= <identifier> | <string>

Identifiers and strings are the same as in Lua, except that the only reserved
keywords are "free", "module", "end" and "private". A variable name can be
equivalently specified as a string or as an identifier. Lua comments are allowed
in declaration files, short and long. Check for *.dlua files in the distribution
for examples.

Meaning of declaration elements:

- Standalone names declare the existence of a variable. This variable is not a
  module, i.e. people must not extract fields from it. For instance, the
  function ipairs() will simply be declared as: "ipairs". With this declaration, 
  it's an error to write, for instance, "ipairs.some_field".

- Names preceded with "free" can be used as you want, including arbitrary
  sub-indexing. This is useful for global tables not used as modules, and for
  modules you're too lazy to fully declare. For instance, the declaration "free
  _G" allows you to bypass all checkings, as long as you access stuff through _G
  rather than directly (i.e. "table.iinsert" will fail, but "_G.table.iinsert"
  will be accepted).

- modules contain field declarations. For instance, the contents of the standard
  "os" module will be declared as "module os exit ; setlocale; date; [...]
  execute end".

Declaration files are loaded:

- manually, by passing "-f filename", "-l libname" or "-e
  decl_literal_expression" as options to the checking program. Options are
  processed in order, i.e. if you load a library after a file name to check,
  this library won't be accessible while checking the dource file.

- automatically, when a call to "require()" is found in the code.

- declaration library "base" is automatically loaded.

Declaration library files are retrieved with the same algorithm as for Lua
libraries, except that the pattern string is taken from environment variable
LUA_DPATH rather than LUA_PATH or LUA_CPATH. For instance, if
LUA_DPATH="./?.dlua" and a "require 'walk.id'" is found, the checker will
attempt to load "./walk/id.dlua". It won't fail if it can't find it, but then,
attempts to use globals declared by walk.id are likely to fail.

The metalua base libraries, which include Lua base libraries, can be found in
base.dlua. They're automatically loaded when you run metalint.

Limitations: if you try to affect custom names to modules, e.g. "local
wi=require 'walk.id'", the checker won't be able to check your usage of
subfields of "wi". Similarly, if you redefine require() or module(), or create
custom versions of these, metalint will be lost. Finally, computed access to
modules are obviously not checked, i.e. "local x, y = 'iinsert', { };
table[x](y, 1)" will be accepted.

Future: Metalint is intended to support richer static type checkings, including
function argument types. The idea is not to formally prove type soundness, but
to accelerate the discovery of many silly bugs when using a (possibly third
party) library. However, to perform interesting checks, the type declaration
system must support a couple of non-trivial stuff like union types and higher
order functions. Moreover, runtime checking code could optionally be inserted to
check that a function API is respected when it's called (check the types
extension in Metalua). Stay tuned.

Notice that metalint can easily be turned into a smarter variable localizer,
which would change references to module elements into local variables.
For instance, it would add "local _table_insert = table.insert" at the beginning
of the file, and change every instance of "table.insert" into a reference to the
local variable. This would be much more efficient than simply adding a "local
table=table".



Finally, to accelerate the migration of existing codebases, a decl_dump()
function is provided with metalint, which attempts to generate a declaration for
a module currently loaded in RAM. The result is not always perfect, but remains
a serious time saver:

~/src/metalua/src/sandbox$ metalua
Metalua, interactive REPLoop.
(c) 2006-2008 <metalua@gmail.com>
M> require    "metalint"
M> require    "walk"
M> decl_dump ("walk", "decl/walk.dlua")
M> ^D
~/src/metalua/src/sandbox$ cat decl/walk.dlua
module walk
  debug;
  module tags
    module stat
      Forin;
      Do;
      Set;
      Fornum;
      Invoke;
      While;
      Break;
      Call;
      Label;
      Goto;
      Local;
      If;
      Repeat;
      Localrec;
      Return;
    end;
    module expr
      True;
      String;
      Index;
      Paren;
      Id;
      False;
      Invoke;
      Function;
      Op;
      Number;
      Table;
      Dots;
      Nil;
      Stat;
      Call;
    end;
  end;
  expr_list;
  binder_list;
  guess;
  expr;
  block;
  module traverse
    expr;
    block;
    stat;
    expr_list;
  end;
  stat;
end;

NEW SINCE 0.1:
==============

Feature-wise, option -a replaces all references to declared fields with locals
and stores the compiled result in a .luac compiled file

Architecture-wise, the system now remembers where (i.e. by which require()
statement, if applicable) a given field has been declared. This is necessary for
the autolocal feature to work correctly.