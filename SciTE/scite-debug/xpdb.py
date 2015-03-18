# A modified main pdb debugger loop (see pdb.py in the Python library!)
from pdb import *
import sys,os,traceback

def main():
    mainpyfile =  sys.argv[1]     # Get script filename
    if not os.path.exists(mainpyfile):
        print 'Error:', mainpyfile, 'does not exist'
        sys.exit(1)

    del sys.argv[0]         # Hide "pdb.py" from argument list
    # Replace pdb's dir with script's dir in front of module search path.
    sys.path[0] = os.path.dirname(mainpyfile)

    pdb = Pdb()
    # 1st customization: prompt w/ a line feed!
    pdb.prompt = '(PDB)\n'
    # 2nd customization: not an infinite loop!
    try:
        pdb._runscript(mainpyfile)
        if pdb._user_requested_quit:
            return
        print "The program finished and will not be restarted"
    except SystemExit:
        # In most cases SystemExit does not warrant a post-mortem session.
        print "The program exited via sys.exit(). Exit status: ",
        print sys.exc_info()[1]
    except:
        traceback.print_exc()
        print "Uncaught exception. Entering post mortem debugging"
        t = sys.exc_info()[2]
        while t.tb_next is not None:
            t = t.tb_next
        pdb.interaction(t.tb_frame,t)


# When invoked as main program, invoke the debugger on a script
if __name__=='__main__':
    main()
	# under Windows, we need to run Python w/ the -i flag; this ensures that we die!
    sys.exit(0)

