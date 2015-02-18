# iOSVideoTranscriber
iOS Video Recorder/Transcriber

This app supports recording video (limited to a configurable 15 seconds).  When the video is recorded, the audio is transcribed (via Nuance SpeechKit).

##Initial Setup (just to get this to compile)

To get this to work, you must get a key from Nuance:

http://dragonmobile.nuancemobiledeveloper.com//public/index.php?task=register

You will then need to view your Sandbox Credentials here:

http://dragonmobile.nuancemobiledeveloper.com//public/index.php?task=credentials

And then add them to the ViewController.m file:

    const unsigned char SpeechKitApplicationKey[] = {
        NUANCE_APP_KEY
    };

(replace "NUANCE_APP_KEY" with the hex string under "Platform Specific Helpers: iOS")

    [SpeechKit setupWithID:NUANCE_REPLACE_WITH_ID
                      host:NUANCE_REPLACE_WITH_HOST
                      port:443
                    useSSL:NO
                  delegate:self];

(replace NUANCE_REPLACE_WITH_ID and NUANCE_REPLACE_WITH_HOST based on the values generated for you by Nuance)

## Current Problems

To turn on transcription, set:
    #define ENABLE_TRANSCRIPTION            1

This will generate the transcribed (spoken) text when the recording is stopped.  However, this will disable the video from being recorded.

To turn it off:
    #define ENABLE_TRANSCRIPTION            0

This will turn off transcribing, but will record the video (completion of the recording will pop up the video preview).

I am trying to find out how to get these functions to play together nicely.

