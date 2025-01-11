local function printf(...)
	io.write(string.format(...))
end
local ffi = require"ffi"
local Pa = require"portaudio_ffi"

local function PrintSupportedStandardSampleRates(inputParameters,outputParameters )
    local standardSampleRates = {
        8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
        44100.0, 48000.0, 88200.0, 96000.0, 192000.0};

    local printCount = 0;
    for i=1, #standardSampleRates do
        local err = Pa.C.Pa_IsFormatSupported( inputParameters, outputParameters, standardSampleRates[i] );
        if( err == Pa.C.paFormatIsSupported ) then
            if( printCount == 0 ) then
                printf( "\t%8.2f", standardSampleRates[i] );
                printCount = 1;
            elseif( printCount == 4 ) then
                printf( ",\n\t%8.2f", standardSampleRates[i] );
                printCount = 1;
            else
                printf( ", %8.2f", standardSampleRates[i] );
                printCount = printCount + 1;
            end
        end
    end
    if( printCount == 0) then
        printf( "None\n" );
    else
        printf( "\n" );
	end
end


local err = Pa.C.Pa_Initialize()
assert(err==Pa.C.paNoError)

    print( string.format("PortAudio version: 0x%08X\n", Pa.C.Pa_GetVersion()));
    print( string.format("Version text: '%s'\n", ffi.string(Pa.C.Pa_GetVersionInfo().versionText )));
	local numDevices = Pa.C.Pa_GetDeviceCount();
	print( string.format("Number of devices = %d\n", numDevices ));
	
for i=0,numDevices-1 do
        local deviceInfo = Pa.C.Pa_GetDeviceInfo( i );
        printf( "--------------------------------------- device #%d\n", i );

    --/* Mark global and API specific default devices */
        local defaultDisplayed = false;
        if( i == Pa.C.Pa_GetDefaultInputDevice() ) then
            printf( "[ Default Input" );
            defaultDisplayed = true;
        elseif( i == Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi ).defaultInputDevice ) then
            local hostInfo = Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi );
            printf( "[ Default %s Input", ffi.string(hostInfo.name) );
            defaultDisplayed = true;
        end

        if( i == Pa.C.Pa_GetDefaultOutputDevice() ) then
            printf( (defaultDisplayed and "," or "[") );
            printf( " Default Output" );
            defaultDisplayed = true;
        elseif( i == Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi ).defaultOutputDevice ) then
            local hostInfo = Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi );
            printf( (defaultDisplayed and "," or "[") );
            printf( " Default %s Output", ffi.string(hostInfo.name) );
            defaultDisplayed = true;
        end

        if( defaultDisplayed ) then
            printf( " ]\n" );
		end

    --/* print device info fields */

        printf( "Name                        = %s\n", ffi.string(deviceInfo.name) );

        printf( "Host API                    = %s\n",  ffi.string(Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi ).name ));
        printf( "Max inputs = %d", deviceInfo.maxInputChannels  );
        printf( ", Max outputs = %d\n", deviceInfo.maxOutputChannels  );

        printf( "Default low input latency   = %8.4f\n", deviceInfo.defaultLowInputLatency  );
        printf( "Default low output latency  = %8.4f\n", deviceInfo.defaultLowOutputLatency  );
        printf( "Default high input latency  = %8.4f\n", deviceInfo.defaultHighInputLatency  );
        printf( "Default high output latency = %8.4f\n", deviceInfo.defaultHighOutputLatency  );

if ffi.os=="Windows" then

--/* ASIO specific latency information */
        if( Pa.C.Pa_GetHostApiInfo( deviceInfo.hostApi ).type == Pa.C.paASIO ) then
            local minLatency, maxLatency, preferredLatency, granularity = ffi.new("long[1]"),ffi.new("long[1]"),ffi.new("long[1]"),ffi.new("long[1]")

            local err = Pa.C.PaAsio_GetAvailableBufferSizes( i,
                    minLatency, maxLatency, preferredLatency, granularity );

            printf( "ASIO minimum buffer size    = %d\n", minLatency[0]  );
            printf( "ASIO maximum buffer size    = %d\n", maxLatency[0]  );
            printf( "ASIO preferred buffer size  = %d\n", preferredLatency[0]  );

            if( granularity[0] == -1 ) then
                printf( "ASIO buffer granularity     = power of 2\n" );
            else
                printf( "ASIO buffer granularity     = %d\n", granularity[0]  );
			end
        end

end

        printf( "Default sample rate         = %8.2f\n", deviceInfo.defaultSampleRate );

    --/* poll for standard sample rates */
		local inputParameters = ffi.new("PaStreamParameters")
        inputParameters.device = i;
        inputParameters.channelCount = deviceInfo.maxInputChannels;
        inputParameters.sampleFormat = Pa.C.paInt16;
        inputParameters.suggestedLatency = 0; --/* ignored by Pa_IsFormatSupported() */
        inputParameters.hostApiSpecificStreamInfo = nil;

		local outputParameters = ffi.new("PaStreamParameters")
        outputParameters.device = i;
        outputParameters.channelCount = deviceInfo.maxOutputChannels;
        outputParameters.sampleFormat = Pa.C.paInt16;
        outputParameters.suggestedLatency = 0; --/* ignored by Pa_IsFormatSupported() */
        outputParameters.hostApiSpecificStreamInfo = nil;

        if( inputParameters.channelCount > 0 ) then
            printf("Supported standard sample rates\n for half-duplex 16 bit %d channel input = \n",
                    inputParameters.channelCount );
            PrintSupportedStandardSampleRates( inputParameters, NULL );
        end

        if( outputParameters.channelCount > 0 ) then
            printf("Supported standard sample rates\n for half-duplex 16 bit %d channel output = \n",
                    outputParameters.channelCount );
            PrintSupportedStandardSampleRates( NULL, outputParameters );
        end

        if( inputParameters.channelCount > 0 and outputParameters.channelCount > 0 ) then
            printf("Supported standard sample rates\n for full-duplex 16 bit %d channel input, %d channel output = \n",
                    inputParameters.channelCount, outputParameters.channelCount );
            PrintSupportedStandardSampleRates( inputParameters, outputParameters );
        end
    end

    Pa.C.Pa_Terminate();

    printf("----------------------------------------------\n");