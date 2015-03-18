-{ extension "types" }
-{ extension "clist" }

-- Uncomment this to turn typechecking code generation off:
-- -{stat: types.enabled=false}

function sum (x :: table(number)) :: number
   local acc :: number = 0
   for i=1, #x do
      acc = acc + x[i] -- .. 'x' -- converts to string
   end
   --acc='bug' -- put a string in a number variable
   return acc
end

x       = { i for i=1,100 }
--x[23] = 'toto' -- string in a number list, sum() will complain
y       = sum (x)
printf ("sum 1 .. %i = %i", #x, y)