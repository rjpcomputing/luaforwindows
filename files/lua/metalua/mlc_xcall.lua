-- lua -l mlc_xcall -e 'luafile_to_astfile ("/tmp/tmp12345.lua", "/tmp/tmp54321.ast")'
-- lua -l mlc_xcall -e 'lua_to_astfile ("/tmp/tmp54321.ast")'

mlc_xcall = { }

function mlc_xcall.server (luafilename, astfilename)

   -- We don't want these to be loaded when people only do client-side business
   require 'metalua.compiler'
   require 'serialize'

   -- compile the content of luafile name in an AST, serialized in astfilename
   local ast = mlc.luafile_to_ast (luafilename)
   local out = io.open (astfilename, 'w')
   out:write (serialize (ast))
   out:close ()
end

function mlc_xcall.client_file (luafile)

   --printf("\n\nmlc_xcall.client_file(%q)\n\n", luafile)

   local tmpfilename = os.tmpname()
   local cmd = string.format ([[lua -l metalua.mlc_xcall -e "mlc_xcall.server('%s', '%s')"]], 
			      luafile :gsub ([[\]], [[\\]]), 
			      tmpfilename :gsub([[\]], [[\\]]))

   --printf("os.execute [[%s]]\n\n", cmd)

   local ret = os.execute (cmd)
   if ret~=0 then error "xcall failure. FIXME: transmit failure and backtrace" end
   local ast = (lua_loadfile or loadfile) (tmpfilename) ()
   os.remove(tmpfilename)
   return true, ast
end

function mlc_xcall.client_literal (luasrc)
   local srcfilename = os.tmpname()
   local srcfile, msg = io.open (srcfilename, 'w')
   if not srcfile then print(msg) end
   srcfile :write (luasrc)
   srcfile :close ()
   local status, ast = mlc_xcall.client_file (srcfilename)
   os.remove(srcfilename)
   return status, ast
end

return mlc_xcall