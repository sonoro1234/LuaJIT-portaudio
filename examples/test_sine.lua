------sleep function
local ffi = require("ffi")
ffi.cdef[[
void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

local sleep
if ffi.os == "Windows" then
  function sleep(s)
    ffi.C.Sleep(s*1000)
  end
else
  function sleep(s)
    ffi.C.poll(nil, 0, s*1000)
  end
end
-------------------------------------
local function audio_init(userdata_cdef)
	local ffi = require"ffi"
	local Pa = require"portaudio_ffi"
	ffi.cdef(userdata_cdef)
	return function(inputBuffer, outputBuffer,
                            framesPerBuffer,
                             timeInfo,
                            statusFlags,
                            userData )
    local data = ffi.cast("paTestData*",userData)
    local out = ffi.cast("float*",outputBuffer)
    local finished = 0;
    for i=0,framesPerBuffer-1  do
        out[i] = data.sine[data.phase];  --/* left */
        data.phase = data.phase + 1;
        if( data.phase >= 200 ) then data.phase = data.phase - 200; end
    end
    return finished;
end
end

-------------------------------------
local Pa = require"portaudio_ffi"

local err = Pa.Initialize()
assert(err==Pa.NoError)

local userdata_cdef = [[
typedef struct
{
    float sine[200];
    int phase;
}
paTestData;
]]

ffi.cdef(userdata_cdef)

local data = ffi.new("paTestData")
for i=0,199 do
	data.sine[i] = 0.8 * math.sin( ((i/200) * math.pi * 2 ));
end
data.phase=0

local cbpa = Pa.MakeAudioCallback(audio_init, userdata_cdef)


local outputParameters = ffi.new"PaStreamParameters"
outputParameters.device = Pa.GetDefaultOutputDevice(); --/* default output device */
    if (outputParameters.device == Pa.NoDevice) then
        error("Error: No default output device.\n");
    end
    outputParameters.channelCount = 1;       
    outputParameters.sampleFormat = Pa.Float32;-- /* 32 bit floating point output */
    outputParameters.suggestedLatency = Pa.GetDeviceInfo( outputParameters.device ).defaultLowOutputLatency;
    outputParameters.hostApiSpecificStreamInfo = nil;
print("outdevice",outputParameters.device)
local err = Pa.IsFormatSupported( nil, outputParameters, 44100 );
if( err == Pa.FormatIsSupported ) then print"supported" else print"unsupported" end


local stream, err, errmsg = Pa.OpenStream(nil, outputParameters, 44100, 64, Pa.ClipOff, cbpa, data)
--local stream, err, errmsg = Pa.OpenDefaultStream(0, 1, Pa.Float32, 44100, 64, cbpa, data)
local err = stream:StartStream()
if not(err == Pa.NoError) then print(string.format("error: %s",ffi.string(Pa.GetErrorText(err)))) end
sleep(3);
print("cpuload",stream:GetStreamCpuLoad())
err = stream:CloseStream()
if not(err == Pa.NoError) then print(string.format("error: %s",ffi.string(Pa.GetErrorText(err)))) end
Pa.Terminate()