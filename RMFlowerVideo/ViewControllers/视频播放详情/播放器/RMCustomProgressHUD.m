//
//  CustomSVProgressHUD.m
//  RMCustomPlay
//
//  Created by 润华联动 on 14-11-5.
//  Copyright (c) 2014年 runmobile. All rights reserved.
//

#import "RMCustomProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@implementation RMCustomProgressHUD

- (void)showWithState:(BOOL)isFastForward andNowTime:(NSInteger)time{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 8;
    self.hidden = NO;
    self.alpha=0.8;
    if(!isFastForward){
        [self.headImage setImage:[UIImage imageNamed:@"rm_speed"]];
    }else{
        [self.headImage setImage:[UIImage imageNamed:@"rm_back"]];
    }
    NSInteger minutes = time/60;
    NSInteger seconds = time%60;
    if (minutes<=0) {
        minutes = 0;
    }if (seconds<=0) {
        seconds = 0;
    }
    self.beginLable.text = [NSString stringWithFormat:@"%ld:%ld",(long)minutes,(long)seconds];
    self.totalLable.text = [NSString stringWithFormat:@"  /  %@",self.totalTimeString];
    
    [self performSelector:@selector(hideCustomHUD) withObject:nil afterDelay:2.0];
}

- (void)hideCustomHUD {
    self.alpha=0.8;
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha=0.0;
        [self setNeedsLayout];
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.alpha = 0.8;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCustomHUD) object:nil];
    }];
}

@end
