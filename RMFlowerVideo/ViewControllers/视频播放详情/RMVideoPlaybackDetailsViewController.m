//
//  RMVideoPlaybackDetailsViewController.m
//  RMFlowerVideo
//
//  Created by runmobile on 15-1-5.
//  Copyright (c) 2015年 runmoble. All rights reserved.
//

#import "RMVideoPlaybackDetailsViewController.h"
#import "RMPlayRelatedViewController.h"
#import "RMPlayDetailsViewController.h"
#import "RMPlayCreatorViewController.h"
#import "RMPlayTVEpisodeViewController.h"
#import "RMLoginViewController.h"
#import "RMLoadingWebViewController.h"
#import "RMDownLoadingViewController.h"
#import "RMTVDownLoadViewController.h"
#import "RMDetailsBottomView.h"
#import "RMSourceTypeView.h"
#import "DOPScrollableActionSheet.h"
#import "RMSegmentedController.h"
#import "RMTopJumpWebView.h"
#import "UIButton+EnlargeEdge.h"
#import "UMSocial.h"
#import "Flurry.h"
#import "GUIPlayerView.h"
#import "AppDelegate.h"

typedef enum{
    requestAddFavoriteType = 1,
    requestDeleteFavoriteType,
    requestVideoDetailsType
}RequestType;

@interface RMVideoPlaybackDetailsViewController ()<BottomBtnDelegate,SwitchSelectedMethodDelegate,RMAFNRequestManagerDelegate,SourceTypeDelegate,TVEpisodeDelegate,RefreshPlayAddressDelegate,UMSocialUIDelegate,GUIPlayerViewDelegate>{
    RMSegmentedController * segmentedCtl;
    RMPlayRelatedViewController * playRelatedCtl;
    RMPlayDetailsViewController * playDetailsCtl;
    RMPlayCreatorViewController * playCreatorCtl;
    RMPlayTVEpisodeViewController *playEpisodeCtl;
    RMSourceTypeView * sourceTypeView;
    RMTopJumpWebView * topJumpWebView;
    
    NSArray * nameArr;                      //segmentedCtl 上面的选项
    BOOL isFirstViewAppear;                 //是否第一次加载
    
    RequestType requestType;
    RMDownLoadingViewController *downLoadingCtl;//下载视图
}
@property (nonatomic, strong) RMDetailsBottomView * detailsBottomView;      //底部选择项
@property (nonatomic, strong) RMPublicModel * dataModel;                    //视频数据
@property (strong, nonatomic) GUIPlayerView *playerView;

@property (nonatomic, copy) NSString * currentSelectType;                   //当前选择播放源类型
@property (nonatomic, assign) BOOL isCollection;                            //当前是否已经收藏
@property (nonatomic, assign) NSInteger currentWatchVideo;                  //当前观看电视剧的集数
@property (nonatomic, assign) BOOL isRemovePlayer;                          //是否移除播放器
@end

@implementation RMVideoPlaybackDetailsViewController
@synthesize playerView, isRemovePlayer;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Flurry logEvent:@"VIEW_VideoPlayDetail" timed:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isFirstViewAppear){
        [self stratRequestWithVideo_id:self.video_id];
        isFirstViewAppear = NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kDeviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //统计视频播放次数
    RMAFNRequestManager * statisticalRequest = [[RMAFNRequestManager alloc] init];
    [statisticalRequest getDeviceHitsWithVideo_id:self.video_id Device:@"iPhone"];
    statisticalRequest.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"VIEW_VideoPlayDetail" withParameters:nil];
    [self hideLoading];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayJumpWeb) object:nil];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
        isRemovePlayer = NO;
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        isRemovePlayer = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kDeviceOrientationDidChangeNotification" object:nil];
    
    [playerView cancelNSTimer];
    if (isRemovePlayer){
        [self removePlayer];
        NSLog(@"移除");
    }else{
        [playerView.player pause];
        NSLog(@"暂停");
    }

    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    [storage beginUpdates];
    [storage setObject:@"NO" forKey:CustomNavCanRotate_KEY];
    [storage endUpdates];
    
    [self hideLoading];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.    
    
    [self hideCustomNavigationBar:YES withHideCustomStatusBar:YES];

    leftBarButton.hidden = YES;
    rightBarButton.hidden = YES;
    if (IS_IPHONE_6p_SCREEN | IS_IPHONE_6_SCREEN){
        self.detailsBottomView = [[RMDetailsBottomView alloc] initWithFrame:CGRectMake(0, ScreenHeight - 49, ScreenWidth, 49)];
    }else{
        self.detailsBottomView = [[RMDetailsBottomView alloc] initWithFrame:CGRectMake(0, ScreenHeight - 40, ScreenWidth, 40)];
    }
    self.detailsBottomView.backgroundColor = [UIColor blackColor];
    self.detailsBottomView.delegate = self;
    [self.detailsBottomView initDetailsBottomView];
    [self.view addSubview:self.detailsBottomView];
    
    if ([self.segVideoType isEqualToString:@"电影"]){
        nameArr = [NSArray arrayWithObjects:@"详情", @"主创", @"相关", nil];
    }else{
        nameArr = [NSArray arrayWithObjects:@"剧集", @"详情", @"主创", nil];
    }
    segmentedCtl = [[RMSegmentedController alloc] initWithFrame:CGRectMake(0, 226, [UIScreen mainScreen].bounds.size.width, 35) withSectionTitles:@[[nameArr objectAtIndex:0], [nameArr objectAtIndex:1], [nameArr objectAtIndex:2]] withIdentifierType:@"视频播放详情" withLineEdge:0 withAddLine:YES];
    segmentedCtl.delegate = self;
    [segmentedCtl setBackgroundColor:[UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1]];
    [segmentedCtl setTextColor:[UIColor clearColor]];
    [segmentedCtl setSelectionIndicatorColor:[UIColor clearColor]];
    [self.view addSubview:segmentedCtl];

    isFirstViewAppear = YES;
    self.currentWatchVideo = 0;
}

#pragma mark - 添加播放器

- (void)addPlayerWithUrl:(NSString *)url withVideoName:(NSString *)name; {
    [self removePlayer];

    playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 180)];
    [playerView setDelegate:self];
    playerView.topTitleLabel.text = name;
    [[self view] addSubview:playerView];

#if 0
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"BigBuckBunny" ofType:@"mp4"];
    //    NSURL *URL = [[NSURL alloc] initFileURLWithPath:path];
    
    NSURL *URL = [NSURL fileURLWithPath:url];
#else
    
#if 0
    NSURL * URL = [NSURL URLWithString:url];
#else
    NSURL * URL = [NSURL URLWithString:@"http://103.41.140.52/youku/6561A90C05437C4508343C61/030020010054F929428A9E15C96B7ED713FD70-5422-1F89-0657-49F438FD38B9.mp4"];
#endif
    
#endif

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [playerView setVideoURL:URL];
        [playerView prepareAndPlayAutomatically:YES];
    });
}

#pragma mark - 移除播放器

- (void)removePlayer {
    [playerView clean];
}

#pragma mark - GUI Player View Delegate Methods

- (void)playerWillEnterFullscreen {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)playerDidEnterFullscreen {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    playRelatedCtl.view.hidden = YES;
    playDetailsCtl.view.hidden = YES;
    playCreatorCtl.view.hidden = YES;
    playEpisodeCtl.view.hidden = YES;
    sourceTypeView.hidden = YES;
}

- (void)playerWillLeaveFullscreen {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)playerDidLeaveFullscreen {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    playRelatedCtl.view.hidden = NO;
    playDetailsCtl.view.hidden = NO;
    playCreatorCtl.view.hidden = NO;
    playEpisodeCtl.view.hidden = NO;
    sourceTypeView.hidden = NO;
}

- (void)playerDidEndPlaying {
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    [storage beginUpdates];
    [storage setObject:@"NO" forKey:CustomNavCanRotate_KEY];
    [storage endUpdates];
    [playerView clean];
}

- (void)playerFailedToPlayToEnd {
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    [storage beginUpdates];
    [storage setObject:@"NO" forKey:CustomNavCanRotate_KEY];
    [storage endUpdates];
    [self refreshUIWhenPlayerFailed];
    [playerView clean];
}

- (void)kDeviceOrientationDidChangeNotification:(CGFloat)duration {
    UIInterfaceOrientation toInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIDeviceOrientationIsLandscape(toInterfaceOrientation)){
        //横屏
    }else{
        //竖屏
    }
    [UIView animateWithDuration:duration animations:^{
        if(UIDeviceOrientationIsLandscape(toInterfaceOrientation)) {
            //横屏
            [self playerWillEnterFullscreen];
            playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            [playerView.playerLayer setFrame:playerView.frame];
            [playerView.activityIndicator setFrame:playerView.frame];
            [playerView.touchView setFrame:playerView.frame];
            playerView.progressHUD.frame = CGRectMake(0, 0, 193, 133);
            playerView.progressHUD.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
            playerView.fullscreen = YES;
            [playerView.fullscreenButton setSelected:YES];
            [playerView showControllers];
            [playerView.playButton setImage:[UIImage imageNamed:@"rm_pause_btn"] forState:UIControlStateNormal];
            [playerView.playButton setImage:[UIImage imageNamed:@"rm_play_btn"] forState:UIControlStateSelected];
        }else{
            //竖屏
            [self playerWillLeaveFullscreen];
            playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 180);
            [playerView.playerLayer setFrame:playerView.frame];
            [playerView.activityIndicator setFrame:playerView.frame];
            [playerView.touchView setFrame:playerView.frame];
            playerView.progressHUD.hidden = YES;
            playerView.fullscreen = NO;
            [playerView.fullscreenButton setSelected:NO];
            [playerView showControllers];
            [playerView.topControllersView setAlpha:0.0f];
            [playerView.playButton setImage:[UIImage imageNamed:@"rm_pausezoom_btn"] forState:UIControlStateNormal];
            [playerView.playButton setImage:[UIImage imageNamed:@"rm_playzoom_btn"] forState:UIControlStateSelected];
        }
        playerView.progressIndicator.bottomView.frame = CGRectMake(0, 18, [UIScreen mainScreen].bounds.size.width - 170, 5);
        playerView.progressIndicator.middleView.frame = CGRectMake(0, 18, [UIScreen mainScreen].bounds.size.width - 170, 5);
    } completion:^(BOOL finished) {
        if(UIDeviceOrientationIsLandscape(toInterfaceOrientation)) {
            //横屏
            [self playerDidEnterFullscreen];
        }else{
            //竖屏
            [self playerDidLeaveFullscreen];
        }
    }];
}

#pragma mark - 选集模块 刷新视频

- (void)videoEpisodeWithOrder:(NSInteger)order {
    if (self.dataModel.video_type.integerValue == 2){   //电视剧
        self.currentWatchVideo = order - 1;
        for (NSInteger i=0; i<[self.dataModel.playurls count]; i++) {
            if ([self.currentSelectType isEqualToString:[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"]]){
                [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:(order-1)] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                break;
            }
        }
    }else{  //综艺
        self.currentWatchVideo = order - 1;
        for (NSInteger i=0; i<[self.dataModel.playurls count]; i++) {
            if ([self.currentSelectType isEqualToString:[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"]]){
                [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:(order-1)] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                break;
            }
        }
    }
}

#pragma mark - 重新加载视频详情界面

- (void)reloadViewDidLoadWithVideo_id:(NSString *)video_id {
    [playerView cancelNSTimer];
    [self removePlayer];
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    [storage beginUpdates];
    [storage setObject:@"NO" forKey:CustomNavCanRotate_KEY];
    [storage endUpdates];
    
    if (self.dataModel.video_type.integerValue == 2){   //电视剧
        self.currentWatchVideo = 0;
    }else if (self.dataModel.video_type.integerValue == 3){  //综艺
        self.currentWatchVideo = [[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] count] - 1;
    }else{
    }
    [self stratRequestWithVideo_id:video_id];
}

#pragma mark - 点击 重新播放当前视频

- (void)refreshPlayAddressMethod {
    topJumpWebView.hidden = YES;
    if (self.dataModel.video_type.integerValue == 1){
        if ([self.dataModel.playurl count] == 0){
            [self refreshUIWhenPlayerFailed];
        }else{
            for (NSInteger i=0; i<[self.dataModel.playurl count]; i++){
                if ([[[self.dataModel.playurl objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                    [self addPlayerWithUrl:[[self.dataModel.playurl objectAtIndex:i] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                    break;
                }else{
                }
            }
        }
    }else{
        if ([self.dataModel.playurls count] == 0){
            [self refreshUIWhenPlayerFailed];
        }else{
            if (self.dataModel.video_type.integerValue == 2){   //电视剧
                self.currentWatchVideo = 0;
                if ([[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] count] == 0){
                    [self refreshUIWhenPlayerFailed];
                }else{
                    for (NSInteger i=0; i<[self.dataModel.playurls count]; i++) {
                        if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                            [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                            break;
                        }else{
                            
                        }
                    }
                }
            }else{  //综艺
                if ([[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] count] == 0){
                    [self refreshUIWhenPlayerFailed];
                }else{
                    for (NSInteger i=0; i<[self.dataModel.playurls count]; i++) {
                        if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                            self.currentWatchVideo = [[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] count] - 1;
                            [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                            break;
                        }else{
                            
                        }
                    }
                }
            }
        }
    }
}

#pragma mark - 请求完成默认第一次加载Player内容 type 1 为电影  2为电视剧 综艺

- (void)reloadFirstPlayerContent {
    if (self.dataModel.video_type.integerValue == 2){   //电视剧
        self.currentWatchVideo = 0;
    }else if (self.dataModel.video_type.integerValue == 3){  //综艺
        self.currentWatchVideo = [[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] count] - 1;
    }else{
        
    }
    if (self.dataModel.video_type.integerValue == 1){
        if ([self.dataModel.playurl count] == 0){
            [self refreshUIWhenPlayerFailed];
        }else{
            [self addPlayerWithUrl:[[self.dataModel.playurl objectAtIndex:0] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
        }
    }else{
        if ([self.dataModel.playurls count] == 0){
            [self refreshUIWhenPlayerFailed];
        }else{
            if ([[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] count] == 0){
                [self refreshUIWhenPlayerFailed];
            }else{
                [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:0] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
            }
        }
    }
}

#pragma mark - 视频加载失败调用的方法

- (void)refreshUIWhenPlayerFailed {
    [self loadTopJumpWebUI];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationPortrait;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

#pragma marl - 加载跳转失败转web的UI

- (void)loadTopJumpWebUI {
    if (!topJumpWebView){
        topJumpWebView = [[RMTopJumpWebView alloc] init];
        topJumpWebView.delegate = self;
        topJumpWebView.frame = CGRectMake(0, 0, ScreenWidth, 180);
        topJumpWebView.backgroundColor = [UIColor blackColor];
        [topJumpWebView initTopJumpWebView];
        [self.view addSubview:topJumpWebView];
    }
    topJumpWebView.hidden = NO;
    [self showLoadingSimpleWithUserInteractionEnabled:YES];
    [self performSelector:@selector(delayJumpWeb) withObject:nil afterDelay:1.0];
}

- (void)delayJumpWeb {
    if ([self.dataModel.video_type isEqualToString:@"1"]){   //电影
        if (self.dataModel.playurl.count == 0){
            [self hideLoading];
            [self showHUDWithImage:@"videoIsNotAddress" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
        }else{
            for (NSInteger i=0; i<[self.dataModel.playurl count]; i++){
                if ([[[self.dataModel.playurl objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                    RMLoadingWebViewController * loadingWebCtl = [[RMLoadingWebViewController alloc] init];
                    loadingWebCtl.loadingUrl = [[self.dataModel.playurl objectAtIndex:i] objectForKey:@"jumpurl"];
                    loadingWebCtl.name = self.dataModel.name;
                    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
                    [self.navigationController pushViewController:loadingWebCtl animated:YES];
                    break;
                }else{
                }
            }
        }
    }else{  //电视剧 综艺
        if (self.dataModel.playurls.count == 0){
            [self hideLoading];
            [self showHUDWithImage:@"videoIsNotAddress" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
        }else{
            if (self.dataModel.video_type.integerValue == 2){   //电视剧
                for (NSInteger i=0; i<[self.dataModel.playurls count]; i++){
                    if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                        if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] count] == 0){
                        }else{
                            RMLoadingWebViewController * loadingWebCtl = [[RMLoadingWebViewController alloc] init];
                            loadingWebCtl.loadingUrl = [[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:self.currentWatchVideo] objectForKey:@"jumpurl"];
                            loadingWebCtl.name = self.dataModel.name;
                            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
                            [self.navigationController pushViewController:loadingWebCtl animated:YES];
                        }
                        break;
                    }else{
                    }
                }
            }else{  //综艺
                for (NSInteger i=0; i<[self.dataModel.playurls count]; i++){
                    if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                        if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] count] == 0){
                        }else{
                            RMLoadingWebViewController * loadingWebCtl = [[RMLoadingWebViewController alloc] init];
                            loadingWebCtl.loadingUrl = [[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:self.currentWatchVideo] objectForKey:@"jumpurl"];
                            loadingWebCtl.name = self.dataModel.name;
                            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
                            [self.navigationController pushViewController:loadingWebCtl animated:YES];
                        }
                        break;
                    }else{
                    }
                }
            }

        }
    }
    [self hideLoading];
}

#pragma mark - 视频下模块分类 事件

- (void)switchSelectedMethodWithValue:(int)value withTitle:(NSString *)title {
    //电影：详情 主创 相关     电视剧： 剧集  详情 主创
    switch (value) {
        case 0:{
            if (self.dataModel.video_type.integerValue == 1){
                if (! playDetailsCtl){              //详情
                    playDetailsCtl = [[RMPlayDetailsViewController alloc] init];
                }
                if (IS_IPHONE_6_SCREEN | IS_IPHONE_6p_SCREEN){
                    playDetailsCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playDetailsCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playDetailsCtl.videoPlaybackDetailsDelegate = self;
                [playDetailsCtl reloadDataWithModel:self.dataModel];
                [self.view addSubview:playDetailsCtl.view];
            }else{
                if (! playEpisodeCtl){              //剧集
                    playEpisodeCtl = [[RMPlayTVEpisodeViewController alloc] init];
                }
                if (IS_IPHONE_6p_SCREEN | IS_IPHONE_6_SCREEN){
                    playEpisodeCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playEpisodeCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playEpisodeCtl.videoPlaybackDetailsDelegate = self;
                playEpisodeCtl.delegate = self;
                [playEpisodeCtl reloadDataWithModel:self.dataModel withVideoSourceType:self.currentSelectType];
                [self.view addSubview:playEpisodeCtl.view];
            }
            break;
        }
        case 1:{
            if (self.dataModel.video_type.integerValue == 1){
                if (! playCreatorCtl){              //主创
                    playCreatorCtl = [[RMPlayCreatorViewController alloc] init];
                }
                if (IS_IPHONE_6_SCREEN | IS_IPHONE_6p_SCREEN){
                    playCreatorCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playCreatorCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playCreatorCtl.videoPlaybackDetailsDelegate = self;
                [playCreatorCtl reloadDataWithModel:self.dataModel];
                [self.view addSubview:playCreatorCtl.view];
            }else{
                if (! playDetailsCtl){              //详情
                    playDetailsCtl = [[RMPlayDetailsViewController alloc] init];
                }
                if (IS_IPHONE_6p_SCREEN | IS_IPHONE_6_SCREEN){
                    playDetailsCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playDetailsCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playDetailsCtl.videoPlaybackDetailsDelegate = self;
                [playDetailsCtl reloadDataWithModel:self.dataModel];
                [self.view addSubview:playDetailsCtl.view];
                
            }
            break;
        }
        case 2:{
            if (self.dataModel.video_type.integerValue == 1){
                if (! playRelatedCtl){              //相关
                    playRelatedCtl = [[RMPlayRelatedViewController alloc] init];
                }
                if (IS_IPHONE_6_SCREEN | IS_IPHONE_6p_SCREEN){
                    playRelatedCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playRelatedCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playRelatedCtl.videoPlaybackDetailsDelegate = self;
                [playRelatedCtl reloadDataWithModel:self.dataModel];
                [self.view addSubview:playRelatedCtl.view];
            }else{
                if (! playCreatorCtl){              //主创
                    playCreatorCtl = [[RMPlayCreatorViewController alloc] init];
                }
                if (IS_IPHONE_6p_SCREEN | IS_IPHONE_6_SCREEN){
                    playCreatorCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 49);
                }else{
                    playCreatorCtl.view.frame = CGRectMake(0, 261, ScreenWidth, ScreenHeight - 261 - 40);
                }
                playCreatorCtl.videoPlaybackDetailsDelegate = self;
                [playCreatorCtl reloadDataWithModel:self.dataModel];
                [self.view addSubview:playCreatorCtl.view];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - 底部选项卡 事件

- (void)bottomBtnActionMethodWithSender:(NSInteger)sender {
    switch (sender) {
        case 1:{    //返回
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
        case 2:{//下载
            [Flurry logEvent:@"Click_DownLoad"];
            if ([self.dataModel.is_download isEqualToString:@"0"]){
                [self showHUDWithImage:@"videoIsNotDownload" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                return;
            }
            downLoadingCtl = [RMDownLoadingViewController shared];
            if (self.dataModel.video_type.integerValue == 1){   //电影]
                for(NSDictionary *dict in self.dataModel.playurl){
                    if([[dict objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                        if([dict objectForKey:@"m_down_url"]==nil||![[[dict objectForKey:@"m_down_url"] pathExtension] isEqualToString:@"mp4"]){
                            [self showHUDWithImage:@"videoIsNotDownload" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                        }
                        else if([[Database sharedDatabase] isDownLoadMovieWith:self.dataModel]){
                            [self showHUDWithImage:@"videoIsDownloaded" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                        }
                        else if( [self isContainsModel:downLoadingCtl.dataArray modelName:self.dataModel.name]){
                            [self showHUDWithImage:@"videoIsQueue" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                        }
                        else{
                            RMPublicModel *model = [[RMPublicModel alloc] init];
                            model.downLoadURL = [dict objectForKey:@"m_down_url"];
                            model.name = self.dataModel.name;
                            model.downLoadState = @"等待缓存";
                            model.actors = self.dataModel.actor;
                            model.directors = self.dataModel.director;
                            model.hits = self.dataModel.hits;
                            model.totalMemory = @"0M";
                            model.alreadyCasheMemory = @"0M";
                            model.cacheProgress = @"0.0";
                            model.pic = self.dataModel.pic;
                            model.video_id = self.dataModel.video_id;
                            model.isTVModel = NO;
                            [downLoadingCtl.dataArray addObject:model];
                            [downLoadingCtl.downLoadIDArray addObject:model];
                            [downLoadingCtl BeginDownLoad];
                            [self showHUDWithImage:@"videoAddSucess" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                            NSData * data = [NSKeyedArchiver archivedDataWithRootObject:downLoadingCtl.dataArray];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:DownLoadDataArray_KEY];
                        }
                    }
                }
            }else{  //电视剧
                RMTVDownLoadViewController *TVDownLoadCtl = [[RMTVDownLoadViewController alloc] init];
                TVDownLoadCtl.videoName = self.dataModel.name;
                TVDownLoadCtl.actors = self.dataModel.actors;
                TVDownLoadCtl.director = self.dataModel.directors;
                TVDownLoadCtl.PlayCount = self.dataModel.hits;
                TVDownLoadCtl.videoHeadImage = self.dataModel.pic;
                TVDownLoadCtl.video_id = self.dataModel.video_id;
                [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
                [self.navigationController pushViewController:TVDownLoadCtl animated:YES];
            }
            break;
        }
        case 3:{    //添加收藏   删除收藏
            [Flurry logEvent:@"Click_Collection"];
            if ([self.dataModel.video_id isEqualToString:@""] || self.dataModel.video_id.integerValue == 0){
                return;
            }
            //判断登录
            CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
            if (![[AESCrypt decrypt:[storage objectForKey:LoginStatus_KEY] password:PASSWORD] isEqualToString:@"islogin"]){
                RMLoginViewController * loginCtl = [[RMLoginViewController alloc] init];
                [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
                [self presentViewController:loginCtl animated:YES completion:^{
                }];
                return;
            }
            NSDictionary *dict = [storage objectForKey:UserLoginInformation_KEY];
            NSString * token = [NSString stringWithFormat:@"%@",[dict objectForKey:@"token"]];
            nilToEmpty(token);
            RMAFNRequestManager * request = [[RMAFNRequestManager alloc] init];
            request.delegate = self;
            
            if (self.isCollection){
                requestType = requestDeleteFavoriteType;
                [request deleteFavoriteWithVideo_id:self.dataModel.video_id andToken:token];
            }else{
                requestType = requestAddFavoriteType;
                [request addFavoriteWithVideo_id:self.dataModel.video_id andToken:token];
            }
            
            break;
        }
        case 4:{    //分享
            [Flurry logEvent:@"Click_Share"];
            NSArray *imageName;
            if(IS_IPHONE_6_SCREEN){
                imageName = [NSArray arrayWithObjects:@"share_sina_6",@"share_wechat_6",@"share_qq_6",@"share_QQZore_6",@"share_friends_6", nil];
            }else if (IS_IPHONE_6p_SCREEN){
                imageName = [NSArray arrayWithObjects:@"share_sina_6p",@"share_wechat_6p",@"share_qq_6p",@"share_QQZore_6p",@"share_friends_6p", nil];
            }else{
                imageName = [NSArray arrayWithObjects:@"share_sina",@"share_wechat",@"share_qq",@"share_QQZore",@"share_friends", nil];
            }
            DOPScrollableActionSheet *action = [[DOPScrollableActionSheet alloc] init];
            action.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
            action.backgroundColor = [UIColor clearColor];
            [action initWithPlatformHeadImageArray:imageName];                                    
            action.VideoPlaybackDetailsDelegate = self;
            action.videoName = self.dataModel.name;
            action.video_pic = self.dataModel.pic;
            [self.view addSubview:action];
            [action show];
            [action shareSuccess:^{
                [self showMessage:@"分享成功" duration:1 withUserInteractionEnabled:YES];
            }];
            [action shareError:^{
                [self showMessage:@"分享失败" duration:1 withUserInteractionEnabled:YES];
            }];
            [action shareBtnSelectIndex:^(NSInteger Index) {
                
                NSString *shareString = [NSString stringWithFormat:@"我正在看《%@》,精彩内容,精准推荐,尽在小花视频 %@",self.dataModel.name,kAppAddress];
                UIImage *shareImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.dataModel.pic]]];
                if(Index==0){
                    [[UMSocialControllerService defaultControllerService] setShareText:shareString shareImage:shareImage socialUIDelegate:self];
                    UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:UMShareToSina];
                    snsPlatform.snsClickHandler(self,[UMSocialControllerService defaultControllerService],YES);
                }else{
                    [[UMSocialDataService defaultDataService]  postSNSWithTypes:@[[self getSocialSnsPlatformNameWithType:Index]]
                                                                        content:shareString
                                                                          image:shareImage
                                                                       location:nil urlResource:nil
                                                            presentedController:self
                                                                     completion:^(UMSocialResponseEntity *response){
                                                                         if (response.responseCode == UMSResponseCodeSuccess) {
                                                                             NSLog(@"分享成功!");
                                                                         }
                                                                     }];
                }
                
            }];
            break;
        }
            
        default:
            break;
    }
}

- (NSString *)getSocialSnsPlatformNameWithType:(NSInteger)type {
    switch (type) {
        case 0:{
            return @"sina";
            break;
        }
        case 1:{
            return @"wxsession";
            break;
        }
        case 2:{
            return @"qq";
            break;
        }
        case 3:{
            return @"qzone";
            break;
        }
        case 4:{
            return @"wxtimeline";
            break;
        }
            
        default:
            return nil;
            break;
    }
}

- (BOOL)isContainsModel:(NSMutableArray *)dataArray modelName:(NSString *)string{
    for(RMPublicModel *tmpModel in dataArray){
        if([tmpModel.name isEqualToString:string]){
            return YES;
        }
    }
    return NO;
}

#pragma mark - 加载视频资源选项UI

/**
 *  type 1为电影   2为电视剧 或者 综艺
 */
- (void)loadSourceTypeUIWithType:(NSInteger)type {
    switch (type) {
        case 1:{
            NSMutableArray * totalArr = [[NSMutableArray alloc] init];
            for (NSInteger i=0; i<[self.dataModel.playurl count]; i++){
                RMPublicModel * model = [[RMPublicModel alloc] init];
                model.jumpurl = [[self.dataModel.playurl objectAtIndex:i] objectForKey:@"jumpurl"];
                model.m_down_url = [[self.dataModel.playurl objectAtIndex:i] objectForKey:@"m_down_url"];
                model.source_type = [[self.dataModel.playurl objectAtIndex:i] objectForKey:@"source_type"];
                [totalArr addObject:model];
                self.currentSelectType = [[self.dataModel.playurl objectAtIndex:0] objectForKey:@"source_type"];
            }
            if (!sourceTypeView){
                sourceTypeView = [[RMSourceTypeView alloc] init];
            }
            sourceTypeView.frame = CGRectMake(0, 180, ScreenWidth, 45);
            sourceTypeView.delegate = self;
            sourceTypeView.backgroundColor = [UIColor clearColor];
            [sourceTypeView loadSourceTypeViewWithTotal:totalArr];
            [self.view addSubview:sourceTypeView];
            break;
        }
        case 2:{
            NSMutableArray * totalArr = [[NSMutableArray alloc] init];
            for (NSInteger i=0; i<[self.dataModel.playurls count]; i++){
                RMPublicModel * model = [[RMPublicModel alloc] init];
                model.source_type = [[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"];
                model.urls = [[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"];
                [totalArr addObject:model];
                self.currentSelectType = [[self.dataModel.playurls objectAtIndex:0] objectForKey:@"source_type"];
            }
            if (!sourceTypeView){
                sourceTypeView = [[RMSourceTypeView alloc] init];
            }
            sourceTypeView.frame = CGRectMake(0, 180, ScreenWidth, 45);
            sourceTypeView.delegate = self;
            sourceTypeView.backgroundColor = [UIColor clearColor];
            [sourceTypeView loadSourceTypeViewWithTotal:totalArr];
            [self.view addSubview:sourceTypeView];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - 切换视频资源选项 事件
/**
 *  切换视频播放源  刷新当前播放资源
 *  0:默认 1:优酷 2:迅雷 3:腾讯 4:乐视 5:pptv 6:爱奇艺 7:土豆 8:1905 9:华数 10.搜狐
 */
- (void)switchVideoSourceToCurrentType:(NSInteger)type {
    self.currentSelectType = [NSString stringWithFormat:@"%ld",(long)type];
    
    if (self.dataModel.video_type.integerValue == 1){
        for (NSInteger i=0; i<[self.dataModel.playurl count]; i++){
            if ([[[self.dataModel.playurl objectAtIndex:i] objectForKey:@"source_type"] integerValue] == type){
                [self addPlayerWithUrl:[[self.dataModel.playurl objectAtIndex:i] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                break;
            }
        }
    }else{
        for (NSInteger i=0; i<[self.dataModel.playurls count]; i++) {
            if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"source_type"] integerValue] == type){
                if ([[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] count] == 0){
                    [self showHUDWithImage:@"videoIsNotAddress" imageFrame:CGRectMake(0, 0, 160, 40) duration:1.5 userInteractionEnabled:YES];
                }else{
                    [self addPlayerWithUrl:[[[[self.dataModel.playurls objectAtIndex:i] objectForKey:@"urls"] objectAtIndex:0] objectForKey:@"m_down_url"] withVideoName:self.dataModel.name];
                }
                break;
            }
        }
    }
}

#pragma mark - 请求

- (void)stratRequestWithVideo_id:(NSString *)video_id {
    requestType = requestVideoDetailsType;
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    NSDictionary *dict = [storage objectForKey:UserLoginInformation_KEY];
    NSString * token = [NSString stringWithFormat:@"%@",[dict objectForKey:@"token"]];
    nilToEmpty(token);
    RMAFNRequestManager * request = [[RMAFNRequestManager alloc] init];
    request.delegate = self;
    [request getVideoDetailWithVideo_id:video_id Token:token];
    [self showLoadingSimpleWithUserInteractionEnabled:YES];
}

- (void)requestFinishiDownLoadWithResults:(NSString *)results {
    if (requestType == requestAddFavoriteType){ //添加收藏
        if ([results isEqualToString:@"success"]){
            [self showHUDWithImage:@"addColSucess" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
            self.isCollection = YES;
            [self.detailsBottomView switchCollectionState:self.isCollection];
        }else{
            [self showHUDWithImage:@"addColFailed" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
            self.isCollection = NO;
            [self.detailsBottomView switchCollectionState:self.isCollection];
        }
    }else{  //删除收藏
        if ([results isEqualToString:@"success"]){
            [self showHUDWithImage:@"deleteColSucess" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
            self.isCollection = NO;
            [self.detailsBottomView switchCollectionState:self.isCollection];
        }else{
            [self showHUDWithImage:@"deleteColFailed" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
            self.isCollection = NO;
            [self.detailsBottomView switchCollectionState:self.isCollection];
        }
    }
    [self hideLoading];
}

- (void)requestFinishiDownLoadWithModel:(RMPublicModel *)model {
    self.dataModel = nil;
    self.dataModel = model;
    NSString *jumpString = @"",*m_down_url = @"",*videoName = @"";
    RMPublicModel *historyModel = [[RMPublicModel alloc] init];
    if (model.video_type.integerValue == 1){    //电影
        [segmentedCtl setSelectedIndex:2];
        [self switchSelectedMethodWithValue:2 withTitle:nil];
        [self loadSourceTypeUIWithType:1];
        for(NSDictionary *dict in self.dataModel.playurl){
            if([[dict objectForKey:@"source_type"] isEqualToString:self.currentSelectType]){
                jumpString = [dict objectForKey:@"jumpurl"];
                m_down_url = [dict objectForKey:@"m_down_url"];
                videoName = self.dataModel.name;
                break;
            }
        }
        historyModel.actors = self.dataModel.actor;
    }else{  //电视剧   综艺
        [segmentedCtl setSelectedIndex:0];
        [self switchSelectedMethodWithValue:0 withTitle:nil];
        [self loadSourceTypeUIWithType:2];
        if(self.dataModel.playurls.count>0){
            NSDictionary *dict = [self.dataModel.playurls objectAtIndex:0];
            jumpString = [dict objectForKey:@"jumpurl"];
            m_down_url = [dict objectForKey:@"m_down_url"];
            if([self.dataModel.video_type isEqualToString:@"2"]){
                videoName = [NSString stringWithFormat:@"电视剧_%@",self.dataModel.name];
                historyModel.actors = self.dataModel.actor;
            }
            else{
                videoName = [NSString stringWithFormat:@"综艺_%@",self.dataModel.name];
                historyModel.actors = self.dataModel.presenters;
            }
        }
    }
    historyModel.pic = self.dataModel.pic;
    historyModel.name = videoName;
    historyModel.directors = self.dataModel.director;
    historyModel.hits = self.dataModel.hits;
    historyModel.m_down_url = m_down_url;
    historyModel.playTime = @"0";
    historyModel.video_id = self.dataModel.video_id;
    historyModel.jumpurl =jumpString;
    [[Database sharedDatabase] insertHistoryMovieItem:historyModel];
    
    if (self.dataModel.is_favorite.integerValue == 1){
        self.isCollection = YES;
    }else{
        self.isCollection = NO;
    }
    [self.detailsBottomView switchCollectionState:self.isCollection];
    
    if ([self.dataModel.is_download isEqualToString:@"1"]){
        [self.detailsBottomView switchDownLoadState:YES];
    }else{
        [self.detailsBottomView switchDownLoadState:NO];
    }
    
    [self reloadFirstPlayerContent];
    [self hideLoading];
}

- (void)requestError:(NSError *)error {
    if (requestType == requestAddFavoriteType){ //添加收藏
        [self showHUDWithImage:@"addColFailed" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
    }else if (requestType == requestDeleteFavoriteType){  //删除收藏
        [self showHUDWithImage:@"deleteColFailed" imageFrame:CGRectMake(0, 0, 130, 40) duration:2 userInteractionEnabled:YES];
    }else{
        
    }
    [self hideLoading];
}

@end
