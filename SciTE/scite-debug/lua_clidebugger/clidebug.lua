-- utility package loaded before the program to be debugged.
require"debugger"
-- Windows requires this for us to immediately see all output!
io.stdout:setvbuf("no")
pause('debug')
