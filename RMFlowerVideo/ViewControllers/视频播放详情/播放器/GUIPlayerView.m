//
//  GUIPlayerView.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "GUIPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "CUSFileStorage.h"
#import "CONST.h"

@interface GUIPlayerView () <AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate,TouchViewDelegate>

@property (strong, nonatomic) UIView *controllersView;

@property (strong, nonatomic) UILabel *currentTimeLabel;
@property (strong, nonatomic) UILabel *remainingTimeLabel;
@property (strong, nonatomic) UILabel *liveLabel;

@property (strong, nonatomic) NSTimer *progressTimer;
@property (strong, nonatomic) NSTimer *controllersTimer;
@property (assign, nonatomic) BOOL seeking;
@property (assign, nonatomic) BOOL isToolbar;
@property (assign, nonatomic) CGRect defaultFrame;

@property (nonatomic, copy) NSString *positionIdentifier;                   //判断当前是否是左右滑动
@property (nonatomic, assign) NSInteger fastForwardOrRetreatQuickly;        //视频若快进和快退时，标记当前的位置
@property (nonatomic, assign) BOOL isGetTotalTime;                          //是否拿到总共时间

@end

@implementation GUIPlayerView

@synthesize player, playerLayer, currentItem;
@synthesize controllersView, topControllersView;
@synthesize playButton, fullscreenButton, progressIndicator, touchView, progressHUD, topTitleLabel, currentTimeLabel, remainingTimeLabel, liveLabel, isGetTotalTime;
@synthesize activityIndicator, progressTimer, controllersTimer, seeking, fullscreen, isToolbar, defaultFrame, positionIdentifier ,fastForwardOrRetreatQuickly;

@synthesize videoURL, controllersTimeoutPeriod, delegate;

#pragma mark - View Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    defaultFrame = frame;
    [self setup];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}

- (void)setup {
    // Set up notification observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFailedToPlayToEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    [self setBackgroundColor:[UIColor blackColor]];
    
    NSArray *horizontalConstraints;
    NSArray *verticalConstraints;
    
    /** Container Top View **************************************************************************************************/
    topControllersView = [UIView new];
    [topControllersView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [topControllersView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
    [self addSubview:topControllersView];
    
    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[TCV]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"TCV" : topControllersView}];
    
    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[TCV(50)]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"TCV" : topControllersView}];
    [self addConstraints:horizontalConstraints];
    [self addConstraints:verticalConstraints];

    
    /** Container View **************************************************************************************************/
    controllersView = [UIView new];
    [controllersView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [controllersView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
    [self addSubview:controllersView];
    
    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CV]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"CV" : controllersView}];
    
    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[CV(40)]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"CV" : controllersView}];
    [self addConstraints:horizontalConstraints];
    [self addConstraints:verticalConstraints];
    
    
    /** UI Controllers **************************************************************************************************/
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [playButton setImage:[UIImage imageNamed:@"rm_pause_btn"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"rm_play_btn"] forState:UIControlStateSelected];
    
    fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [fullscreenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [fullscreenButton setImage:[UIImage imageNamed:@"expand"] forState:UIControlStateNormal];
    [fullscreenButton setImage:[UIImage imageNamed:@"shrink"] forState:UIControlStateSelected];
    
    currentTimeLabel = [UILabel new];
    [currentTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [currentTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [currentTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [currentTimeLabel setTextColor:[UIColor whiteColor]];
    currentTimeLabel.text = @"00:00";

    remainingTimeLabel = [UILabel new];
    [remainingTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [remainingTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [remainingTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [remainingTimeLabel setTextColor:[UIColor whiteColor]];
    remainingTimeLabel.text = @"00:00";

    progressIndicator = [RMSlider new];
    progressIndicator.backgroundColor = [UIColor clearColor];
    progressIndicator.minimumTrackTintColor = [UIColor colorWithRed:0.89 green:0.17 blue:0.08 alpha:1];
    progressIndicator.middleTrackTintColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1];
    progressIndicator.maximumTrackTintColor = [UIColor colorWithRed:0.21 green:0.21 blue:0.21 alpha:1];
    [progressIndicator setThumbImage:[UIImage imageNamed:@"rm_sliderdot"] forState:UIControlStateNormal];
    [progressIndicator setThumbImage:[UIImage imageNamed:@"rm_sliderdot"] forState:UIControlStateHighlighted];
    progressIndicator.middleView.frame = CGRectMake(0, 18, [UIScreen mainScreen].bounds.size.width - 170, 5);
    progressIndicator.bottomView.frame = CGRectMake(0, 18, [UIScreen mainScreen].bounds.size.width - 170, 5);
    [progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    liveLabel = [UILabel new];
    [liveLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [liveLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [liveLabel setTextAlignment:NSTextAlignmentCenter];
    [liveLabel setTextColor:[UIColor whiteColor]];
    [liveLabel setText:@""];
    [liveLabel setHidden:YES];
    
    [controllersView addSubview:playButton];
    [controllersView addSubview:currentTimeLabel];
    [controllersView addSubview:progressIndicator];
    [controllersView addSubview:remainingTimeLabel];
    [controllersView addSubview:fullscreenButton];
    [controllersView addSubview:liveLabel];
    
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[P(40)][C]-10-[I]-5-[R][F(40)]|"
                             options:0
                             metrics:nil
                             views:@{@"P" : playButton,
                                     @"C" : currentTimeLabel,
                                     @"I" : progressIndicator,
                                     @"R" : remainingTimeLabel,
                                     @"F" : fullscreenButton}];
    
    [controllersView addConstraints:horizontalConstraints];
    
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|-5-[L]-5-|"
                             options:0
                             metrics:nil
                             views:@{@"L" : liveLabel}];
    
    [controllersView addConstraints:horizontalConstraints];
    
    for (UIView *view in [controllersView subviews]) {
        verticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[V(40)]"
                               options:NSLayoutFormatAlignAllCenterY
                               metrics:nil
                               views:@{@"V" : view}];
        [controllersView addConstraints:verticalConstraints];
    }
    
    topTitleLabel = [UILabel new];
    [topTitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [topTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f]];
    [topTitleLabel setTextAlignment:NSTextAlignmentLeft];
    [topTitleLabel setHidden:YES];
    [topTitleLabel setTextColor:[UIColor whiteColor]];

    [topControllersView addSubview:topTitleLabel];

    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|-5-[TTLH]-5-|"
                             options:0
                             metrics:nil
                             views:@{@"TTLH" : topTitleLabel}];
    
    [topControllersView addConstraints:horizontalConstraints];

    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[TTLV(50)]-0-|"
                             options:0
                             metrics:nil
                             views:@{@"TTLV" : topTitleLabel}];
    
    [topControllersView addConstraints:horizontalConstraints];
    
    for (UIView *view in [topControllersView subviews]) {
        verticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[TV(50)]-0-|"
                               options:NSLayoutFormatAlignAllCenterY
                               metrics:nil
                               views:@{@"TV" : view}];
        [topControllersView addConstraints:verticalConstraints];
    }
    
    /** Loading Indicator ***********************************************************************************************/
    activityIndicator = [UIActivityIndicatorView new];
    [activityIndicator stopAnimating];
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [activityIndicator setFrame:frame];
    [self addSubview:activityIndicator];
    
    /** Touch Setup ***************************************************************************************************/
    touchView = [[RMTouchVIew alloc] init];
    touchView.backgroundColor = [UIColor clearColor];
    touchView.frame = self.frame;
    touchView.delegate = self;
    [self addSubview:touchView];
    
    /** progressHUD Setup ***************************************************************************************************/
    progressHUD = [[NSBundle mainBundle] loadNibNamed:@"RMCustomProgressHUD" owner:self options:nil].lastObject;
    progressHUD.hidden = YES;
    progressHUD.frame = CGRectMake(0, 0, 193, 133);
    progressHUD.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    [self addSubview:progressHUD];
    
    
    /** Actions Setup ***************************************************************************************************/
    
    [playButton addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
    [fullscreenButton addTarget:self action:@selector(toggleFullscreen) forControlEvents:UIControlEventTouchUpInside];
    
    [progressIndicator.slider addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
    [progressIndicator.slider addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
    [progressIndicator.slider addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside|
     UIControlEventTouchUpOutside];
    
    [self showControllers];
    controllersTimeoutPeriod = 3;
    isToolbar = YES;
}

#pragma mark - UI Customization

- (void)setLiveStreamText:(NSString *)text {
    [liveLabel setText:text];
}

#pragma mark - Actions

- (void)togglePlay:(UIButton *)button {
    if ([button isSelected]) {
        [button setSelected:NO];
        [player pause];
        
        if ([delegate respondsToSelector:@selector(playerDidPause)]) {
            [delegate playerDidPause];
        }
    } else {
        [button setSelected:YES];
        [self startNStimer];

        [self play];
        
        if ([delegate respondsToSelector:@selector(playerDidResume)]) {
            [delegate playerDidResume];
        }
    }
    
    [self showControllers];
}

- (void)toggleFullscreen {
    if (fullscreen){
        //竖屏
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];

//        if ([delegate respondsToSelector:@selector(playerWillLeaveFullscreen)]) {
//            [delegate playerWillLeaveFullscreen];
//        }
        
        [UIView animateWithDuration:0.2f animations:^{
            self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 180);
            [playerLayer setFrame:self.frame];
            [activityIndicator setFrame:self.frame];
            [touchView setFrame:self.frame];
            progressHUD.hidden = YES;
            [fullscreenButton setSelected:NO];
            [topControllersView setAlpha:0.0f];
        } completion:^(BOOL finished) {
//            if ([delegate respondsToSelector:@selector(playerDidLeaveFullscreen)]) {
//                [delegate playerDidLeaveFullscreen];
//            }
            fullscreen = NO;
        }];
        
    }else{
        //横屏
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
        
//        if ([delegate respondsToSelector:@selector(playerWillEnterFullscreen)]) {
//            [delegate playerWillEnterFullscreen];
//        }
        
        [UIView animateWithDuration:0.2f animations:^{
            self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            [playerLayer setFrame:self.frame];
            [activityIndicator setFrame:self.frame];
            [touchView setFrame:self.frame];
            progressHUD.frame = CGRectMake(0, 0, 193, 133);
            progressHUD.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
            [fullscreenButton setSelected:YES];
            [topControllersView setAlpha:1.0f];
        } completion:^(BOOL finished) {
//            if ([delegate respondsToSelector:@selector(playerDidEnterFullscreen)]) {
//                [delegate playerDidEnterFullscreen];
//            }
            fullscreen = YES;
        }];
    }
    
    [self showControllers];
}

- (void)seek:(UISlider *)slider {
    progressIndicator.aboveValue = progressIndicator.slider.value * progressIndicator.frame.size.width;
    int timescale = currentItem.asset.duration.timescale;
    float time = slider.value * (currentItem.asset.duration.value / timescale);
    [player seekToTime:CMTimeMakeWithSeconds(time, timescale)];
    
    [self showControllers];
}

- (void)pauseRefreshing {
    seeking = YES;
}

- (void)resumeRefreshing {
    seeking = NO;
}

- (NSTimeInterval)availableDuration {
    NSTimeInterval result = 0;
    NSArray *loadedTimeRanges = player.currentItem.loadedTimeRanges;
    
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        result = startSeconds + durationSeconds;
    }
    
    return result;
}

- (void)refreshProgressIndicator {
    CGFloat duration = CMTimeGetSeconds(currentItem.asset.duration);
    
    if (duration == 0 || isnan(duration)) {
        // Video is a live stream
        [currentTimeLabel setText:@"00:00"];
        [remainingTimeLabel setText:@"00:00"];
//        [progressIndicator setHidden:YES];
        [liveLabel setHidden:NO];
    } else {
        CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
        [storage beginUpdates];
        [storage setObject:@"YES" forKey:CustomNavCanRotate_KEY];
        [storage endUpdates];
        
        CGFloat current = seeking ?
        progressIndicator.value * duration :            // If seeking, reflects the position of the slider
        CMTimeGetSeconds(player.currentTime);           // Otherwise, use the actual video position
        
        [progressIndicator setValue:(current / duration)];
        progressIndicator.middleValue = ([self availableDuration] / duration) * progressIndicator.frame.size.width;
        progressIndicator.aboveValue = progressIndicator.slider.value * progressIndicator.frame.size.width;
        
        // Set time labels
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:(duration >= 3600 ? @"hh:mm:ss": @"mm:ss")];
        
        [currentTimeLabel setText:[self getStringFromCMTime:player.currentTime]];
        [remainingTimeLabel setText:[NSString stringWithFormat:@"%@", [self getStringFromCMTime:player.currentItem.asset.duration]]];
        
//        NSDate *currentTime = [NSDate dateWithTimeIntervalSince1970:current];
//        NSDate *remainingTime = [NSDate dateWithTimeIntervalSince1970:(duration - current)];
        
//        [currentTimeLabel setText:[formatter stringFromDate:currentTime]];
//        [remainingTimeLabel setText:[NSString stringWithFormat:@"-%@", [formatter stringFromDate:remainingTime]]];
        
        if (!isGetTotalTime){
            progressHUD.totalTimeString = [self getStringFromCMTime:player.currentItem.asset.duration];

//            progressHUD.totalTimeString = [formatter stringFromDate:remainingTime];
            isGetTotalTime = YES;
        }

        [progressIndicator setHidden:NO];
        [liveLabel setHidden:YES];
    }
}

- (NSString*)getStringFromCMTime:(CMTime)time {
    Float64 currentSeconds = CMTimeGetSeconds(time);
    int mins = currentSeconds/60.0;
    int secs = fmodf(currentSeconds, 60.0);
    NSString *minsString = mins < 10 ? [NSString stringWithFormat:@"0%d", mins] : [NSString stringWithFormat:@"%d", mins];
    NSString *secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
    return [NSString stringWithFormat:@"%@:%@", minsString, secsString];
}

- (void)showControllers {
    [topTitleLabel setHidden:NO];
    [UIView animateWithDuration:0.2f animations:^{
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            [controllersView setAlpha:1.0f];
            [topControllersView setAlpha:0.0f];
        }else{
            [controllersView setAlpha:1.0f];
            [topControllersView setAlpha:1.0f];
        }
    } completion:^(BOOL finished) {
        [controllersTimer invalidate];
        controllersTimer = [NSTimer scheduledTimerWithTimeInterval:controllersTimeoutPeriod
                                                            target:self
                                                          selector:@selector(hideControllers)
                                                          userInfo:nil
                                                           repeats:NO];
    }];
    isToolbar = YES;
}

- (void)hideControllers {
    [topTitleLabel setHidden:NO];
    [UIView animateWithDuration:0.5f animations:^{
        [controllersView setAlpha:0.0f];
        [topControllersView setAlpha:0.0f];
    }];
    isToolbar = NO;
}

#pragma mark - Public Methods

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically {
    currentItem = [AVPlayerItem playerItemWithURL:videoURL];
    player = [AVPlayer playerWithPlayerItem:currentItem];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.layer addSublayer:playerLayer];
    
    defaultFrame = self.frame;
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [playerLayer setFrame:frame];
    
    [self bringSubviewToFront:topControllersView];
    [self bringSubviewToFront:controllersView];
    [self bringSubviewToFront:progressHUD];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [player seekToTime:kCMTimeZero];
    [player setRate:0.0f];
    
    if (playAutomatically) {
        [self play];
        [activityIndicator startAnimating];
    }
    isGetTotalTime = NO;
}

- (void)clean {
    [self stop];
    [player removeObserver:self forKeyPath:@"rate"];
    touchView.delegate = nil;
    [self setPlayer:nil];
    [self setPlayerLayer:nil];
    [self removeFromSuperview];
}

- (void)play {
    [player play];
    
    [playButton setImage:[UIImage imageNamed:@"rm_pause_btn"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"rm_play_btn"] forState:UIControlStateSelected];
    [playButton setSelected:YES];

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [playButton setImage:[UIImage imageNamed:@"rm_pause_btn"] forState:UIControlStateNormal];
//        [playButton setImage:[UIImage imageNamed:@"rm_play_btn"] forState:UIControlStateSelected];
//        
//        progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
//                                                         target:self
//                                                       selector:@selector(refreshProgressIndicator)
//                                                       userInfo:nil
//                                                        repeats:YES];
//    });
}

- (void)pause {
    [player pause];
    [playButton setSelected:NO];
    
    if ([delegate respondsToSelector:@selector(playerDidPause)]) {
        [delegate playerDidPause];
    }
}

- (void)stop {
    if (player) {
        [player pause];
        [player seekToTime:kCMTimeZero];
        
        [playButton setSelected:NO];
    }
}

- (BOOL)isPlaying {
    return [player rate] > 0.0f;
}

#pragma mark - AV Player Notifications and Observers

- (void)playerDidFinishPlaying:(NSNotification *) notification {
    [self stop];
    
    if (fullscreen) {
        [self toggleFullscreen];
    }
    
    if ([delegate respondsToSelector:@selector(playerDidEndPlaying)]) {
        [delegate playerDidEndPlaying];
    }
}

- (void)playerFailedToPlayToEnd:(NSNotification *)notification {
    [self stop];
    
    if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
        [delegate playerFailedToPlayToEnd];
    }
}

- (void)playerStalled:(NSNotification *)notification {
    [self togglePlay:playButton];
    
    if ([delegate respondsToSelector:@selector(playerStalled)]) {
        [delegate playerStalled];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"rate"]) {
        CGFloat rate = [player rate];
        if (rate > 0) {
            [activityIndicator stopAnimating];
        }
    }
    if ([keyPath isEqualToString:@"status"]) {
        if (currentItem.status == AVPlayerItemStatusFailed) {
            if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
                [delegate playerFailedToPlayToEnd];
            }
        }
        else if (currentItem.status == AVPlayerItemStatusReadyToPlay){
            [activityIndicator stopAnimating];
            dispatch_async(dispatch_get_main_queue(), ^{
                progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                                 target:self
                                                               selector:@selector(refreshProgressIndicator)
                                                               userInfo:nil
                                                                repeats:YES];
            });
            
        }
    }
}

#pragma mark - TouchViewDelegate

- (void)touchInViewOfLocation:(float)space andDirection:(NSString *)direction slidingPosition:(NSString *)position {
    if([direction isEqualToString:@"right"]){
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            return ;
        }
        self.positionIdentifier = direction;
        BOOL isfastForward = NO;
        if(space>0){
            isfastForward = YES;
        }
        [progressHUD showWithState:isfastForward andNowTime:fastForwardOrRetreatQuickly];
        self.fastForwardOrRetreatQuickly = self.fastForwardOrRetreatQuickly - space;
    }else if([direction isEqualToString:@"left"]){
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            return ;
        }
        self.positionIdentifier = direction;
        BOOL isfastForward = NO;
        if(space>0){
            isfastForward = YES;
        }
        [progressHUD showWithState:isfastForward andNowTime:fastForwardOrRetreatQuickly];
        fastForwardOrRetreatQuickly = fastForwardOrRetreatQuickly -  space;
    }else if ([direction isEqualToString:@"down"]){
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            return ;
        }
        if([position isEqualToString:@"left"]){//控制声音
            MPMusicPlayerController *mpc = [MPMusicPlayerController applicationMusicPlayer];
            float num = mpc.volume;
            num += space/100;
            mpc.volume = num;  //0.0~1.0
        }else if([position isEqualToString:@"right"]){//控制屏幕亮度
            float num =[UIScreen mainScreen].brightness;
            num += space/100;
            [UIScreen mainScreen].brightness = num;
        }
    }else if ([direction isEqualToString:@"up"]){
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            return ;
        }
        if([position isEqualToString:@"left"]){//控制声音
            MPMusicPlayerController *mpc = [MPMusicPlayerController applicationMusicPlayer];
            float num  = mpc.volume;
            num += space/100;
            mpc.volume = num;  //0.0~1.0
        }else if([position isEqualToString:@"right"]){//控制屏幕亮度
            float num =[UIScreen mainScreen].brightness;
            num += space/100;
            [UIScreen mainScreen].brightness = num;
        }
    }
}

- (void)gestureRecognizerStateEnded {
    if([positionIdentifier isEqualToString:@"right"] || [positionIdentifier isEqualToString:@"left"]){
        CMTime seekTime = CMTimeMakeWithSeconds(fastForwardOrRetreatQuickly, player.currentTime.timescale);
        [player seekToTime:seekTime];
        [player play];
    }
}

- (void)gestureRecognizerStateBegan {
    positionIdentifier = @"none";
    fastForwardOrRetreatQuickly = progressIndicator.value * (double)player.currentItem.asset.duration.value/(double)player.currentItem.asset.duration.timescale;
}

- (void)gestureRecognizerOneTapMetohd {
    if (!isToolbar){
        [self showControllers];
    }else{
        [self hideControllers];
    }
}

- (void)gestureRecognizerTwoTapMetohd {
    if (playButton.isSelected) {
        [player pause];
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            [playButton setImage:[UIImage imageNamed:@"rm_pausezoom_btn"] forState:UIControlStateNormal];
        }else{
            [playButton setImage:[UIImage imageNamed:@"rm_pause_btn"] forState:UIControlStateNormal];
        }
        [playButton setSelected:NO];
    } else {
        [player play];
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
            [playButton setImage:[UIImage imageNamed:@"rm_playzoom_btn"] forState:UIControlStateSelected];
        }else{
            [playButton setImage:[UIImage imageNamed:@"rm_play_btn"] forState:UIControlStateSelected];
        }
        [playButton setSelected:YES];
    }
}

#pragma mark - 取消计时器

- (void)cancelNSTimer {
    [progressTimer setFireDate:[NSDate distantFuture]];
    [controllersTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark - 打开计时器

- (void)startNStimer {
    [progressTimer setFireDate:[NSDate distantPast]];
    [controllersTimer setFireDate:[NSDate distantPast]];
}

@end
