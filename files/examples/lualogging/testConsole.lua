require"logging.console"

local logger = logging.console()

logger:info("logging.console test")
logger:debug("debugging...")
logger:error("error!")
logger:debug("string with %4")
print("Console Logging OK")