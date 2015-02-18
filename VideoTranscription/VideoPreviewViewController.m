//
//  VideoPreviewViewController.m
//  VideoTranscription
//
//  Created by Jeffrey Berthiaume on 2/18/15.
//  Copyright (c) 2015 Pushplay.net. All rights reserved.
//

#import "VideoPreviewViewController.h"

#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoPreviewViewController ()

@property (strong, nonatomic) MPMoviePlayerController *videoController;

@end

@implementation VideoPreviewViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self playVideo];
}

- (void) playVideo {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (!appDelegate.videoURL)
        [self dismissViewControllerAnimated:YES completion:nil];
    
    self.videoController = [[MPMoviePlayerController alloc] init];
    
    [self.videoController setContentURL:appDelegate.videoURL];
    
    self.videoController.view.frame = self.view.bounds;
    
    [self.view addSubview:self.videoController.view];
    
    [self.videoController play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoController];
    
}

- (void) videoPlaybackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoController];
    
    [self.videoController stop];
    [self.videoController.view removeFromSuperview];
    self.videoController = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
