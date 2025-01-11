--package.path = package.path.."../../LuaJIT-ImGui/cimgui/generator/?.lua"
package.path = package.path.."../../anima/LuaJIT-ImGui/cimgui/generator/?.lua"
local cp2c = require"cpp2ffi"
local parser = cp2c.Parser()

local defines = {}

cp2c.save_data("./outheader.h",[[#include <portaudio.h>
#include "pa_asio.h"]])

defines = parser:take_lines([[gcc -E -dD -I ../portaudio/ -I ../portaudio/include/ ./outheader.h]],{"portaudio.-","pa_asio.-"},"gcc")


os.remove"./outheader.h"

---------------------------
parser:do_parse()


local cdefs = {}
for i,it in ipairs(parser.itemsarr) do
	table.insert(cdefs,it.item)
end


local deftab = {}
---[[
local ffi = require"ffi"
ffi.cdef(table.concat(cdefs,""))
local wanted_strings = {"."}
for i,v in ipairs(defines) do
	local wanted = false
	for _,wan in ipairs(wanted_strings) do
		if (v[1]):match(wan) then wanted=true; break end
	end
	if wanted then
		local lin = "static const int "..v[1].." = " .. v[2] .. ";"
		local ok,msg = pcall(function() return ffi.cdef(lin) end)
		if not ok then
			print("skipping def",lin)
			print(msg)
		else
			table.insert(deftab,lin)
		end
	end
end
--]]


local portaudio_t_code = [[
ffi.cdef"typedef struct pa_type{} pa_type;"

local PaStream_t = {}
PaStream_t.__index = PaStream_t


function PaStream_t:CloseStream()
    ffi.gc(self,nil)
    return lib.Pa_CloseStream(self)
end

]]
cp2c.table_do_sorted(parser.defsT, function(k,v)
--for k,v in pairs(parser.defsT) do
	if v[1].argsT[1] then
		if v[1].argsT[1].type:match("PaStream") and v[1].funcname~="Pa_OpenStream" and v[1].funcname~="Pa_OpenDefaultStream" and v[1].funcname~="Pa_CloseStream"
		then 
			--print(v[1].funcname,v[1].signature) 
			local cname = v[1].funcname:gsub("Pa_","")
			local code = "\nfunction PaStream_t:"..cname.."("
			local codeargs = ""
			for i=2,#v[1].argsT do
				codeargs = codeargs..v[1].argsT[i].name..", "
			end
			codeargs = codeargs:gsub(", $","") --delete last comma
			code = code..codeargs..")\n"
			local retcode = "lib."..v[1].funcname.."(self"
			if #codeargs==0 then
				retcode = retcode ..")"
			else
				retcode = retcode..","..codeargs..")"
			end
			if v[1].ret:match("char") then
				retcode = "    local ret = "..retcode
				retcode = retcode.."\n    if ret==nil then return nil else return ffi.string(ret) end"
			else
				retcode = "    return "..retcode
			end
			code = code .. retcode.. "\nend"
			portaudio_t_code = portaudio_t_code..code
		end
	end
--end
end)
portaudio_t_code = portaudio_t_code..[[

M.Pa = ffi.metatype("pa_type",PaStream_t)

]]


local sdlstr = [[
local ffi = require"ffi"

--uncomment to debug cdef calls]]..
"\n---[["..[[

local ffi_cdef = function(code)
    local ret,err = pcall(ffi.cdef,code)
    if not ret then
        local lineN = 1
        for line in code:gmatch("([^\n\r]*)\r?\n") do
            print(lineN, line)
            lineN = lineN + 1
        end
        print(err)
        error"bad cdef"
    end
end
]].."--]]"..[[

ffi_cdef]].."[["..table.concat(cdefs,"").."]]"..[[

ffi_cdef]].."[["..table.concat(deftab,"\n").."]]"..[[

local lib = ffi.load"portaudio"

local M = {C=lib}]]..portaudio_t_code..[=[

function M.OpenDefaultStream(numInputChannels, numOutputChannels, sampleFormat, sampleRate, framesPerBuffer, streamCallback, userData)
    local stream = ffi.new("PaStream*[1]")
    local err = lib.Pa_OpenDefaultStream(stream,numInputChannels, numOutputChannels, sampleFormat, sampleRate, framesPerBuffer, streamCallback, userData)
    if not(err == lib.paNoError) then 
        return nil, err, string.format("error: %s",ffi.string(lib.Pa_GetErrorText(err)))
    end
    local st = ffi.new("pa_type*",stream[0])
    ffi.gc(st,lib.Pa_CloseStream)
    return st
end
function M.OpenStream(inputParameters, outputParameters, sampleRate, framesPerBuffer, streamFlags, streamCallback, userData)
    local stream = ffi.new("PaStream*[1]")
    local err = lib.Pa_OpenStream(stream,inputParameters, outputParameters, sampleRate, framesPerBuffer, streamFlags, streamCallback, userData)
    if not(err == lib.paNoError) then 
        return nil, err, string.format("error: %s",ffi.string(lib.Pa_GetErrorText(err)))
    end
    local st = ffi.new("pa_type*",stream[0])
    ffi.gc(st,lib.Pa_CloseStream)
    return st
end


local callback_t
local callbacks_anchor = {}
function M.MakeAudioCallback(func, ...)
	if not callback_t then
		local CallbackFactory = require "lj-async.callback"
		callback_t = CallbackFactory("int(*)(void*,void*,unsigned long,PaStreamCallbackTimeInfo*,PaStreamCallbackFlags,void*)") --"RtAudioCallback"
	end
	local cb = callback_t(func, ...)
	table.insert(callbacks_anchor,cb)
	return cb:funcptr() , cb
end



setmetatable(M,{
__index = function(t,k)
	local ok,ptr = pcall(function(str) return lib["Pa_"..str] end,k)
	if not ok then ok,ptr = pcall(function(str) return lib["pa"..str] end,k) end 
	if not ok then error(k.." not found") end
	rawset(M, k, ptr)
	return ptr
end
})


return M
]=]

cp2c.save_data("./portaudio_ffi.lua",sdlstr)
cp2c.copyfile("./portaudio_ffi.lua","../portaudio_ffi.lua")

