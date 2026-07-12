local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('journal')

local str = require 'cc-libs.util.string'

---@class Journal
---@field file_path string
---@field journal_path string
---@field file ccTweaked.fs.WriteHandle
local Journal = {}

local function recover_journal(file_path, journal_path)
    log:warning('Journal file', journal_path, 'exists for file', file_path, 'recovering file content')
    local journal = fs.open(journal_path, 'r')
    assert(journal ~= nil, 'failed to open journal ' .. journal_path)

    local journal_content = journal.readAll()
    journal.close()
    assert(journal_content ~= nil, 'failed to read journal ' .. journal_path)
    log:debug('Got', #journal_content, 'characters from journal', journal_path)

    local file = fs.open(file_path, 'r')
    assert(file ~= nil, 'failed to open ' .. file_path .. ' for read')

    local file_content = file.readAll()
    assert(file_content ~= nil, 'failed to read ' .. file_path)
    file.close()
    log:debug('Got', #file_content, 'characters from', file_path)

    if not str.ends_with(file_content, journal_content) then
        log:debug('File does not end with journal content, appending content')
        file = fs.open(file_path, 'a')
        assert(file ~= nil, 'failed to open ' .. file_path .. ' for write')
        file.write(journal_content)
        log:debug('Finished appending', #journal_content, 'characters to', file_path)
        file.close()
    else
        log:debug('File already contains contents from journal, ignoring journal file')
    end
    os.remove(journal_path)
    log:debug('Removed journal file', journal_path)
end

---Open a file to write with journal
---@param file_path string
---@return Journal
function Journal:new(file_path, mode)
    local journal_path = file_path .. '.journal'

    if fs.exists(journal_path) then
        recover_journal(file_path, journal_path)
    end

    local o = {
        file_path = file_path,
        journal_path = journal_path,
        mode = mode,
        file = fs.open(file_path, mode),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Journal:write(value)
    local journal = fs.open(self.journal_path, 'w')
    assert(journal ~= nil)
    journal.write(value)
    journal.close()
    self.file.write(value)
    os.remove(self.journal_path)
end

return {
    Journal = Journal,
}
