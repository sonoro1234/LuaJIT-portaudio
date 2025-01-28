local igwin = require"imgui.window"
--local win = igwin:SDL(800,400, "audio sine")
local win = igwin:GLFW(800,400, "audio sine",{vsync=2})
local ig = win.ig
local igLOG = ig.Log()
local function printLOG(...)
	igLOG:Add(table.concat({...},", ").."\n")
end
local ffi = require"ffi"
local Pa = require"portaudio_ffi"
local err = Pa.Initialize()
assert(err==Pa.NoError)
-------------------------------------
local function AudioInit(udatacode)
	local ffi = require"ffi"
	local Pa = require"portaudio_ffi"
	local sin = math.sin
	ffi.cdef(udatacode)
	return function(inp, out, nFrames, timeInfo, statusFlags, ud )
		local buf = ffi.cast("float*",out)
		local udc = ffi.cast("MyUdata*",ud)
		for i=0,(2*nFrames)-2,2 do
			local sample = sin(udc.Phase)*0.01
			udc.Phase = udc.Phase + udc.dPhase
			buf[i] = sample
			buf[i+1] = sample
		end
		return Pa.Continue
	end
end

local udatacode = [[typedef struct {double Phase;double dPhase;} MyUdata]]
ffi.cdef(udatacode)
local ud = ffi.new"MyUdata"
local sampleHz = 44100
local function setFreq(ff)
    ud.dPhase = 2 * math.pi * ff / sampleHz
end

local thecallback = Pa.MakeAudioCallback(AudioInit,udatacode)

local auinf = Pa.GetAllInfo()
--local ocombos = auinf.out_combos(ig)
--local oAPI,odevice = auinf.first_out()
local dac
local odevice = 0
local SRcombo, BScombo

local function set_odev(dev)
	sampleHz = tonumber(SRcombo:get_name())
	local wantedBsiz = tonumber(BScombo:get_name())
    odevice = dev
    printLOG(odevice, sampleHz, wantedBsiz)
	--if dac close it
	if dac then 
		dac:StopStream(); 
		dac:CloseStream(); 
		dac = nil 
	end
	if odevice == -1 then return end --bad device
	local outputParameters = ffi.new("PaStreamParameters",{odevice, 2, Pa.Float32, 0, nil})
	outputParameters.suggestedLatency = Pa.GetDeviceInfo(outputParameters.device).defaultLowOutputLatency;
	printLOG(outputParameters.channelCount, "channesl",outputParameters.suggestedLatency)
	
	-- local outputParameters = ffi.new"PaStreamParameters"
	-- outputParameters.device = odevice --Pa.GetDefaultOutputDevice(); --/* default output device */
    -- if (outputParameters.device == Pa.NoDevice) then
        -- error("Error: No default output device.\n");
    -- end
    -- outputParameters.channelCount = 2       
    -- outputParameters.sampleFormat = Pa.Float32;-- /* 32 bit floating point output */
    -- outputParameters.suggestedLatency = Pa.GetDeviceInfo( outputParameters.device ).defaultLowOutputLatency;
    -- outputParameters.hostApiSpecificStreamInfo = nil;
	-- print("outdevice",outputParameters.device)
	-- local err = Pa.IsFormatSupported( nil, outputParameters, sampleHz );
	-- if( err == Pa.FormatIsSupported ) then print"supported" else print"unsupported" end
	
	local stream, err, errmsg = Pa.OpenStream(nil, outputParameters, sampleHz, wantedBsiz, Pa.ClipOff, thecallback, ud)
	print(stream, err, errmsg)
	if not stream then
		print("ERROR", errmsg)
		return 
	end
	dac = stream
	local streamInfo = Pa.GetStreamInfo( stream );
    printLOG( "out latency", streamInfo.outputLatency  );
	if dac:StartStream()~= Pa.NoError then
		printLOG("error in start_stream")--,ffi.string(lib.Pa.GetErrorText(err))))
	end
end

local function scandevices()
	auinf = Pa.GetAllInfo()
	--ocombos = auinf.out_combos(ig)
	--oAPI,odevice = auinf.first_out()
	if dac then dac:StopStream(); dac:CloseStream(); dac = nil end
end

local standardSampleRates = {
    8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
    44100.0, 48000.0, 88200.0, 96000.0, 192000.0}
for i,v in ipairs(standardSampleRates) do standardSampleRates[i] = tostring(v) end
SRcombo = ig.LuaCombo("SampleRate##in",standardSampleRates)
SRcombo:set_name("44100")

local bufsizes = {}
for i= 6,11 do table.insert(bufsizes, tostring(2^i)) end
BScombo = ig.LuaCombo("buffer size##in",bufsizes)
BScombo:set_name("512")

local DevCombo = ig.LuaCombo("devices", auinf.out_devices.names, function(val, id)
	odevice = auinf.out_devices.devID[id] ; printLOG(val,id)
end)


local counter = 0
function win:draw(ig)

	igLOG:Draw("log window")
	if ig.Button"scan devices" then
		scandevices()
	end
	
	DevCombo:draw()
	ig.Text("%s, %s, API:%s",tostring(odevice), auinf.DEVS[odevice].name, auinf.DEVS[odevice].API)
	
	SRcombo:draw()
	BScombo:draw()
	if ig.Button"reset device" then
		set_odev(odevice)
	end
	
    if counter==10 then
		setFreq(math.random()*500 + 100)
		counter = 0
	else counter = counter + 1 end
end

win:start()

Pa.Terminate()