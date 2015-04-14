//
//  RMSlider.m
//  RMSlider
//
//  Created by runmobile on 15/2/11.
//  Copyright (c) 2015年 runmobile. All rights reserved.
//

#import "RMSlider.h"
#import <QuartzCore/QuartzCore.h>

@interface RMSlider (){

}
@property (nonatomic, assign) BOOL loaded;
@end

@implementation RMSlider
@synthesize slider, loaded, bgColor;
@synthesize bottomView, middleView, aboveView;

- (void)awakeFromNib {
    [self loadSubView];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self loadSubView];
    }
    return self;
}

- (void)loadSubView {
    if (loaded){
        return;
    }
    loaded = YES;
    
    self.backgroundColor = bgColor;
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    
    slider = [[UISlider alloc] initWithFrame:self.bounds];
    slider.maximumTrackTintColor = [UIColor clearColor];
    slider.minimumTrackTintColor = [UIColor clearColor];
    [slider setMinimumTrackImage:[self imageWithColor:[UIColor clearColor] andSize:CGSizeMake(10, 10)] forState:UIControlStateHighlighted];
    [slider setMinimumTrackImage:[self imageWithColor:[UIColor clearColor] andSize:CGSizeMake(10, 10)] forState:UIControlStateNormal];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:slider];
    
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(3, 18, 0, 5)];
    bottomView.userInteractionEnabled = YES;
    bottomView.multipleTouchEnabled = YES;
    [bottomView.layer setCornerRadius:2.5];
    [slider addSubview:bottomView];
    
    middleView = [[UIView alloc] initWithFrame:CGRectMake(3, 18, 0, 5)];
    middleView.userInteractionEnabled = YES;
    middleView.multipleTouchEnabled = YES;
    [middleView.layer setCornerRadius:2.5];
    [slider addSubview:middleView];

    aboveView = [[UIView alloc] initWithFrame:CGRectMake(3, 18, 0, 5)];
    aboveView.userInteractionEnabled = YES;
    aboveView.multipleTouchEnabled = YES;
    [aboveView.layer setCornerRadius:2.5];
    [slider addSubview:aboveView];

}

- (CGFloat)value {
    return slider.value;
}

- (void)setValue:(CGFloat)value {
    slider.value = value;
}

- (CGFloat)middleValue {
    return middleView.frame.size.width;
}

- (void)setMiddleValue:(CGFloat)middleValue {
    middleView.frame = CGRectMake(0, 18, middleValue, 5);
}

- (CGFloat)aboveValue {
    return aboveView.frame.size.width;
}

- (void)setAboveValue:(CGFloat)aboveValue {
    if (aboveValue > [UIScreen mainScreen].bounds.size.width - 170){
        aboveView.frame = CGRectMake(0, 18, [UIScreen mainScreen].bounds.size.width - 170, 5);
    }else{
        aboveView.frame = CGRectMake(0, 18, aboveValue, 5);
    }
}

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state {
    [slider setThumbImage:image forState:state];
}

- (UIColor *)minimumTrackTintColor {
    return aboveView.backgroundColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    [aboveView setBackgroundColor:minimumTrackTintColor];
}

- (UIColor *)middleTrackTintColor {
    return middleView.backgroundColor;
}

- (void)setMiddleTrackTintColor:(UIColor *)middleTrackTintColor {
    [middleView setBackgroundColor:middleTrackTintColor];
}

- (UIColor *)maximumTrackTintColor {
    return bottomView.backgroundColor;
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    [bottomView setBackgroundColor:maximumTrackTintColor];
}

- (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
