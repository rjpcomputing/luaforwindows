require"logging.email"

local logger = logging.email {
                               rcpt = "mail@host.com",
                               from = "mail@host.com",
                               { 
                                 subject = "[%level] logging.email test", 
                               }, -- headers
}

logger:info("logging.sql test")
logger:debug("debugging...")
logger:error("error!")

print("Mail Logging OK")