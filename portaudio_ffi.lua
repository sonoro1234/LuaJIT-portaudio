local ffi = require"ffi"

--uncomment to debug cdef calls
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
ffi_cdef[[
int Pa_GetVersion( void );
const char* Pa_GetVersionText( void );
typedef struct PaVersionInfo {
    int versionMajor;
    int versionMinor;
    int versionSubMinor;
    const char *versionControlRevision;
    const char *versionText;
} PaVersionInfo;
const PaVersionInfo* Pa_GetVersionInfo( void );
typedef int PaError;
typedef enum PaErrorCode
{
    paNoError = 0,
    paNotInitialized = -10000,
    paUnanticipatedHostError,
    paInvalidChannelCount,
    paInvalidSampleRate,
    paInvalidDevice,
    paInvalidFlag,
    paSampleFormatNotSupported,
    paBadIODeviceCombination,
    paInsufficientMemory,
    paBufferTooBig,
    paBufferTooSmall,
    paNullCallback,
    paBadStreamPtr,
    paTimedOut,
    paInternalError,
    paDeviceUnavailable,
    paIncompatibleHostApiSpecificStreamInfo,
    paStreamIsStopped,
    paStreamIsNotStopped,
    paInputOverflowed,
    paOutputUnderflowed,
    paHostApiNotFound,
    paInvalidHostApi,
    paCanNotReadFromACallbackStream,
    paCanNotWriteToACallbackStream,
    paCanNotReadFromAnOutputOnlyStream,
    paCanNotWriteToAnInputOnlyStream,
    paIncompatibleStreamHostApi,
    paBadBufferPtr
} PaErrorCode;
const char *Pa_GetErrorText( PaError errorCode );
PaError Pa_Initialize( void );
PaError Pa_Terminate( void );
typedef int PaDeviceIndex;
typedef int PaHostApiIndex;
PaHostApiIndex Pa_GetHostApiCount( void );
PaHostApiIndex Pa_GetDefaultHostApi( void );
typedef enum PaHostApiTypeId
{
    paInDevelopment=0,
    paDirectSound=1,
    paMME=2,
    paASIO=3,
    paSoundManager=4,
    paCoreAudio=5,
    paOSS=7,
    paALSA=8,
    paAL=9,
    paBeOS=10,
    paWDMKS=11,
    paJACK=12,
    paWASAPI=13,
    paAudioScienceHPI=14,
    paAudioIO=15
} PaHostApiTypeId;
typedef struct PaHostApiInfo
{
    int structVersion;
    PaHostApiTypeId type;
    const char *name;
    int deviceCount;
    PaDeviceIndex defaultInputDevice;
    PaDeviceIndex defaultOutputDevice;
} PaHostApiInfo;
const PaHostApiInfo * Pa_GetHostApiInfo( PaHostApiIndex hostApi );
PaHostApiIndex Pa_HostApiTypeIdToHostApiIndex( PaHostApiTypeId type );
PaDeviceIndex Pa_HostApiDeviceIndexToDeviceIndex( PaHostApiIndex hostApi,
        int hostApiDeviceIndex );
typedef struct PaHostErrorInfo{
    PaHostApiTypeId hostApiType;
    long errorCode;
    const char *errorText;
}PaHostErrorInfo;
const PaHostErrorInfo* Pa_GetLastHostErrorInfo( void );
PaDeviceIndex Pa_GetDeviceCount( void );
PaDeviceIndex Pa_GetDefaultInputDevice( void );
PaDeviceIndex Pa_GetDefaultOutputDevice( void );
typedef double PaTime;
typedef unsigned long PaSampleFormat;
typedef struct PaDeviceInfo
{
    int structVersion;
    const char *name;
    PaHostApiIndex hostApi;
    int maxInputChannels;
    int maxOutputChannels;
    PaTime defaultLowInputLatency;
    PaTime defaultLowOutputLatency;
    PaTime defaultHighInputLatency;
    PaTime defaultHighOutputLatency;
    double defaultSampleRate;
} PaDeviceInfo;
const PaDeviceInfo* Pa_GetDeviceInfo( PaDeviceIndex device );
typedef struct PaStreamParameters
{
    PaDeviceIndex device;
    int channelCount;
    PaSampleFormat sampleFormat;
    PaTime suggestedLatency;
    void *hostApiSpecificStreamInfo;
} PaStreamParameters;
PaError Pa_IsFormatSupported( const PaStreamParameters *inputParameters,
                              const PaStreamParameters *outputParameters,
                              double sampleRate );
typedef void PaStream;
typedef unsigned long PaStreamFlags;
typedef struct PaStreamCallbackTimeInfo{
    PaTime inputBufferAdcTime;
    PaTime currentTime;
    PaTime outputBufferDacTime;
} PaStreamCallbackTimeInfo;
typedef unsigned long PaStreamCallbackFlags;
typedef enum PaStreamCallbackResult
{
    paContinue=0,
    paComplete=1,
    paAbort=2
} PaStreamCallbackResult;
typedef int PaStreamCallback(
    const void *input, void *output,
    unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void *userData );
PaError Pa_OpenStream( PaStream** stream,
                       const PaStreamParameters *inputParameters,
                       const PaStreamParameters *outputParameters,
                       double sampleRate,
                       unsigned long framesPerBuffer,
                       PaStreamFlags streamFlags,
                       PaStreamCallback *streamCallback,
                       void *userData );
PaError Pa_OpenDefaultStream( PaStream** stream,
                              int numInputChannels,
                              int numOutputChannels,
                              PaSampleFormat sampleFormat,
                              double sampleRate,
                              unsigned long framesPerBuffer,
                              PaStreamCallback *streamCallback,
                              void *userData );
PaError Pa_CloseStream( PaStream *stream );
typedef void PaStreamFinishedCallback( void *userData );
PaError Pa_SetStreamFinishedCallback( PaStream *stream, PaStreamFinishedCallback* streamFinishedCallback );
PaError Pa_StartStream( PaStream *stream );
PaError Pa_StopStream( PaStream *stream );
PaError Pa_AbortStream( PaStream *stream );
PaError Pa_IsStreamStopped( PaStream *stream );
PaError Pa_IsStreamActive( PaStream *stream );
typedef struct PaStreamInfo
{
    int structVersion;
    PaTime inputLatency;
    PaTime outputLatency;
    double sampleRate;
} PaStreamInfo;
const PaStreamInfo* Pa_GetStreamInfo( PaStream *stream );
PaTime Pa_GetStreamTime( PaStream *stream );
double Pa_GetStreamCpuLoad( PaStream* stream );
PaError Pa_ReadStream( PaStream* stream,
                       void *buffer,
                       unsigned long frames );
PaError Pa_WriteStream( PaStream* stream,
                        const void *buffer,
                        unsigned long frames );
signed long Pa_GetStreamReadAvailable( PaStream* stream );
signed long Pa_GetStreamWriteAvailable( PaStream* stream );
PaError Pa_GetSampleSize( PaSampleFormat format );
void Pa_Sleep( long msec );
PaError PaAsio_GetAvailableBufferSizes( PaDeviceIndex device,
        long *minBufferSizeFrames, long *maxBufferSizeFrames, long *preferredBufferSizeFrames, long *granularity );
PaError PaAsio_ShowControlPanel( PaDeviceIndex device, void* systemSpecific );
PaError PaAsio_GetInputChannelName( PaDeviceIndex device, int channelIndex,
        const char** channelName );
PaError PaAsio_GetOutputChannelName( PaDeviceIndex device, int channelIndex,
        const char** channelName );
PaError PaAsio_SetStreamSampleRate( PaStream* stream, double sampleRate );
typedef struct PaAsioStreamInfo{
    unsigned long size;
    PaHostApiTypeId hostApiType;
    unsigned long version;
    unsigned long flags;
    int *channelSelectors;
}PaAsioStreamInfo;]]
ffi_cdef[[static const int paNoDevice = ((PaDeviceIndex)-1);
static const int paUseHostApiSpecificDeviceSpecification = ((PaDeviceIndex)-2);
static const int paFloat32 = ((PaSampleFormat) 0x00000001);
static const int paInt32 = ((PaSampleFormat) 0x00000002);
static const int paInt24 = ((PaSampleFormat) 0x00000004);
static const int paInt16 = ((PaSampleFormat) 0x00000008);
static const int paInt8 = ((PaSampleFormat) 0x00000010);
static const int paUInt8 = ((PaSampleFormat) 0x00000020);
static const int paCustomFormat = ((PaSampleFormat) 0x00010000);
static const int paNonInterleaved = ((PaSampleFormat) 0x80000000);
static const int paFormatIsSupported = (0);
static const int paFramesPerBufferUnspecified = (0);
static const int paNoFlag = ((PaStreamFlags) 0);
static const int paClipOff = ((PaStreamFlags) 0x00000001);
static const int paDitherOff = ((PaStreamFlags) 0x00000002);
static const int paNeverDropInput = ((PaStreamFlags) 0x00000004);
static const int paPrimeOutputBuffersUsingStreamCallback = ((PaStreamFlags) 0x00000008);
static const int paPlatformSpecificFlags = ((PaStreamFlags)0xFFFF0000);
static const int paInputUnderflow = ((PaStreamCallbackFlags) 0x00000001);
static const int paInputOverflow = ((PaStreamCallbackFlags) 0x00000002);
static const int paOutputUnderflow = ((PaStreamCallbackFlags) 0x00000004);
static const int paOutputOverflow = ((PaStreamCallbackFlags) 0x00000008);
static const int paPrimingOutput = ((PaStreamCallbackFlags) 0x00000010);
static const int PaAsio_GetAvailableLatencyValues = PaAsio_GetAvailableBufferSizes;
static const int paAsioUseChannelSelectors = (0x01);]]
local lib = ffi.load"portaudio"

local M = {C=lib}ffi.cdef"typedef struct pa_type{} pa_type;"

local PaStream_t = {}
PaStream_t.__index = PaStream_t


function PaStream_t:CloseStream()
    ffi.gc(self,nil)
    return lib.Pa_CloseStream(self)
end


function PaStream_t:PaAsio_SetStreamSampleRate(sampleRate)
    return lib.PaAsio_SetStreamSampleRate(self,sampleRate)
end
function PaStream_t:AbortStream()
    return lib.Pa_AbortStream(self)
end
function PaStream_t:GetStreamCpuLoad()
    return lib.Pa_GetStreamCpuLoad(self)
end
function PaStream_t:GetStreamInfo()
    return lib.Pa_GetStreamInfo(self)
end
function PaStream_t:GetStreamReadAvailable()
    return lib.Pa_GetStreamReadAvailable(self)
end
function PaStream_t:GetStreamTime()
    return lib.Pa_GetStreamTime(self)
end
function PaStream_t:GetStreamWriteAvailable()
    return lib.Pa_GetStreamWriteAvailable(self)
end
function PaStream_t:IsFormatSupported(outputParameters, sampleRate)
    return lib.Pa_IsFormatSupported(self,outputParameters, sampleRate)
end
function PaStream_t:IsStreamActive()
    return lib.Pa_IsStreamActive(self)
end
function PaStream_t:IsStreamStopped()
    return lib.Pa_IsStreamStopped(self)
end
function PaStream_t:ReadStream(buffer, frames)
    return lib.Pa_ReadStream(self,buffer, frames)
end
function PaStream_t:SetStreamFinishedCallback(streamFinishedCallback)
    return lib.Pa_SetStreamFinishedCallback(self,streamFinishedCallback)
end
function PaStream_t:StartStream()
    return lib.Pa_StartStream(self)
end
function PaStream_t:StopStream()
    return lib.Pa_StopStream(self)
end
function PaStream_t:WriteStream(buffer, frames)
    return lib.Pa_WriteStream(self,buffer, frames)
end
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
