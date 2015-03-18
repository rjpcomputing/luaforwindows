-------------------------------------------------------------------------------
-- Copas - Coroutine Oriented Portable Asynchronous Services
-- 
-- Copas Wrapper for socket.http module
-- 
-- Written by Leonardo Godinho da Cunha
-------------------------------------------------------------------------------
require "copas"

module "copas.cosocket"

-- Meta information is public even begining with an "_"
_COPYRIGHT   = "Copyright (C) 2004-2006 Kepler Project"
_DESCRIPTION = "Coroutine Oriented Portable Asynchronous Services Wrapper for socket module"
_NAME        = "Copas.cosocket"
_VERSION     = "0.1"


function tcp ()
	skt=socket.tcp()
	w_skt_mt={__index = skt
	}
	ret_skt = setmetatable ({socket = skt}, w_skt_mt)
	ret_skt.settimeout = function (self,val)
				return self.socket:settimeout (val) 
			end 	
	ret_skt.connect = function (self,host, port)
				ret,err = copas.connect (self.socket,host, port)
				local d = copas.wrap(self.socket)

				self.send= function(client, data)
					local ret,val=d.send(client, data)
					return ret,val
				end
    				self.receive=d.receive
    				self.close = function (w_socket)
    					ret=w_socket.socket:close()
    					return ret
    				end
				return ret,err
			end 
	return  ret_skt
end
