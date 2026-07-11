---@meta

-- These are all the globals being defined in kernel.lua, process.lua, etc.

---Get the current process id
---@return number pid
function os.getPid() end

---Get this process struct from within the process
---@return Process process the current process
function os.getCurrentProcess() end

---Get a process from it's process id
---@param pid number the process id
---@return Process? proc the process for pid if it exists
function os.getProcess(pid) end

---Open a new process
---@param cmd string command and arguments as a single string
---@return number? pid the child process id or nil for error
function os.popen(cmd) end

---Wait for a process to finish
---@param pid number the process id
function os.waitPid(pid) end

---Get the current working directory
---@return string path absolute path to current directory
function os.getCwd() end

---Change working directory to path
---@param path string absolute or relative path
function os.chdir(path) end

-- Defined empty here so the fields in kernel.lua will be visible in other files
kernel = {}
