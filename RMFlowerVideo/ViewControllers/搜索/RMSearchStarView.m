//
//  RMSearchStarView.m
//  RMFlowerVideo
//
//  Created by runmobile on 15-1-27.
//  Copyright (c) 2015年 runmoble. All rights reserved.
//

#import "RMSearchStarView.h"
#import "CONST.h"
#import "RMStarIntroViewController.h"
#import "RMSegmentedMultiSelectController.h"
#import "RMChannelMoviesViewController.h"
#import "RMChannelTeleplayViewController.h"
#import "RMChannelVarietyViewController.h"
#import "RMSearchViewController.h"

@interface RMSearchStarView ()<SwitchSelectedMethodDelegate>{
    UIImageView * starHead;
    UILabel * starIntrodue;
    
    RMChannelMoviesViewController * channelMoviesCtl;       //电影
    RMChannelTeleplayViewController * channelTeleplayCtl;   //电视剧
    RMChannelVarietyViewController * channelVarietyCtl;     //综艺
    RMSegmentedMultiSelectController * segmentedCtl;
    UIImageView * jumpIntrodueImg;
    UIButton * jumpBtn;
}
@end

@implementation RMSearchStarView

- (void)initSearchStarView {
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    [self loadStarView];
}

- (void)loadStarView {
    if (!starHead){
        starHead = [[UIImageView alloc] init];
    }
    starHead.frame = CGRectMake(12, 12, 92, 138);
    starHead.backgroundColor = [UIColor clearColor];
    [self addSubview:starHead];
    
    if (!starIntrodue){
        starIntrodue = [[UILabel alloc] init];
    }
    starIntrodue.frame = CGRectMake(110, 11, ScreenWidth - 120, 120);
    starIntrodue.numberOfLines = 0;
    starIntrodue.font = FONT(14.0);
    [self addSubview:starIntrodue];
    
    NSString * starDetail = [NSString stringWithFormat:@"%@",[[self.dataModel.star_list objectAtIndex:0] objectForKey:@"detail"]];
    NSString * starImage = [NSString stringWithFormat:@"%@",[[self.dataModel.star_list objectAtIndex:0] objectForKey:@"pic"]];
    
    [starHead sd_setImageWithURL:[NSURL URLWithString:starImage] placeholderImage:LOADIMAGE(@"92_138")];
    // 设置字体间每行的间距
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    //    paragraphStyle.lineHeightMultiple = 15.0f;
    //    paragraphStyle.maximumLineHeight = 15.0f;
    //    paragraphStyle.minimumLineHeight = 15.0f;
    paragraphStyle.lineSpacing = 5.0f;// 行间距
    NSDictionary *ats = @{
                          NSParagraphStyleAttributeName : paragraphStyle,
                          };
    starIntrodue.attributedText = [[NSAttributedString alloc] initWithString:starDetail attributes:ats];
    
    if (starDetail.length != 0){
        if (!jumpIntrodueImg){
            jumpIntrodueImg = [[UIImageView alloc] init];
            jumpIntrodueImg.frame = CGRectMake(ScreenWidth-50, 131, 36, 13);
            jumpIntrodueImg.image = LOADIMAGE(@"starDetails_show");
            [self addSubview:jumpIntrodueImg];
        }
        
        if (!jumpBtn){
            jumpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            jumpBtn.frame = CGRectMake(110, 5, ScreenWidth - 120, 140);
            jumpBtn.backgroundColor = [UIColor clearColor];
            [jumpBtn addTarget:self action:@selector(jumpIntrodueMethod) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:jumpBtn];
        }
    }else{
        starIntrodue.text = @"暂无介绍";
        jumpBtn.enabled = NO;
    }

    if ([starDetail isEqualToString:@"暂无"]){
        starIntrodue.text = @"暂无介绍";
        jumpBtn.enabled = NO;
        jumpIntrodueImg.hidden = YES;
    }
    
    NSArray * nameArr = [self getStarNameArrWithTVNum:[self.dataModel.tv_list count] withVarietyNum:[self.dataModel.variety_list count] withVodNum:[self.dataModel.vod_list count]];
    
    if (segmentedCtl){
        [segmentedCtl removeFromSuperview];
        segmentedCtl = nil;
    }
    
    segmentedCtl = [[RMSegmentedMultiSelectController alloc] initWithSectionTitles:@[[nameArr objectAtIndex:0], [nameArr objectAtIndex:1], [nameArr objectAtIndex:2]] withIdentifierType:@"搜索明星详情" withAddLine:YES];
    segmentedCtl.delegate = self;
    segmentedCtl.frame = CGRectMake(0, 160, ScreenWidth, 50);
    [segmentedCtl setSelectedIndex:0];
    [segmentedCtl setBackgroundColor:[UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1]];
    [segmentedCtl setTextColor:[UIColor clearColor]];
    [segmentedCtl setSelectionIndicatorColor:[UIColor clearColor]];
    [self addSubview:segmentedCtl];
    
    NSString * firstName;
    for (NSInteger i=0; i<[nameArr count]; i++) {
        if (![[nameArr objectAtIndex:i] isEqualToString:@""]){
            firstName = [nameArr objectAtIndex:i];
            break;
        }
    }
    [self switchSelectedMethodWithValue:0 withTitle:firstName];
}

- (void)jumpIntrodueMethod {
    RMSearchViewController * searchCtl = self.jumpDelegate;
    RMStarIntroViewController * starIntroCtl = [[RMStarIntroViewController alloc] init];
    starIntroCtl.starName = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"name"];
    starIntroCtl.starIntrodue = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"detail"];
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    [searchCtl.navigationController pushViewController:starIntroCtl animated:YES];
}

- (void)switchSelectedMethodWithValue:(NSInteger)value withTitle:(NSString *)title {
    switch (value) {
        case 0:{
            if ([title isEqualToString:@"电影"]){
                if (! channelMoviesCtl){
                    channelMoviesCtl = [[RMChannelMoviesViewController alloc] init];
                }
                channelMoviesCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
                channelMoviesCtl.MyChannelDetailsDelegate = self.jumpDelegate;
                channelMoviesCtl.ctlType = @"搜索";
                channelMoviesCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
                [self addSubview:channelMoviesCtl.view];
            }else if ([title isEqualToString:@"电视剧"]){
                if (! channelTeleplayCtl){
                    channelTeleplayCtl = [[RMChannelTeleplayViewController alloc] init];
                }
                channelTeleplayCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
                channelTeleplayCtl.MyChannelDetailsDelegate = self.jumpDelegate;
                channelTeleplayCtl.ctlType = @"搜索";
                channelTeleplayCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
                [self addSubview:channelTeleplayCtl.view];
            }else{
                if (! channelVarietyCtl){
                    channelVarietyCtl = [[RMChannelVarietyViewController alloc] init];
                }
                channelVarietyCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
                channelVarietyCtl.MyChannelDetailsDelegate = self.jumpDelegate;
                channelVarietyCtl.ctlType = @"搜索";
                channelVarietyCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
                [self addSubview:channelVarietyCtl.view];
            }
            break;
        }
        case 1:{
            if ([title isEqualToString:@"电视剧"]){
                if (! channelTeleplayCtl){
                    channelTeleplayCtl = [[RMChannelTeleplayViewController alloc] init];
                }
                channelTeleplayCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
                channelTeleplayCtl.MyChannelDetailsDelegate = self.jumpDelegate;
                channelTeleplayCtl.ctlType = @"搜索";
                channelTeleplayCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
                [self addSubview:channelTeleplayCtl.view];
            }else if ([title isEqualToString:@"综艺"]){
                if (! channelVarietyCtl){
                    channelVarietyCtl = [[RMChannelVarietyViewController alloc] init];
                }
                channelVarietyCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
                channelVarietyCtl.MyChannelDetailsDelegate = self.jumpDelegate;
                channelVarietyCtl.ctlType = @"搜索";
                channelVarietyCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
                [self addSubview:channelVarietyCtl.view];
            }
            break;
        }
        case 2:{
            if (! channelVarietyCtl){
                channelVarietyCtl = [[RMChannelVarietyViewController alloc] init];
            }
            channelVarietyCtl.view.frame = CGRectMake(0, 210, ScreenWidth, ScreenHeight - 210);
            channelVarietyCtl.MyChannelDetailsDelegate = self.jumpDelegate;
            channelVarietyCtl.ctlType = @"搜索";
            channelVarietyCtl.tag_id = [[self.dataModel.star_list objectAtIndex:0] objectForKey:@"tag_id"];
            [self addSubview:channelVarietyCtl.view];
            break;
        }
            
        default:
            break;
    }
}

- (NSArray *)getStarNameArrWithTVNum:(NSInteger)tv withVarietyNum:(NSInteger)variety withVodNum:(NSInteger)vod {
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    if (vod == 0){
        [arr addObject:@""];
    }else{
        [arr addObject:@"电影"];
    }
    
    if (tv == 0){
        [arr addObject:@""];
    }else{
        [arr addObject:@"电视剧"];
    }
    
    if (variety == 0){
        [arr addObject:@""];
    }else{
        [arr addObject:@"综艺"];
    }
    return arr;
}

@end
