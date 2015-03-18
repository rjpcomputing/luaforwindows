require( "luacurl" )

c = curl.new() -- curl.new not found

-- Set the proxy if you need it.
--c:setopt( curl.OPT_PROXY,"myproxy.com:7777" )

c:setopt( curl.OPT_WRITEFUNCTION, function ( stream, buffer )
	if stream:write( buffer ) then
		return string.len( buffer )
	end
end);

c:setopt( curl.OPT_WRITEDATA, io.open( "lua-5.0.2.tar.gz", "wb" ) )

c:setopt( curl.OPT_PROGRESSFUNCTION, function ( _, dltotal, dlnow, uptotal, upnow )
	print( dltotal, dlnow, uptotal, upnow )
end )

c:setopt( curl.OPT_NOPROGRESS, false )

c:setopt( curl.OPT_HTTPHEADER, "Connection: Keep-Alive", "Accept-Language: en-us" )

c:setopt( curl.OPT_URL, "http://www.lua.org/ftp/lua-5.0.2.tar.gz" )
c:setopt( curl.OPT_CONNECTTIMEOUT, 15 )
c:perform()
c:close()
