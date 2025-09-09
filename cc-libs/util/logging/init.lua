local log_formatter = require 'cc-libs.util.logging.formatter'
local log_handler = require 'cc-libs.util.logging.handler'
local log_level = require 'cc-libs.util.logging.level'
local log_logger = require 'cc-libs.util.logging.logger'
local log_stream = require 'cc-libs.util.logging.stream'

local ROOT_LOGGER_NAME = 'root'

local M = {
    Formatter = log_formatter.Formatter,
    Record = log_formatter.Record,
    ShortFormatter = log_formatter.ShortFormatter,
    LongFormatter = log_formatter.LongFormatter,
    JsonFormatter = log_formatter.JsonFormatter,
    Handler = log_handler.Handler,
    ConsoleStream = log_stream.ConsoleStream,
    FileStream = log_stream.FileStream,
    RemoteStream = log_stream.RemoteStream,
    Level = log_level.Level,
    level_name = log_level.level_name,
    level_from_name = log_level.level_from_name,
    Logger = log_logger.Logger,
    subsystems = {},
}

---Get the logger object for the give subsystem name
---@param subsystem? string name of the subsystem
---@return Logger
function M.get_logger(subsystem)
    subsystem = subsystem or ROOT_LOGGER_NAME
    local exists = M.subsystems[subsystem]
    if exists == nil then
        exists = log_logger.Logger:new(subsystem)
        if subsystem ~= ROOT_LOGGER_NAME then
            exists.parent = M.get_logger(ROOT_LOGGER_NAME)
        end
        M.subsystems[subsystem] = exists
    end
    return exists
end

---@class BasicConfigArgs
---@field level? number|LogLevel
---@field file_level? number|LogLevel
---@field filepath? string
---@field machine_level? number|LogLevel
---@field machine_filepath? string
---@field remote_enabled? boolean
---@field remote_level? number|LogLevel
---@field force? boolean

---Setup root logger and default handlers
---@param args? BasicConfigArgs
function M.basic_config(args)
    args = args or {}
    if M.subsystems[ROOT_LOGGER_NAME] ~= nil then
        if args.force then
            M.subsystems[ROOT_LOGGER_NAME].handlers = {}
        else
            return
        end
    end
    local level = args.level or M.Level.INFO
    M.root = M.get_logger(ROOT_LOGGER_NAME)
    M.root:new_handler(M.ShortFormatter:new(), M.ConsoleStream:new(level))
    if args.filepath then
        local file_level = args.file_level or M.Level.DEBUG
        M.root:new_handler(M.LongFormatter:new(), M.FileStream:new(args.filepath, file_level))
    end
    if args.machine_filepath then
        local machine_level = args.machine_level or M.Level.TRACE
        M.root:new_handler(M.JsonFormatter:new(), M.FileStream:new(args.machine_filepath, machine_level))
    end
    if args.remote_enabled then
        local remote_level = args.remote_level or M.Level.DEBUG
        M.root:new_handler(M.JsonFormatter:new(), M.RemoteStream:new(remote_level))
    end
end

return M
