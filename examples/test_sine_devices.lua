local igwin = require"imgui.window"
--local win = igwin:SDL(800,400, "audio sine")
local win = igwin:GLFW(800,400, "audio sine",{vsync=2})
local ig = win.ig
local ffi = require"ffi"
----------Log
local function Log()
	local L = {}
	local Buf = ffi.new"ImGuiTextBuffer"
	local ScrollToBottom = false
	function L:Add(fmt,args)
		Buf:appendfv(fmt, args);
		ScrollToBottom = true
	end
	function L:Draw(title)
		if ig.Button("Clear") then Buf:clear() end
		ig.BeginChild("scrolling", ig.ImVec2(0,0), false, ig.ImGuiWindowFlags_HorizontalScrollbar);
		ig.TextUnformatted(Buf:begin());
		if (ScrollToBottom) then ig.SetScrollHereY(1.0); ScrollToBottom = false end
		ig.EndChild();
	end
	return L
end
local igLOG = Log()
local function strconcat(...)
	local str=""
	for i=1, select('#', ...) do
		str = str .. tostring(select(i, ...)) .. ",\t"
	end
	str = str .. "\n"
	return str
end
local function printLOG(...)
	igLOG:Add(strconcat(...))
end
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

local dac
local odevice = 0
local SRcombo, BScombo
local zerolat = ffi.new("bool[1]",false)
local function set_odev(dev)
	sampleHz = tonumber(SRcombo:get_name())
	local wantedBsiz = tonumber(BScombo:get_name())
    odevice = dev
    printLOG(auinf.DEVS[odevice].name, sampleHz, wantedBsiz)
	--if dac close it
	if dac then 
		dac:StopStream(); 
		dac:CloseStream(); 
		dac = nil 
	end
	if odevice == -1 then return end --bad device
	local outputParameters = ffi.new("PaStreamParameters",{odevice, 2, Pa.Float32, 0, nil})
	outputParameters.suggestedLatency = zerolat[0] and 0 or Pa.GetDeviceInfo(outputParameters.device).defaultLowOutputLatency;
	printLOG( "suggestedLatency",outputParameters.suggestedLatency)

	local err = Pa.IsFormatSupported( nil, outputParameters, sampleHz );
	if( err == Pa.FormatIsSupported ) then printLOG"supported" else printLOG"unsupported" end
	
	local stream, err, errmsg = Pa.OpenStream(nil, outputParameters, sampleHz, wantedBsiz, Pa.ClipOff, thecallback, ud)
	if not stream then
		printLOG("ERROR", errmsg)
		return 
	end
	dac = stream
	local streamInfo = Pa.GetStreamInfo( stream );
    printLOG( "out latency", streamInfo.outputLatency,"SR",  streamInfo.sampleRate, sampleHz*streamInfo.outputLatency);
	if dac:StartStream()~= Pa.NoError then
		printLOG("error in start_stream")--,ffi.string(lib.Pa.GetErrorText(err))))
	end
end
local DevCombo
local function scandevices()
	if dac then dac:StopStream(); dac:CloseStream(); dac = nil end
	Pa.Terminate()
	Pa.Initialize()
	auinf = Pa.GetAllInfo()
	DevCombo:set( auinf.out_devices.names)
end

local standardSampleRates = {
    8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
    44100.0, 48000.0, 88200.0, 96000.0, 192000.0}
for i,v in ipairs(standardSampleRates) do standardSampleRates[i] = tostring(v) end
SRcombo = ig.LuaCombo("SampleRate##in",standardSampleRates)
SRcombo:set_name("44100")

local bufsizes = {}
for i= 6,11 do table.insert(bufsizes, tostring(2^i)) end
table.insert(bufsizes, 1,tostring(0))
BScombo = ig.LuaCombo("buffer size##in",bufsizes)
BScombo:set_name("512")

DevCombo = ig.LuaCombo("devices", auinf.out_devices.names, function(val, id)
	odevice = auinf.out_devices.devID[id] ;
end)


local counter = 0
function win:draw(ig)

	if ig.Button"scan devices" then
		scandevices()
	end
	
	DevCombo:draw()
	ig.Text("%s, %s, API:%s",tostring(odevice), auinf.DEVS[odevice].name, auinf.DEVS[odevice].API)
	
	SRcombo:draw()
	BScombo:draw()
	
	ig.Checkbox("zero suggested latency",zerolat)
	ig.SameLine()
	if ig.Button"reset device" then
		set_odev(odevice)
	end
	
	ig.Separator()
	igLOG:Draw("log window")
	
    if counter==10 then
		setFreq(math.random()*500 + 100)
		counter = 0
	else counter = counter + 1 end
end

win:start()

Pa.Terminate()