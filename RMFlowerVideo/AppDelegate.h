//
//  AppDelegate.h
//  RMFlowerVideo
//
//  Created by 润华联动 on 14-12-30.
//  Copyright (c) 2014年 润滑联动. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMCustomNavViewController.h"

#define ShareApp (AppDelegate *)[[UIApplication sharedApplication] delegate]

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RMCustomNavViewController *cusNav;

@property (copy) void (^backgroundSessionCompletionHandler)();

@end

