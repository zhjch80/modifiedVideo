//
//  DOPScrollableActionSheet.h
//  RMFlowerVideo
//
//  Created by runmobile on 14-9-28.
//  Copyright (c) 2014年 runmobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface DOPScrollableActionSheet : UIView{
    void(^shareSuccess)();
    void(^shareError)();
    void(^selectIndex)(NSInteger index);
}
@property (nonatomic, assign) id VideoPlaybackDetailsDelegate;

@property (nonatomic, copy) NSString *videoName;
@property (nonatomic, copy) NSString *video_pic;

- (void)initWithPlatformHeadImageArray:(NSArray *)images;

- (void)show;

- (void)dismiss;

- (void)shareSuccess:(void(^)())block;
- (void)shareError:(void(^)())block;
- (void)shareBtnSelectIndex:(void(^)(NSInteger Index))block;

@end