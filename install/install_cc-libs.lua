-- This file is a combination of tar library and download script to keep
-- everything in a single file. Changes have been made to the tar library for
-- compatibility with ComputerCraft.

-- Tar extraction module based off LUARocks : github.com/keplerproject/luarocks
-- By Danny @ anscamobile
--
-- Restored directory creation
-- Handles space-padded numbers, e.g. in the size field, so it can handle a TAR file
-- created by the OS X UNIX tar.
--
-- By David Gross

-- Sample code is MIT licensed -- Copyright (C) 2011 InfusedDreams. All Rights Reserved.

-- This is replaced with the fs package provided by ComputerCraft
-- -- Lua File System
-- local lfs = require "lfs"

local blocksize = 512
local _ceil = math.ceil
local _tonumber = tonumber
local _ioOpen = io.open
local byte = string.byte

-- trim5 from http://lua-users.org/wiki/StringTrim
local function trim(s)
    return s:match '^%s*(.*%S)' or ''
end

local function get_typeflag(flag)
    if flag == '0' or flag == '\0' then
        return 'file'
    elseif flag == '1' then
        return 'link'
    elseif flag == '2' then
        return 'symlink' -- "reserved" in POSIX, "symlink" in GNU
    elseif flag == '3' then
        return 'character'
    elseif flag == '4' then
        return 'block'
    elseif flag == '5' then
        return 'directory'
    elseif flag == '6' then
        return 'fifo'
    elseif flag == '7' then
        return 'contiguous' -- "reserved" in POSIX, "contiguous" in GNU
    elseif flag == 'x' then
        return 'next file'
    elseif flag == 'g' then
        return 'global extended header'
    elseif flag == 'L' then
        return 'long name'
    elseif flag == 'K' then
        return 'long link name'
    end
    return 'unknown'
end

local function octal_to_number(octal)
    local exp = 0
    local number = 0
    octal = trim(octal)
    for i = #octal, 1, -1 do
        local digit = _tonumber(octal:sub(i, i))
        if not digit then
            break
        end
        number = number + (digit * 8 ^ exp)
        exp = exp + 1
    end
    return number
end

--[[
It is correct that the checksum is the sum of the 512 header
bytes after filling the checksum field itself with spaces.
The checksum is then written as a string giving the *octal*
representation of the checksum. Maybe you forgot to convert
your hand computed sum to octal ??.
]]

local function checksum_header(block)
    local sum = 256
    for i = 1, 148 do
        sum = sum + block:byte(i)
    end
    for i = 157, 500 do
        sum = sum + block:byte(i)
    end
    return sum
end

local function nullterm(s)
    return s:match('^[^%z]*')
end

local function read_header_block(block)
    local header = {}
    header.name = nullterm(block:sub(1, 100))
    header.mode = nullterm(block:sub(101, 108))
    header.uid = octal_to_number(nullterm(block:sub(109, 116)))
    header.gid = octal_to_number(nullterm(block:sub(117, 124)))
    header.size = octal_to_number(nullterm(block:sub(125, 136)))
    header.mtime = octal_to_number(nullterm(block:sub(137, 148)))
    header.chksum = octal_to_number(nullterm(block:sub(149, 156)))
    header.typeflag = get_typeflag(block:sub(157, 157))
    header.linkname = nullterm(block:sub(158, 257))
    header.magic = block:sub(258, 263)
    header.version = block:sub(264, 265)
    header.uname = nullterm(block:sub(266, 297))
    header.gname = nullterm(block:sub(298, 329))
    header.devmajor = octal_to_number(nullterm(block:sub(330, 337)))
    header.devminor = octal_to_number(nullterm(block:sub(338, 345)))
    header.prefix = block:sub(346, 500)
    header.pad = block:sub(501, 512)
    if header.magic ~= 'ustar ' and header.magic ~= 'ustar\0' then
        return false, 'Invalid header magic ' .. header.magic
    end
    if header.version ~= '00' and header.version ~= ' \0' then
        return false, 'Unknown version ' .. header.version
    end
    if not checksum_header(block) == header.chksum then
        return false, 'Failed header checksum'
    end
    return header
end

local function untar(filePath, destdir, onComplete)
    local destPath = destdir or '.'

    local testForFile = _ioOpen(filePath, 'rb')

    if not testForFile then
        print('TAR ERROR : File Not Found, Please check the file exists in the path specified')
    end

    local tar_handle = _ioOpen(filePath, 'rb')
    if not tar_handle then
        return nil, 'Error opening file ' .. filePath
    end

    local long_name, long_link_name
    while true do
        local block

        -- Read a header
        repeat
            block = tar_handle:read(blocksize)
        until (not block) or checksum_header(block) > 256
        if not block then
            break
        end
        local header, err = read_header_block(block)
        assert(header, err)

        -- read entire file that follows header
        local file_data = tar_handle:read(_ceil(header.size / blocksize) * blocksize):sub(1, header.size)

        if header.typeflag == 'long name' then
            long_name = nullterm(file_data)
        elseif header.typeflag == 'long link name' then
            long_link_name = nullterm(file_data)
        else
            if long_name then
                header.name = long_name
                long_name = nil
            end
            if long_link_name then
                header.name = long_link_name
                long_link_name = nil
            end
        end

        local pathname

        if false then
            pathname = destPath .. '/' .. header.name
        else
            if destPath and string.sub(destPath, -1) ~= '/' then
                pathname = destPath .. '/' .. header.name
            else
                pathname = destPath .. header.name
            end
        end

        if header.typeflag == 'directory' then
            fs.makeDir(pathname)
        elseif header.typeflag == 'file' then
            -- print('Write to file ' .. pathname)
            local file_handle = _ioOpen(pathname, 'wb')
            assert(file_handle, 'Failed to open file ' .. pathname .. ' for writing')
            file_handle:write(file_data)
            file_handle:close()
        end
    end

    if onComplete then
        if type(onComplete) == 'function' then
            --print ("TAR COMPLETED...")
            onComplete()
        else
            print('TAR ERROR : OnComplete must be a function')
        end
    end

    return true
end

print('Downloading library from github')

local PACKAGE_URL = 'https://github.com/twh2898/cc-libs/releases/latest/download/cc-libs.tar'
local CHUNK_SIZE = 8192
local resp = assert(http.get(PACKAGE_URL), 'Failed to fetch package from github')
local tar_file = assert(io.open('cc-libs.tar', 'wb'), 'Failed to open tar file')

repeat
    local chunk = resp:read(CHUNK_SIZE)
    if chunk then
        tar_file:write(chunk)
    end
until chunk == nil

if fs.exists('cc-libs') then
    print('Download complete, Updating cc-libs')
else
    print('Download complete, Installing cc-libs')
end

local success, err = pcall(untar, 'cc-libs.tar', '_extract')

if not success then
    print('Failed to extract tar')
    error(err)
end

print('Extraction complete')

fs.delete('cc-libs')
fs.move('_extract/cc-libs', '.')
fs.delete('_extract')

print('Finished installing cc-libs')
