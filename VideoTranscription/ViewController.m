//
//  ViewController.m
//  VideoTranscription
//
//  Created by Jeffrey Berthiaume on 2/18/15.
//  Copyright (c) 2015 Pushplay.net. All rights reserved.
//

#import "ViewController.h"

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <SpeechKit/SpeechKit.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureFileOutputRecordingDelegate, SpeechKitDelegate, SKRecognizerDelegate> {
    
    AVCaptureMovieFileOutput *movieFileOutput;
    BOOL isRecording;
    float elapsedTime;
    NSTimer *elapsedTimer;
    
    SKRecognizer* voiceSearch;
}

@property (nonatomic, weak) IBOutlet UIView *videoPreviewView;
@property (nonatomic, weak) IBOutlet UIButton *btnStartRecording;
@property (nonatomic, weak) IBOutlet UILabel *elapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *transcriptionLabel;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

#define MAX_SECONDS_FOR_VIDEO           15.0f
#define CAPTURE_FRAMES_PER_SECOND       30.0f

@implementation ViewController

const unsigned char SpeechKitApplicationKey[] = {
    NUANCE_APP_KEY
};

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [SpeechKit setupWithID:NUANCE_REPLACE_WITH_ID
                      host:NUANCE_REPLACE_WITH_HOST
                      port:443
                    useSSL:NO
                  delegate:self];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setUpRecording];
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_session) {
        [_session stopRunning];
        _session = nil;
    }
    
}

- (void) setUpRecording {
    if (_session) {
        [_session stopRunning];
        _session = nil;
    }
    
    [self.btnStartRecording setImage:[UIImage imageNamed:@"btn-record.png"] forState:UIControlStateNormal];
    
    isRecording = NO;
    [self setupCaptureSession];
    elapsedTime = -0.5f;
    [self updateElapsedTime];
    
}

- (void) updateElapsedTime {
    elapsedTime += 0.5f;
    
    NSInteger elapsedFromMax = MAX_SECONDS_FOR_VIDEO - elapsedTime;
    
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"00:%02li", (long)elapsedFromMax];
    if (elapsedTime >= MAX_SECONDS_FOR_VIDEO) {
        isRecording = YES; // just in case they hit the stop button at the same time
        [self recordVideo:self.btnStartRecording];
    }
    
}

// start camera/video

- (void) setupCaptureSession {
    NSError *error = nil;
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    [_session addInput:input];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // Microphone enabled code
            AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:nil];
            [_session addInput:audioInput];
        } else {
            
            // Microphone disabled code
            
        }
        
    }];
    
    dispatch_queue_t queue = dispatch_queue_create("videoCaptureQueue", NULL);
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @( kCVPixelFormatType_32BGRA ) };
    [output setSampleBufferDelegate:self queue:queue];
    
    [_session addOutput:output];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.name = @"videoPreview";
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = CGRectMake (0, 0, _videoPreviewView.frame.size.width, _videoPreviewView.frame.size.height);
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    if (currentOrientation == UIDeviceOrientationLandscapeLeft)
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    else
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    
    [_videoPreviewView.layer addSublayer:_previewLayer];
    
    //ADD MOVIE FILE OUTPUT
    NSLog(@"Adding movie file output");
    
    movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = MAX_SECONDS_FOR_VIDEO;                                   //Total seconds
    int32_t preferredTimeScale = CAPTURE_FRAMES_PER_SECOND;                         //Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale); //<<SET MAX DURATION
    movieFileOutput.maxRecordedDuration = maxDuration;
    
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024; //<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([_session canAddOutput:movieFileOutput])
        [_session addOutput:movieFileOutput];
    
    AVCaptureConnection *videoConnection = nil;
    
    for ( AVCaptureConnection *connection in [movieFileOutput connections] ) {
        NSLog(@"%@", connection);
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            NSLog(@"%@", port);
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
            }
        }
    }
    
    if([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:(AVCaptureVideoOrientation)currentOrientation];
    }
    
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) //Check size based configs are supported before setting them
        [_session setSessionPreset:AVCaptureSessionPreset640x480];
    
    [_session startRunning];
    
}


- (IBAction) recordVideo:(UIButton *) btn {
    
    if (!isRecording) {
        isRecording = YES;
        
        self.transcriptionLabel.text = @"";
        
        elapsedTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f
                                                        target:self
                                                      selector:@selector(updateElapsedTime)
                                                      userInfo:nil
                                                       repeats:YES];
        
        voiceSearch = [[SKRecognizer alloc] initWithType:SKDictationRecognizerType
                                               detection:SKLongEndOfSpeechDetection
                                                language:@"en_US"
                                                delegate:self];
        
        [btn setImage:[UIImage imageNamed:@"btn-stop.png"] forState:UIControlStateNormal];
        
        //Create local file URL to record to
        
        NSString *path = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"video.mp4"];
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:path];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            NSError *error;
            if ([fileManager removeItemAtPath:path error:&error] == NO) {
                //Error - handle if required
            }
        }
        
        //Start recording
        
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
    } else {
        isRecording = NO;
        
        [elapsedTimer invalidate];
        
        [movieFileOutput stopRecording];
        [voiceSearch stopRecording];
        
        [[[UIAlertView alloc] initWithTitle:@"Video Recorded" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Re-Record", @"Done", nil] show];
        
    }
    
}


- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [self setUpRecording];
    } else {
        [self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"videoPreviewViewController"] animated:YES completion:nil];
    }
    
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else {
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
}

- (void) captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
    
    BOOL RecordedSuccessfully = YES;
    
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            RecordedSuccessfully = [value boolValue];
        }
    }
    
    if (RecordedSuccessfully) {
        //----- RECORDED SUCESSFULLY -----
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
        
        //save outputFileURL
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.videoURL = outputFileURL;
        
        [[self.session.outputs[1] connectionWithMediaType:AVMediaTypeAudio] setEnabled:YES];
    }
}

#pragma mark -
#pragma mark SKRecognizerDelegate methods

- (void) recognizerDidBeginRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording started.");
}

- (void) recognizerDidFinishRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording finished.");
    
    [[self.session.outputs[1] connectionWithMediaType:AVMediaTypeAudio] setEnabled:NO];
}

- (void) recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results {
    NSLog(@"Got results.");
    NSLog(@"Session ID [%@].", [SpeechKit sessionID]);
    
    NSLog(@"%@", [results firstResult]);
    
    self.transcriptionLabel.text = [results firstResult];
    
    voiceSearch = nil;
}

- (void) recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    NSLog(@"Got error.");
    NSLog(@"Session id [%@].", [SpeechKit sessionID]); // for debugging purpose: printing out the speechkit session id
    
    NSLog(@"%@", suggestion);
    
    voiceSearch = nil;
}


@end
