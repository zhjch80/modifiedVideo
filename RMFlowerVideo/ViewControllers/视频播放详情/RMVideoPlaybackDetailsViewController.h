//
//  RMVideoPlaybackDetailsViewController.h
//  RMFlowerVideo
//
//  Created by runmobile on 15-1-5.
//  Copyright (c) 2015年 runmoble. All rights reserved.
//

#import "RMBaseViewController.h"

@interface RMVideoPlaybackDetailsViewController : RMBaseViewController
@property (nonatomic, copy) NSString * video_id;
@property (nonatomic, copy) NSString * segVideoType;

- (void)reloadViewDidLoadWithVideo_id:(NSString *)video_id; //重新加载界面

@end
