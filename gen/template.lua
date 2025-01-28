local ffi = require"ffi"

--uncomment to debug cdef calls]]..
---[[

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
--]]

ffi_cdef[[CDEFS]]

ffi_cdef[[DEFINES]]

local lib = ffi.load"portaudio"

local M = {C=lib}

ffi.cdef"typedef struct pa_type{} pa_type;"

local PaStream_t = {}
PaStream_t.__index = PaStream_t

function PaStream_t:CloseStream()
    ffi.gc(self,nil)
    return lib.Pa_CloseStream(self)
end

LUAFUNCS

M.Pa = ffi.metatype("pa_type",PaStream_t)

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

function M.GetAllInfo()
	local Pa = M
	local I = {DEVS = {}}
	local numDevices = Pa.GetDeviceCount();
	for i=0,numDevices-1 do
		local deviceInfo = Pa.GetDeviceInfo( i );
		local hostInfo = Pa.GetHostApiInfo( deviceInfo.hostApi )
		I.DEVS[i] = {}
		I.DEVS[i].name = ffi.string(deviceInfo.name)
		I.DEVS[i].API = ffi.string(hostInfo.name)
		I.DEVS[i].inputs = deviceInfo.maxInputChannels
		I.DEVS[i].outputs = deviceInfo.maxOutputChannels
		I.DEVS[i].low_input_latency = deviceInfo.defaultLowInputLatency 
		I.DEVS[i].low_output_latency = deviceInfo.defaultLowOutputLatency
		I.DEVS[i].hight_input_latency = deviceInfo.defaultHighInputLatency
		I.DEVS[i].hight_output_latency = deviceInfo.defaultHighOutputLatency
		I.DEVS[i].is_default_input = (i == Pa.GetDefaultInputDevice()) or nil
		I.DEVS[i].is_default_output = (i == Pa.GetDefaultOutputDevice()) or nil
		I.DEVS[i].is_default_api_input = (i == hostInfo.defaultInputDevice) or nil
		I.DEVS[i].is_default_api_output = (i == hostInfo.defaultOutputDevice) or nil
		if hostInfo.type == Pa.ASIO then
			local minLatency, maxLatency, preferredLatency, granularity = ffi.new("long[1]"),ffi.new("long[1]"),ffi.new("long[1]"),ffi.new("long[1]")
			local err = Pa.C.PaAsio_GetAvailableBufferSizes( i, minLatency, maxLatency, preferredLatency, granularity );
			assert(err==Pa.NoError)
			I.DEVS[i].minbuff = minLatency[0]
			I.DEVS[i].maxbuff = maxLatency[0]
			I.DEVS[i].bestbuff = preferredLatency[0]
			I.DEVS[i].granularity = (granularity[0] == -1 ) and "power of 2" or granularity[0]
		end
	end
		---get output devices
    local out_devices = {names = {}, devID = {}}
    for j=0,#I.DEVS do
            local dev = I.DEVS[j]
            if dev.outputs > 0 then
                table.insert(out_devices.names , dev.name)
                table.insert(out_devices.devID , j)
            end
    end
    --no device
    if #out_devices.names == 0 then
            table.insert(out_devices.names , "none")
            table.insert(out_devices.devID , -1)
    end
	I.out_devices = out_devices
	return I
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