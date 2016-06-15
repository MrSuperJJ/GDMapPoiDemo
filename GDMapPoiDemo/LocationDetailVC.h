//
//  LocationDetailVC.h
//  GDMapPlaceAroundDemo
//
//  Created by Mr.JJ on 16/6/14.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationDetailVC : UIViewController

- (instancetype)initWithLatitude:(double)latitude
                       longitude:(double)longitude
                           title:(NSString *)title
                        position:(NSString *)position;

@end
