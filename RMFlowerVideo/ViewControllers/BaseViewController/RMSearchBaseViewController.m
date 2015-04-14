//
//  RMSearchBaseViewController.m
//  RMFlowerVideo
//
//  Created by 润华联动 on 15-1-4.
//  Copyright (c) 2015年 runmoble. All rights reserved.
//

#import "RMSearchBaseViewController.h"
#import "RMImageView.h"

@interface RMSearchBaseViewController ()<UIScrollViewDelegate,RefreshControlDelegate>{
    float lastContentOffset;
    int tableHeadViewHeight,searchBtnheight,mainScorllViewHeight,searchViewHeight,originY;
    
}
@property (nonatomic,  retain) UIPageControl *pageControl;
@end

@implementation RMSearchBaseViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableHeadViewHeight = 215,searchBtnheight = 31,mainScorllViewHeight = 172,searchViewHeight = 43,originY = 10;
    if(IS_IPHONE_6_SCREEN){
        tableHeadViewHeight = 247,searchBtnheight = 35, mainScorllViewHeight = 200,searchViewHeight = 47,originY = 14;
    }else if(IS_IPHONE_6p_SCREEN){
        tableHeadViewHeight = 279,searchBtnheight = 35,mainScorllViewHeight = 222,searchViewHeight = 47,originY = 15;
    }

    //随tableview 滚动时候显示的搜索view
    self.searchView = [[UIView alloc] initWithFrame:CGRectMake(originY, -searchViewHeight, ScreenWidth-originY*2, searchViewHeight)];
    self.searchView.backgroundColor = [UIColor whiteColor];
    UIButton *rollBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rollBtn.frame = CGRectMake(0, 6, ScreenWidth-originY*2, searchBtnheight);
    if(IS_IPHONE_6_SCREEN){
        [rollBtn setBackgroundImage:LOADIMAGE(@"home_search_btn_6") forState:UIControlStateNormal];
    }else if (IS_IPHONE_6p_SCREEN){
        [rollBtn setBackgroundImage:LOADIMAGE(@"home_search_btn_6p") forState:UIControlStateNormal];
    }else{
        [rollBtn setBackgroundImage:LOADIMAGE(@"home_search_btn") forState:UIControlStateNormal];
    }
    [rollBtn addTarget:self action:@selector(beginSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.searchView addSubview:rollBtn];
    [self.view addSubview:self.searchView];

    //table view 的 headView
    self.tableHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, tableHeadViewHeight)];

    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    searchBtn.frame = CGRectMake(originY, 6, ScreenWidth-originY*2, searchBtnheight);
    if(IS_IPHONE_6_SCREEN){
        [searchBtn setBackgroundImage:LOADIMAGE(@"home_search_btn_6") forState:UIControlStateNormal];
    }else if (IS_IPHONE_6p_SCREEN){
        [searchBtn setBackgroundImage:LOADIMAGE(@"home_search_btn_6p") forState:UIControlStateNormal];
    }else{
        [searchBtn setBackgroundImage:LOADIMAGE(@"home_search_btn") forState:UIControlStateNormal];
    }
    [searchBtn addTarget:self action:@selector(beginSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeadView addSubview:searchBtn];
    
    self.refreshControl=[[RefreshControl alloc] initWithScrollView:self.mainTableView delegate:self];
    self.refreshControl.topEnabled=YES;
    self.refreshControl.bottomEnabled=YES;
    [self.refreshControl registerClassForTopView:[CustomRefreshView class]];
}
- (void)creatTableViewheadScrollView{
    if(self.mainScorllView){
        [self.mainScorllView removeFromSuperview];
        self.mainScorllView = nil;
    }
    self.mainScorllView = [[CycleScrollView alloc] initWithFrame:CGRectMake(originY, searchViewHeight, ScreenWidth-originY*2, mainScorllViewHeight) animationDuration:4];
    self.mainScorllView.backgroundColor = [UIColor clearColor];
}
- (void)beginSearch{
    
}

- (void)showSearchView{
    [UIView animateWithDuration:0.3 animations:^{
        self.searchView.frame = CGRectMake(originY, 0, ScreenWidth-originY*2, searchViewHeight);
    }];
}

- (void)hideSearchViewWithDuration:(NSTimeInterval)time{
    [UIView animateWithDuration:time animations:^{
        self.searchView.frame = CGRectMake(originY, -searchViewHeight, ScreenWidth-originY*2, searchViewHeight);
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    lastContentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if(scrollView.contentOffset.y==0||scrollView.contentOffset.y<0){
        self.searchView.hidden = YES;
        [self hideSearchViewWithDuration:0.1];
    }
    else if (lastContentOffset < scrollView.contentOffset.y) {
        
        [self hideSearchViewWithDuration:0.3];
    }else{
        self.searchView.hidden = NO;
        [self showSearchView];
    }
}
- (void)setTabelViewHeadViewWith:(BOOL)state{
    self.mainTableView.tableHeaderView = nil;
    if(state){
        self.tableHeadView.frame = CGRectMake(0, 0, ScreenWidth, tableHeadViewHeight+6);
        [self.tableHeadView addSubview:self.mainScorllView];
    }
    else{
        [self.mainScorllView removeFromSuperview];
        self.tableHeadView.frame = CGRectMake(0, 0, ScreenWidth, searchBtnheight+6);
    }
    self.mainTableView.tableHeaderView = self.tableHeadView;
}

#pragma mark 以下俩个方法需要在子类中重写
- (void)refreshControlBeginDropDownLoad{
    
}
- (void)refreshControlBeginPullToRefresh{
    
}
- (void)refreshControl:(RefreshControl *)refreshControl didEngageRefreshDirection:(RefreshDirection)direction {
    if (direction == RefreshDirectionTop) { //下拉刷新
        [self refreshControlBeginPullToRefresh];
    }else if(direction == RefreshDirectionBottom) { //上拉加载
        [self refreshControlBeginDropDownLoad];
    }
}

@end
