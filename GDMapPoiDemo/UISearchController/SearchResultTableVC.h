//
//  SearchResultTableVC.h
//  GDMapPoiDemo
//
//  Created by Mr.JJ on 16/6/15.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AMapPOI;

@protocol SearchResultTableVCDelegate <NSObject>

- (void)setSelectedLocationWithLocation:(AMapPOI *)poi;

@end

@interface SearchResultTableVC : UITableViewController 

- (void)setSearchCity:(NSString *)city;

@property (nonatomic, weak) id<SearchResultTableVCDelegate> delegate;

@end
