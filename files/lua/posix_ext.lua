-- Additions to the posix module (of luaposix).
module ("posix", package.seeall)


--- Run a program like <code>os.system</code>, but without a shell.
-- @param file filename of program to run
-- @param ... arguments to the program
-- @return status exit code, or nil if fork or wait fails
-- @return error message, or exit type if wait succeeds
function system (file, ...)
  local pid = fork ()
  if pid == 0 then
    return execp (file, ...)
  else
    local pid, reason, status = wait (pid)
    return status, reason -- If wait failed, status is nil & reason is error
  end
end

--- Check permissions like <code>access</code>, but for euid.
-- Based on the glibc function of the same name. Does not always check
-- for read-only file system, text busy, etc., and does not work with
-- ACLs &c.
-- @param file file to check
-- @param mode checks to perform (as for access)
-- @return 0 if access allowed; <code>nil</code> otherwise (and errno is set)
function euidaccess (file, mode)
  local pid = getpid ()

  if pid.uid == pid.euid and pid.gid == pid.egid then
    -- If we are not set-uid or set-gid, access does the same.
    return access (file, mode)
  end

  local stats = stat (file)
  if not stats then
    return
  end

  -- The super-user can read and write any file, and execute any file
  -- that anyone can execute.
  if pid.euid == 0 and ((not string.match (mode, "x")) or
                      string.match (stats.st_mode, "x")) then
    return 0
  end

  -- Convert to simple list of modes.
  mode = string.gsub (mode, "[^rwx]", "")

  if mode == "" then
    return 0 -- The file exists.
  end

  -- Get the modes we need.
  local granted = stats.st_mode:sub (1, 3)
  if pid.euid == stats.st_uid then
    granted = stats.st_mode:sub (7, 9)
  elseif pid.egid == stats.st_gid or set.new (getgroups ()):member(stats.st_gid) then
    granted = stats.st_mode:sub (4, 6)
  end
  granted = string.gsub (granted, "[^rwx]", "")

  if string.gsub ("[^" .. granted .. "]", mode) == "" then
    return 0
  end
  set_errno (EACCESS)
end
