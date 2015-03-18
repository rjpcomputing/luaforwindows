local function b(x, suffix)
   local v, ontrue, onfalse = mlp.gensym "test", unpack (suffix)
   return `Stat{ 
      +{ block:
         local -{v}
         if -{x} then (-{v}) = -{ontrue} else (-{v}) = -{onfalse or `Nil} end },
      v }
end

mlp.expr.suffix:add{ "?", mlp.expr, gg.onkeyword{ ",", mlp.expr }, prec=5, builder=b }
