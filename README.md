# iOSVideoTranscriber
iOS Video Recorder/Transcriber

This app records video (limited to a (configurable) 15 seconds).  When the video is recorded, the audio is transcribed (via Nuance SpeechKit).

##Initial Setup (to get this to compile)

To get this to work, you must first get a key from Nuance:

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