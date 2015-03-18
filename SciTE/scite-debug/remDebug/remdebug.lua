-- utility package loaded before the program to be debugged.
require"remdebug.engine"
-- Windows requires this for us to immediately see all output!
io.stdout:setvbuf("no")
remdebug.engine.start()

