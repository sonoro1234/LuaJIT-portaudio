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

local LUAFUNCS = ""

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
			LUAFUNCS = LUAFUNCS..code
		end
	end
--end
end)


local template = cp2c.read_data("./template.lua")
local CDEFS = table.concat(cdefs,"")
local DEFINES = "\n"..table.concat(deftab,"\n")

template = template:gsub("CDEFS",CDEFS)
template = template:gsub("DEFINES",DEFINES)
template = template:gsub("LUAFUNCS",LUAFUNCS)

cp2c.save_data("./portaudio_ffi.lua",template)
cp2c.copyfile("./portaudio_ffi.lua","../portaudio_ffi.lua")

