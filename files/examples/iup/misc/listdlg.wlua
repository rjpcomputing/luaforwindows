require 'iuplua'

local options = {'yellow','green','blue','red'}
res = iup.ListDialog( 1, "Which color?", #options, options, 2, 0, 0 )

iup.Message('ListDialog',res)

