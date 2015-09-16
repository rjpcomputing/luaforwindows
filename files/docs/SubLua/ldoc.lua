#!/usr/bin/env lua
---------------
-- ## ldoc, a Lua documentation generator.
--
-- Compatible with luadoc-style annotations, but providing
-- easier customization options.
--
-- C/C++ support for Lua extensions is provided.
--
-- Available from LuaRocks as 'ldoc' and as a [Zip file](http://stevedonovan.github.com/files/ldoc-1.3.0.zip)
--
-- [Github Page](https://github.com/stevedonovan/ldoc)
--
-- @author Steve Donovan
-- @copyright 2011
-- @license MIT/X11
-- @script ldoc

local class = require 'pl.class'
local app = require 'pl.app'
local path = require 'pl.path'
local dir = require 'pl.dir'
local utils = require 'pl.utils'
local List = require 'pl.List'
local stringx = require 'pl.stringx'
local tablex = require 'pl.tablex'


local append = table.insert

local lapp = require 'pl.lapp'

-- so we can find our private modules
app.require_here()

--- @usage
local usage = [[
ldoc, a documentation generator for Lua, vs 1.3.1
  -d,--dir (default docs) output directory
  -o,--output  (default 'index') output name
  -v,--verbose          verbose
  -a,--all              show local functions, etc, in docs
  -q,--quiet            suppress output
  -m,--module           module docs as text
  -s,--style (default !) directory for style sheet (ldoc.css)
  -l,--template (default !) directory for template (ldoc.ltp)
  -1,--one              use one-column output layout
  -p,--project (default ldoc) project name
  -t,--title (default Reference) page title
  -f,--format (default plain) formatting - can be markdown, discount or plain
  -b,--package  (default .) top-level package basename (needed for module(...))
  -x,--ext (default html) output file extension
  -c,--config (default config.ld) configuration name
  -i,--ignore ignore any 'no doc comment or no module' warnings
  -D,--define (default none) set a flag to be used in config.ld
  -N,--nocolon don't treat colons specially
  -B,--boilerplate ignore first comment in source files
  --dump                debug output dump
  --filter (default none) filter output as Lua data (e.g pl.pretty.dump)
  --tags (default none) show all references to given tags, comma-separated
  <file> (string) source file or directory containing source

  `ldoc .` reads options from an `config.ld` file in same directory;
  `ldoc -c path/to/myconfig.ld .` reads options from `path/to/myconfig.ld`
]]
local args = lapp(usage)
local lfs = require 'lfs'
local doc = require 'ldoc.doc'
local lang = require 'ldoc.lang'
local tools = require 'ldoc.tools'
local global = require 'ldoc.builtin.globals'
local markup = require 'ldoc.markup'
local parse = require 'ldoc.parse'
local KindMap = tools.KindMap
local Item,File,Module = doc.Item,doc.File,doc.Module
local quit = utils.quit


class.ModuleMap(KindMap)

function ModuleMap:_init ()
   self.klass = ModuleMap
   self.fieldname = 'section'
end

ModuleMap:add_kind('function','Functions','Parameters')
ModuleMap:add_kind('table','Tables','Fields')
ModuleMap:add_kind('field','Fields')
ModuleMap:add_kind('lfunction','Local Functions','Parameters')
ModuleMap:add_kind('annotation','Issues')


class.ProjectMap(KindMap)
ProjectMap.project_level = true

function ProjectMap:_init ()
   self.klass = ProjectMap
   self.fieldname = 'type'
end

ProjectMap:add_kind('module','Modules')
ProjectMap:add_kind('script','Scripts')
ProjectMap:add_kind('topic','Topics')
ProjectMap:add_kind('example','Examples')

local lua, cc = lang.lua, lang.cc

local file_types = {
   ['.lua'] = lua,
   ['.ldoc'] = lua,
   ['.luadoc'] = lua,
   ['.c'] = cc,
   ['.cpp'] = cc,
   ['.cxx'] = cc,
   ['.C'] = cc
}

------- ldoc external API ------------

-- the ldoc table represents the API available in `config.ld`.
local ldoc = {}
local add_language_extension

local function override (field)
   if ldoc[field] ~= nil then args[field] = ldoc[field] end
end

-- aliases to existing tags can be defined. E.g. just 'p' for 'param'
function ldoc.alias (a,tag)
   doc.add_alias(a,tag)
end

-- standard aliases --

ldoc.alias('tparam',{'param',modifiers={type="$1"}})
ldoc.alias('treturn',{'return',modifiers={type="$1"}})
ldoc.alias('tfield',{'field',modifiers={type="$1"}})

function ldoc.tparam_alias (name,type)
   type = type or name
   ldoc.alias(name,{'param',modifiers={type=type}})
end

ldoc.tparam_alias 'string'
ldoc.tparam_alias 'number'
ldoc.tparam_alias 'int'
ldoc.tparam_alias 'bool'
ldoc.tparam_alias 'func'
ldoc.tparam_alias 'tab'
ldoc.tparam_alias 'thread'

function ldoc.add_language_extension(ext, lang)
   lang = (lang=='c' and cc) or (lang=='lua' and lua) or quit('unknown language')
   if ext:sub(1,1) ~= '.' then ext = '.'..ext end
   file_types[ext] = lang
end

function ldoc.add_section (name, title, subname)
   ModuleMap:add_kind(name,title,subname)
end

-- new tags can be added, which can be on a project level.
function ldoc.new_type (tag, header, project_level)
   doc.add_tag(tag,doc.TAG_TYPE,project_level)
   if project_level then
      ProjectMap:add_kind(tag,header)
   else
      ModuleMap:add_kind(tag,header)
   end
end

function ldoc.manual_url (url)
    global.set_manual_url(url)
end

function ldoc.custom_see_handler(pat, handler)
    doc.add_custom_see_handler(pat, handler)
end

local ldoc_contents = {
   'alias','add_language_extension','new_type','add_section', 'tparam_alias',
   'file','project','title','package','format','output','dir','ext', 'topics',
   'one','style','template','description','examples',
   'readme','all','manual_url', 'ignore', 'nocolon','boilerplate',
   'no_return_or_parms','no_summary','full_description','backtick_references', 'custom_see_handler',
}
ldoc_contents = tablex.makeset(ldoc_contents)

local function loadstr (ldoc,txt)
   local chunk, err
   local load
   -- Penlight's Lua 5.2 compatibility has wobbled over the years...
   if not rawget(_G,'loadin') then -- Penlight 0.9.5
       -- Penlight 0.9.7; no more global load() override
      load = load or utils.load
      chunk,err = load(txt,'config',nil,ldoc)
   else
      chunk,err = loadin(ldoc,txt)
   end
   return chunk, err
end

-- any file called 'config.ld' found in the source tree will be
-- handled specially. It will be loaded using 'ldoc' as the environment.
local function read_ldoc_config (fname)
   local directory = path.dirname(fname)
   if directory == '' then
      directory = '.'
   end
   local chunk, err, ok
   if args.filter == 'none' then
      print('reading configuration from '..fname)
   end
   local txt,not_found = utils.readfile(fname)
   if txt then
      chunk, err = loadstr(ldoc,txt)
      if chunk then
         if args.define ~= 'none' then ldoc[args.define] = true end
         ok,err = pcall(chunk)
      end
    end
   if err then quit('error loading config file '..fname..': '..err) end
   for k in pairs(ldoc) do
      if not ldoc_contents[k] then
         quit("this config file field/function is unrecognized: "..k)
      end
   end
   return directory, not_found
end

local quote = tools.quote
--- processing command line and preparing for output ---

local F
local file_list = List()
File.list = file_list
local config_dir


local ldoc_dir = arg[0]:gsub('[^/\\]+$','')
local doc_path = ldoc_dir..'/ldoc/builtin/?.lua'

-- ldoc -m is expecting a Lua package; this converts this to a file path
if args.module then
   -- first check if we've been given a global Lua lib function
   if args.file:match '^%a+$' and global.functions[args.file] then
      args.file = 'global.'..args.file
   end
   local fullpath,mod,on_docpath = tools.lookup_existing_module_or_function (args.file, doc_path)
   if not fullpath then
      quit(mod)
   else
      args.nocolon = on_docpath
      args.file = fullpath
      args.module = mod
   end
end

local abspath = tools.abspath

-- a special case: 'ldoc .' can get all its parameters from config.ld
if args.file == '.' then
   local err
   config_dir,err = read_ldoc_config(args.config)
   if err then quit("no "..quote(args.config).." found") end
   local config_path = path.dirname(args.config)
   if config_path ~= '' then
      print('changing to directory',config_path)
      lfs.chdir(config_path)
   end
   config_is_read = true
   args.file = ldoc.file or '.'
   if args.file == '.' then
      args.file = lfs.currentdir()
   elseif type(args.file) == 'table' then
      for i,f in ipairs(args.file) do
         args.file[i] = abspath(f)
         print(args.file[i])
      end
   else
      args.file = abspath(args.file)
   end
else
   args.file = abspath(args.file)
end

local source_dir = args.file
if type(source_dir) == 'table' then
   source_dir = source_dir[1]
end
if type(source_dir) == 'string' and path.isfile(source_dir) then
   source_dir = path.splitpath(source_dir)
end

---------- specifying the package for inferring module names --------
-- If you use module(...), or forget to explicitly use @module, then
-- ldoc has to infer the module name. There are three sensible values for
-- `args.package`:
--
--  * '.' the actual source is in an immediate subdir of the path given
--  * '..' the path given points to the source directory
--  * 'NAME' explicitly give the base module package name
--

local function setup_package_base()
   if ldoc.package then args.package = ldoc.package end
   if args.package == '.' then
      args.package = source_dir
   elseif args.package == '..' then
      args.package = path.splitpath(source_dir)
   elseif not args.package:find '[\\/]' then
      local subdir,dir = path.splitpath(source_dir)
      if dir == args.package then
         args.package = subdir
      elseif path.isdir(path.join(source_dir,args.package)) then
         args.package = source_dir
      else
         quit("args.package is not the name of the source directory")
      end
   end
end


--------- processing files ---------------------
-- ldoc may be given a file, or a directory. `args.file` may also be specified in config.ld
-- where it is a list of files or directories. If specified on the command-line, we have
-- to find an optional associated config.ld, if not already loaded.

if ldoc.ignore then args.ignore = true end

local function process_file (f, flist)
   local ext = path.extension(f)
   local ftype = file_types[ext]
   if ftype then
      if args.verbose then print(path.basename(f)) end
      local F,err = parse.file(f,ftype,args)
      if err then
         if F then
            F:warning("internal LDoc error")
         end
         quit(err)
      end
      flist:append(F)
   end
end

local process_file_list = tools.process_file_list

setup_package_base()


if type(args.file) == 'table' then
   -- this can only be set from config file so we can assume it's already read
   process_file_list(args.file,'*.*',process_file, file_list)
   if #file_list == 0 then quit "no source files specified" end
elseif path.isdir(args.file) then
   local files = List(dir.getallfiles(args.file,'*.*'))
   -- use any configuration file we find, if not already specified
   if not config_dir then
      local config_files = files:filter(function(f)
         return path.basename(f) == args.config
      end)
      if #config_files > 0 then
         config_dir = read_ldoc_config(config_files[1])
         if #config_files > 1 then
            print('warning: other config files found: '..config_files[2])
         end
      end
   end
   for f in files:iter() do
      process_file(f, file_list)
   end
   if #file_list == 0 then
      quit(quote(args.file).." contained no source files")
   end
elseif path.isfile(args.file) then
   -- a single file may be accompanied by a config.ld in the same dir
   if not config_dir then
      config_dir = path.dirname(args.file)
      if config_dir == '' then config_dir = '.' end
      local config = path.join(config_dir,args.config)
      if path.isfile(config) then
         read_ldoc_config(config)
      end
   end
   process_file(args.file, file_list)
   if #file_list == 0 then quit "unsupported file extension" end
else
   quit ("file or directory does not exist: "..quote(args.file))
end

-- create the function that renders text (descriptions and summaries)
override 'format'
ldoc.markup = markup.create(ldoc, args.format)

------ 'Special' Project-level entities ---------------------------------------
-- Examples and Topics do not contain code to be processed for doc comments.
-- Instead, they are intended to be rendered nicely as-is, whether as pretty-lua
-- or as Markdown text. Treating them as 'modules' does stretch the meaning of
-- of the term, but allows them to be treated much as modules or scripts.
-- They define an item 'body' field (containing the file's text) and a 'postprocess'
-- field which is used later to convert them into HTML. They may contain @{ref}s.

local function add_special_project_entity (f,tags,process)
   local F = File(f)
   tags.name = path.basename(f)
   local text = utils.readfile(f)
   local item = F:new_item(tags,1)
   if process then
      text = process(F, text)
   end
   F:finish()
   file_list:append(F)
   item.body = text
   return item, F
end

if type(ldoc.examples) == 'string' then
   ldoc.examples = {ldoc.examples}
end
if type(ldoc.examples) == 'table' then
   local prettify = require 'ldoc.prettify'

   process_file_list (ldoc.examples, '*.lua', function(f)
      local item = add_special_project_entity(f,{
         class = 'example',
      })
      -- wrap prettify for this example so it knows which file to blame
      -- if there's a problem
      item.postprocess = function(code) return prettify.lua(f,code) end
   end)
end

ldoc.readme = ldoc.readme or ldoc.topics
if type(ldoc.readme) == 'string' then
   ldoc.readme = {ldoc.readme}
end
if type(ldoc.readme) == 'table' then
   process_file_list(ldoc.readme, '*.md', function(f)
      local item, F = add_special_project_entity(f,{
         class = 'topic'
      }, markup.add_sections)
      -- add_sections above has created sections corresponding to the 2nd level
      -- headers in the readme, which are attached to the File. So
      -- we pass the File to the postprocesser, which will insert the section markers
      -- and resolve inline @ references.
      item.postprocess = function(txt) return ldoc.markup(txt,F) end
   end)
end

-- extract modules from the file objects, resolve references and sort appropriately ---

local first_module
local project = ProjectMap()
local module_list = List()
module_list.by_name = {}

local modcount = 0

for F in file_list:iter() do
   for mod in F.modules:iter() do
      if not first_module then first_module = mod end
      if doc.code_tag(mod.type) then modcount = modcount + 1 end
      module_list:append(mod)
      module_list.by_name[mod.name] = mod
   end
end

for mod in module_list:iter() do
   if not args.module then -- no point if we're just showing docs on the console
      mod:resolve_references(module_list)
   end
   project:add(mod,module_list)
end

-- the default is not to show local functions in the documentation.
if not args.all and not ldoc.all then
   for mod in module_list:iter() do
      mod:mask_locals()
   end
end

table.sort(module_list,function(m1,m2)
   return m1.name < m2.name
end)

ldoc.single = modcount == 1 and first_module or nil


-------- three ways to dump the object graph after processing -----

-- ldoc -m will give a quick & dirty dump of the module's documentation;
-- using -v will make it more verbose
if args.module then
   if #module_list == 0 then quit("no modules found") end
   if args.module == true then
      file_list[1]:dump(args.verbose)
   else
      local fun = module_list[1].items.by_name[args.module]
      if not fun then quit(quote(args.module).." is not part of "..quote(args.file)) end
      fun:dump(true)
   end
   return
end

-- ldoc --dump will do the same as -m, except for the currently specified files
if args.dump then
   for mod in module_list:iter() do
      mod:dump(true)
   end
   os.exit()
end
if args.tags ~= 'none' then
   local tagset = {}
   for t in stringx.split(args.tags,','):iter() do
      tagset[t] = true
   end
   for mod in module_list:iter() do
      mod:dump_tags(tagset)
   end
   os.exit()
end

-- ldoc --filter mod.name will load the module `mod` and pass the object graph
-- to the function `name`. As a special case --filter dump will use pl.pretty.dump.
if args.filter ~= 'none' then
   doc.filter_objects_through_function(args.filter, module_list)
   os.exit()
end

ldoc.css, ldoc.templ = 'ldoc.css','ldoc.ltp'

local function style_dir (sname)
   local style = ldoc[sname]
   local dir
   if style then
      if style == true then
         dir = config_dir
      elseif type(style) == 'string' and path.isdir(style) then
         dir = style
      else
         quit(quote(tostring(name)).." is not a directory")
      end
      args[sname] = dir
   end
end


-- the directories for template and stylesheet can be specified
-- either by command-line '--template','--style' arguments or by 'template and
-- 'style' fields in config.ld.
-- The assumption here is that if these variables are simply true then the directory
-- containing config.ld contains a ldoc.css and a ldoc.ltp respectively. Otherwise
-- they must be a valid subdirectory.

style_dir 'style'
style_dir 'template'

-- can specify format, output, dir and ext in config.ld
override 'output'
override 'dir'
override 'ext'
override 'one'
override 'nocolon'
override 'boilerplate'

if not args.ext:find '^%.' then
   args.ext = '.'..args.ext
end

if args.one then
   ldoc.css = 'ldoc_one.css'
end

if args.style == '!' or args.template == '!' then
   -- '!' here means 'use built-in templates'
   local tmpdir = path.join(path.is_windows and os.getenv('TMP') or '/tmp','ldoc')
   if not path.isdir(tmpdir) then
      lfs.mkdir(tmpdir)
   end
   local function tmpwrite (name)
      utils.writefile(path.join(tmpdir,name),require('ldoc.html.'..name:gsub('%.','_')))
   end
   if args.style == '!' then
      tmpwrite(ldoc.templ)
      args.style = tmpdir
   end
   if args.template == '!' then
      tmpwrite(ldoc.css)
      args.template = tmpdir
   end
end

ldoc.log = print
ldoc.kinds = project
ldoc.modules = module_list
ldoc.title = ldoc.title or args.title
ldoc.project = ldoc.project or args.project
ldoc.package = args.package:match '%a+' and args.package or nil

local html = require 'ldoc.html'

html.generate_output(ldoc, args, project)

if args.verbose then
   print 'modules'
   for k in pairs(module_list.by_name) do print(k) end
end


