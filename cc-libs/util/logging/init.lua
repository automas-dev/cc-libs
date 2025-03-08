local log_formatter = require 'cc-libs.util.logging.formatter'
local log_handler = require 'cc-libs.util.logging.handler'
local log_level = require 'cc-libs.util.logging.level'
local log_logger = require 'cc-libs.util.logging.logger'

local M = {
    Formatter = log_formatter.Formatter,
    Record = log_formatter.Record,
    ShortFormatter = log_formatter.ShortFormatter,
    LongFormatter = log_formatter.LongFormatter,
    JsonFormatter = log_formatter.JsonFormatter,
    Handler = log_handler.Handler,
    Level = log_level.Level,
    level_name = log_level.level_name,
    level_from_name = log_level.level_from_name,
    Logger = log_logger.Logger,
}

local subsystems = {}

---Get the logger object for the give subsystem name
---@param subsystem string name of the subsystem
---@return Logger
function M.get_logger(subsystem)
    local exists = subsystems[subsystem]
    if exists == nil then
        exists = log_logger.Logger:new(subsystem)
        subsystems[subsystem] = exists
    end
    return exists
end

return M
