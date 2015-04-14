//
//  RMCustomNavViewController.m
//  RMVideo
//
//  Created by 润华联动 on 14-11-6.
//  Copyright (c) 2014年 runmobile. All rights reserved.
//

#import "RMCustomNavViewController.h"
#import "CUSFileStorage.h"
#import "CONST.h"

@interface RMCustomNavViewController () {
    BOOL iscsds;
}

@end

@implementation RMCustomNavViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - 设备方向

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIDeviceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate {
    CUSFileStorage *storage = [CUSFileStorageManager getFileStorage:CURRENTENCRYPTFILE];
    NSString * str = [storage objectForKey:CustomNavCanRotate_KEY];
    if ([str isEqualToString:@"YES"]){
        return YES;
    }else{
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

@end
