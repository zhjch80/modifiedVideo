//
//  GUIPlayerView.h
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMSlider.h"
#import "RMTouchVIew.h"
#import "RMCustomProgressHUD.h"
#import <AVFoundation/AVFoundation.h>

@class GUIPlayerView;

@protocol GUIPlayerViewDelegate <NSObject>

@optional
- (void)playerDidPause;
- (void)playerDidResume;
- (void)playerDidEndPlaying;
- (void)playerWillEnterFullscreen;
- (void)playerDidEnterFullscreen;
- (void)playerWillLeaveFullscreen;
- (void)playerDidLeaveFullscreen;

- (void)playerFailedToPlayToEnd;
- (void)playerStalled;

@end

@interface GUIPlayerView : UIView
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *currentItem;

@property (strong, nonatomic) UIButton *fullscreenButton;
@property (assign, nonatomic) BOOL fullscreen;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) RMSlider *progressIndicator;
@property (strong, nonatomic) RMTouchVIew *touchView;
@property (strong, nonatomic) RMCustomProgressHUD * progressHUD;
@property (strong, nonatomic) UIView *topControllersView;
@property (strong, nonatomic) UILabel *topTitleLabel;
@property (strong, nonatomic) UIButton *playButton;

@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) NSInteger controllersTimeoutPeriod;
@property (weak, nonatomic) id<GUIPlayerViewDelegate> delegate;

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically;
- (void)clean;
- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)isPlaying;

- (void)setLiveStreamText:(NSString *)text;

- (void)toggleFullscreen;

- (void)showControllers;

- (void)cancelNSTimer;

@end
