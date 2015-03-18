require 'pl'
asserteq = require 'pl.test'.asserteq

function testconfig(test,tbl,cfg)
    local f = stringio.open(test)
    local c = config.read(f,cfg)
    f:close()
    if not tbl then
        print(pretty.write(c))
    else
        asserteq(c,tbl)
    end
end

testconfig ([[
 ; comment 2 (an ini file)
[section!]
bonzo.dog=20,30
config_parm=here we go again
depth = 2
[another]
felix="cat"
]],{
  section_ = {
    bonzo_dog = { -- comma-sep values get split by default
      20,
      30
    },
    depth = 2,
    config_parm = "here we go again"
  },
  another = {
    felix = "\"cat\""
  }
})


testconfig ([[
# this is a more Unix-y config file
fred = 1
alice = 2
home.dog = /bonzo/dog/etc
]],{
  home_dog = "/bonzo/dog/etc",  -- note the default is {variablilize = true}
  fred = 1,
  alice = 2
})

-- backspace line continuation works, thanks to config.lines function
testconfig ([[
foo=frodo,a,c,d, \
  frank, alice, boyo
]],
{
  foo = {
    "frodo",
    "a",
    "c",
    "d",
    "frank",
    "alice",
    "boyo"
  }
}
)

------ options to control default behaviour -----

-- want to keep key names as is!
testconfig ([[
alpha.dog=10
# comment here
]],{
    ["alpha.dog"]=10
},{variabilize=false})

-- don't convert strings to numbers
testconfig ([[
alpha.dog=10
; comment here
]],{
    alpha_dog="10"
},{convert_numbers=false})

-- don't split comma-lists by setting the list delimiter to something else
testconfig ([[
extra=10,'hello',42
]],{
    extra="10,'hello',42"
},{list_delim='@'})

-- Unix-style password file
testconfig([[
lp:x:7:7:lp:/var/spool/lpd:/bin/sh
mail:x:8:8:mail:/var/mail:/bin/sh
news:x:9:9:news:/var/spool/news:/bin/sh
]],
{
  {
    "lp",
    "x",
    7,
    7,
    "lp",
    "/var/spool/lpd",
    "/bin/sh"
  },
  {
    "mail",
    "x",
    8,
    8,
    "mail",
    "/var/mail",
    "/bin/sh"
  },
  {
    "news",
    "x",
    9,
    9,
    "news",
    "/var/spool/news",
    "/bin/sh"
  }
},
{list_delim=':'})

-- Unix updatedb.conf is in shell script form, but config.read
-- copes by extracting the variables as keys and the export
-- commands as the array part; there is an option to remove quotes
-- from values
testconfig([[
# Global options for invocations of find(1)
FINDOPTIONS='-ignore_readdir_race'
export FINDOPTIONS
]],{
  "export FINDOPTIONS",
  FINDOPTIONS = "-ignore_readdir_race"
},{trim_quotes=true})

-- Unix fstab format. No key/value assignments so use `ignore_assign`;
-- list values are separated by a number of spaces
testconfig([[
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults        0       0
/dev/sda1       /               ext3    defaults,errors=remount-ro 0       1
]],
{
  {
    "proc",
    "/proc",
    "proc",
    "defaults",
    0,
    0
  },
  {
    "/dev/sda1",
    "/",
    "ext3",
    "defaults,errors=remount-ro",
    0,
    1
  }
},
{list_delim='%s+',ignore_assign=true}
)


-- altho this works, rather use pl.data.read for this kind of purpose.
testconfig ([[
# this is just a set of comma-separated values
1000,444,222
44,555,224
]],{
  {
    1000,
    444,
    222
  },
  {
    44,
    555,
    224
  }
})



