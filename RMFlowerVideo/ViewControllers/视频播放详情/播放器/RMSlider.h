//
//  RMSlider.h
//  RMSlider
//
//  Created by runmobile on 15/2/11.
//  Copyright (c) 2015年 runmobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMSlider : UIView
@property (nonatomic, strong) UIView * bottomView;
@property (nonatomic, strong) UIView * middleView;
@property (nonatomic, strong) UIView * aboveView;

@property (nonatomic, strong) UISlider * slider;
@property (nonatomic, assign) CGFloat value;            /* From 0 to 1 */

@property (nonatomic, assign) CGFloat middleValue;      /* From 0 to 1 */
@property (nonatomic, assign) CGFloat aboveValue;       /* From 0 to 1 */

/**
 *  @name   RMSlider 背景颜色
 */
@property (nonatomic, strong) UIColor * bgColor;

@property (nonatomic, strong) UIColor* minimumTrackTintColor;
@property (nonatomic, strong) UIColor* middleTrackTintColor;
@property (nonatomic, strong) UIColor* maximumTrackTintColor;

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state;

@end
