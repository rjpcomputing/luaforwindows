#Version history#

##1.0.0 (01/09/2015)

### New features
* `require "30log"` now returns a callable table
* Added `class.isClass` 
* Added `class.isInstance`
* Adding mixins can be chained
* `subclass.super` returns the `superclass` of `subclass`
* `instance.class` returns the `class` of `instance`

### Breaking changes
* Changed `class` prototype to `class(name, params)`
* Renamed `class:__init()` to `class:init()`
* Renamed `class.__name` to `class.name`
* Renamed `class:extends()` to `class:extend`
* Renamed `class:is()` to `class:extends`
* Renamed `class:has()` to `class:includes`
* Changed `class:extend` prototype to `class:extend(name, params)`
* Changed `tostring(class)` and `tostring(instance)` output.


##0.9.1 (03/02/2014)
* Internal objects/classes registers made tables with weak keys.

##0.9.0 (02/07/2014)
* Added `class.is` and `instance.is` to inspect inheritance relationship between two objects.
* Removed spaces in class/instance tostring output.

##0.8.0 (01/11/2014)
* Mixins are now included with `include`, not `with`
* Objects (instances) cannot call `new`
* Shortened class/instances `__tostring` output (`class (?)` instead of `class (Unnamed)`)
* Bugfixes for `30logclean` (Thanks [zorfmorf](https://github.com/zorfmorf))
* Updated specification tests and README

##0.7.0 (01/05/2014)
* Fix for chained class extension attributes overriding when given a prototype (Thanks [Italo Maia](https://github.com/Yonaba/30log/issues/7))
* Updated specs
* Removed class-commons plugin, moved to [30logclasscommons](http://github.com/Yonaba/30logclasscommons)

##0.6.0 (08/08/2013)
* Added global source
* Made call to class methods available through initializers
* Made class attributes instantly available upon derivation
* Updated clean source
* Updated `Class Commons` compatibility to meet with the its specifications
* Added `Class Commons` test suite
* Updated specs
* Added performance benchmark
* 2 whitespaces as tabs, for indentation

##0.5.0 (06/13/2013)
* Added mixins
* Added clean source
* Updated Readme and specs tests

##0.4.1 (02/14/2013)
* named classes

##0.4.0 (02/13/2013)
* __init can either be a table or a function
* Added the abitlity to turn classes and objects into strings.

##0.3.0 (09/01/13)
* Added Class-Commons support (Thanks to [TsT2005](https://github.com/tst2005))
* Added Tracis-CI validation
* Updated Readme with chained initialization sample
* Updated specs

##0.2.1 (10/31/12)
* Added specs

##0.2.1 (10/04/12)
* Added local shortcuts to global functions internally used
* Typo fix in Readme's snippets

##0.2 (08/28/12)
* Now returns a local function when required. No longer pollutes the global env.
* Some code compression, to meet with the **30lines** rule!
* Added version history.
* Updated Readme

##0.1 (08/25/12)
* Initial Release
