             LuaTask 1.6.4 - "Multitasking" support Library
             ----------------------------------------------

THE IDEA:
---------

LuaTask implements a concurrent and independent Lua execution
environment model.

We choose the "task" name to avoid confusion with "lua threads".

The program calling luaopen_task() becomes the "main" task.

Each "task" started by the main one ( by calling task.create()), has an
independent lua state, own message queue and execution os thread.

Each task is represented by a number starting at 1 ( 1 is the main
task).

The internal task list grows as it is necessary.  Currently
there is no list size limit.


WIN32 THREADS
-------------

The first implementation ( and the current one selected with NATV_WIN32)
called the Win32 APIs direct from syncos.c and doesn't support cancel.
When I tried to implement the cancel method and after looking for
alternatives to the infame TerminateThread, I decided to use as an
option the Pthreads-Win32 library.
Pthreads-Win32 library (2.7.0) implements thread
cancellation with and without QueueUserAPCEx.
QueueUserAPCEx (by Panagiotis E. Hadjidoukas) is used for true async
cancelation of threads (including blocked threads).



DOCUMENTATION
-------------

Inside the doc directory you can find a manual and a reference guide.



AUTHORS:
--------

LuaTask have been developed by Daniel Quintela.
http://www.soongsoft.com      mailto:dq@soongsoft.com
