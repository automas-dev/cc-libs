local json = require 'cc-libs.util.json'

---@class CoverageEntry
---@field hits table<number, number>
---@field total_lines number
---@field executable_lines number[]

---@class CoverageState
---@field enabled boolean
---@field data table<string, CoverageEntry>
---@field in_hook boolean

---@class CoverageReportFile
---@field path string
---@field line_count number
---@field covered_lines number
---@field missed_lines number[]
---@field coverage number

---@class CoverageReportSummary
---@field files CoverageReportFile[]
---@field total_lines number
---@field covered_lines number
---@field coverage number

local M = {}

---@param path? string
---@return string?
function M.normalize_coverage_path(path)
    if not path then
        return nil
    end

    local normalized = path:gsub('^@', '')

    while normalized:sub(1, 2) == './' do
        normalized = normalized:sub(3)
    end
    while normalized:sub(1, 3) == '../' do
        normalized = normalized:sub(4)
    end

    local cc_prefix = normalized:find('cc%-libs/')
    if not cc_prefix then
        cc_prefix = normalized:find('cc%-apps/')
    end
    if cc_prefix then
        normalized = normalized:sub(cc_prefix)
    end

    if normalized:sub(1, 8) == 'cc-libs/' or normalized:sub(1, 8) == 'cc-apps/' then
        return normalized
    end

    return nil
end

---@param path? string
---@return string?
function M.resolve_coverage_path(path)
    local normalized = M.normalize_coverage_path(path)
    if not normalized then
        return nil
    end

    local candidates = {
        normalized,
        './' .. normalized,
        '../' .. normalized,
    }

    for _, candidate in ipairs(candidates) do
        local file = io.open(candidate, 'r')
        if file and type(file.close) == 'function' then
            file:close()
            return candidate
        end
    end

    return nil
end

---@param path string|nil
---@return boolean
function M.is_coverage_target(path)
    local normalized = M.normalize_coverage_path(path)
    if not normalized then
        return false
    end

    return normalized:sub(1, 8) == 'cc-libs/' or normalized:sub(1, 8) == 'cc-apps/'
end

---@param line string|nil
---@return boolean
function M.should_count_coverage_line(line)
    if not line then
        return false
    end

    local content = line
    local comment_pos = content:find('%-%-')
    if comment_pos then
        content = content:sub(1, comment_pos - 1)
    end

    local trimmed = content:gsub('^%s+', '')
    trimmed = trimmed:gsub('%s+$', '')
    if trimmed == '' then
        return false
    end

    return true
end

---@param path string
---@return number[]
function M.get_executable_lines(path)
    local file = io.open(path, 'r')
    if not file then
        return {}
    end

    local executable_lines = {}
    local line_number = 0
    for line in file:lines() do
        line_number = line_number + 1
        if M.should_count_coverage_line(line) then
            table.insert(executable_lines, line_number)
        end
    end
    file:close()

    return executable_lines
end

---@param path string
---@return number
function M.count_coverage_lines(path)
    local executable_lines = M.get_executable_lines(path)
    return #executable_lines
end

---@param enabled boolean?
---@return CoverageState
function M.new_state(enabled)
    return {
        enabled = enabled ~= false,
        data = {},
        in_hook = false,
    }
end

---@param state CoverageState
---@param source string
---@return CoverageEntry|nil
function M.ensure_coverage_entry(state, source)
    local normalized = M.normalize_coverage_path(source)
    if not normalized or not M.is_coverage_target(normalized) then
        return nil
    end

    local entry = state.data[normalized]
    if not entry then
        local resolved_path = M.resolve_coverage_path(source)
        local executable_lines = M.get_executable_lines(resolved_path or normalized)
        entry = {
            hits = {},
            total_lines = #executable_lines,
            executable_lines = executable_lines,
        }
        state.data[normalized] = entry
    end

    return entry
end

---@param state CoverageState
---@param source string
---@param line number|string
function M.record_coverage_line(state, source, line)
    if not state.enabled or not line or line <= 0 then
        return
    end

    local entry = M.ensure_coverage_entry(state, source)
    if not entry then
        return
    end

    local line_number = tonumber(line)
    if not line_number or line_number <= 0 then
        return
    end

    local file = M.resolve_coverage_path(source)
    if not file then
        return
    end

    local executable_lines = entry.executable_lines or {}
    local is_executable_line = false
    for _, executable_line in ipairs(executable_lines) do
        if executable_line == line_number then
            is_executable_line = true
            break
        end
    end

    if is_executable_line then
        entry.hits[line_number] = (entry.hits[line_number] or 0) + 1
    end
end

---@param state CoverageState
---@param event string
---@param line number
---@param info table|nil
function M.coverage_hook(state, event, line, info)
    if event ~= 'line' or state.in_hook then
        return
    end

    state.in_hook = true

    if not info then
        info = debug.getinfo(2, 'Sl')
    end
    if info then
        M.record_coverage_line(state, info.source, line)
    end

    state.in_hook = false
end

---@param state CoverageState
function M.start_coverage(state)
    if state.enabled then
        debug.sethook(function(event, line)
            local info = debug.getinfo(2, 'Sl')
            M.coverage_hook(state, event, line, info)
        end, 'l')
    end
end

---@param state CoverageState
function M.stop_coverage(state)
    if state.enabled then
        debug.sethook()
    end
end

---@param state CoverageState
---@return CoverageReportSummary
function M.write_coverage_report(state)
    local files = {}
    local total_lines = 0
    local covered_lines = 0

    for path, entry in pairs(state.data) do
        local missed_lines = {}
        local line_count = entry.total_lines or 0
        local covered_count = 0

        local executable_lines = entry.executable_lines or {}
        for _, line in ipairs(executable_lines) do
            if entry.hits[line] then
                covered_count = covered_count + 1
            else
                table.insert(missed_lines, line)
            end
        end

        total_lines = total_lines + line_count
        covered_lines = covered_lines + covered_count

        table.insert(files, {
            path = path,
            line_count = line_count,
            covered_lines = covered_count,
            missed_lines = missed_lines,
            coverage = line_count > 0 and (100 * covered_count / line_count) or 100,
        })
    end

    table.sort(files, function(lhs, rhs)
        return lhs.path < rhs.path
    end)

    local summary = {
        files = files,
        total_lines = total_lines,
        covered_lines = covered_lines,
        coverage = total_lines > 0 and (100 * covered_lines / total_lines) or 100,
    }

    local coverage_file = io.open('coverage_report.json', 'w')
    if coverage_file then
        coverage_file:write(json.encode(summary))
        coverage_file:close()
    end

    return summary
end

---Print a table
---@param columns string[] column names
---@param rows string[][] rows of values
local function print_table(columns, rows)
    local col_len = {}
    for i = 1, #columns do
        col_len[i] = #columns[i]
    end
    for _, row in ipairs(rows) do
        for i = 1, #columns do
            local val_len = #tostring(row[i])
            if col_len[i] < val_len then
                col_len[i] = val_len
            end
        end
    end
    local function print_row(row)
        local cells = {}
        for i = 1, #row do
            if i == 1 then
                table.insert(cells, string.format('%-' .. col_len[i] .. 's', tostring(row[i])))
            else
                table.insert(cells, string.format('%-' .. col_len[i] .. 's', tostring(row[i])))
            end
        end
        print('| ' .. table.concat(cells, ' | ') .. ' |')
    end
    print_row(columns)
    local div = {}
    for i, count in ipairs(col_len) do
        div[i] = string.rep('-', count)
    end
    print_row(div)
    for _, row in ipairs(rows) do
        print_row(row)
    end
end

---@param missing_lines number[]
---@return string
local function format_missing(missing_lines)
    local str_arr = {}
    local last_start = 1
    for i in ipairs(missing_lines) do
        if i == 1 then
            if missing_lines[i + 1] ~= missing_lines[i] + 1 then
                table.insert(str_arr, tostring(missing_lines[i]))
                last_start = 2
            end
        else
            if missing_lines[i] ~= missing_lines[i - 1] + 1 then
                if i == last_start then
                    table.insert(str_arr, tostring(missing_lines[i]))
                else
                    table.insert(
                        str_arr,
                        table.concat({
                            tostring(missing_lines[last_start]),
                            tostring(missing_lines[i]),
                        }, '-')
                    )
                end
            end
        end
    end
    if #missing_lines >= last_start then
        table.insert(str_arr, missing_lines[#missing_lines])
    end
    local res = table.concat(str_arr, ', ')
    local max_width = 40
    if #res > max_width then
        res = res:sub(1, max_width - 3) .. '...'
    end
    return res
end

function M.print_coverage_table(coverage_summary)
    local rows = {}
    for _, f in ipairs(coverage_summary.files) do
        local cov_perc = 0
        if f.line_count > 0 then
            cov_perc = f.covered_lines / f.line_count
        end
        table.insert(rows, {
            f.path,
            f.covered_lines,
            f.line_count,
            tostring(math.floor(cov_perc * 10000) / 100) .. '%',
            format_missing(f.missed_lines),
        })
    end
    print_table({ 'path', 'covered', 'total', 'coverage', 'missing' }, rows)
end

return M
