//
//  PlaceAroundTableView.h
//  GDMapPlaceAroundDemo
//
//  Created by Mr.JJ on 16/6/14.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@protocol PlaceAroundTableViewDelegate <NSObject>

// 加载更多列表数据
- (void)loadMorePOI;
// 将地图中心移到所选的POI位置上
- (void)setMapCenterWithPOI:(AMapPOI *)point isLocateImageShouldChange:(BOOL)isLocateImageShouldChange;

@end

@interface PlaceAroundTableView : UIView <UITableViewDelegate,UITableViewDataSource,AMapSearchDelegate>

@property (nonatomic, weak) id<PlaceAroundTableViewDelegate> delegate;
// 选中的POI点
@property (nonatomic, strong) AMapPOI *selectedPoi;

@end
