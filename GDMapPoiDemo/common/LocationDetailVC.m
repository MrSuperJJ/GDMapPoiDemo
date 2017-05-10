//
//  LocationDetailVC.m
//  GDMapPlaceAroundDemo
//
//  Created by Mr.JJ on 16/6/14.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import "LocationDetailVC.h"
#import <MAMapKit/MAMapKit.h>

#define LABEL_HEIGHT                    80

@interface LocationDetailVC () <MAMapViewDelegate>

@end

@implementation LocationDetailVC
{
    MAMapView *_mapView;
    // 地图中心点的标记
    UIImageView *_centerMaker;
    // 高德API不支持定位开关，需要自己设置
    UIButton *_locationBtn;
    UIImage *_imageLocated;
    UIImage *_imageNotLocate;
    
    // 第一次定位标记
    BOOL isFirstLocated;
    
    double _latitude;
    double _longitude;
    NSString *_title;
    NSString *_position;
}

- (instancetype)initWithLatitude:(double)latitude
                       longitude:(double)longitude
                           title:(NSString *)title
                        position:(NSString *)position
{
    if (self = [super init]) {
        _latitude = latitude;
        _longitude = longitude;
        _title = title;
        _position = position;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"位置";
    
    [self initMapView];
    [self initTitleLabel];
    [self initLocationButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 绘制自定义Marker
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(_latitude, _longitude);
    [_mapView addAnnotation:pointAnnotation];
}

#pragma mark - MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // 首次定位
    if (updatingLocation && !isFirstLocated) {
        [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(_latitude,_longitude)];
        isFirstLocated = YES;
    }
}

// 自定义Marker
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *reuseIndetifier = @"anntationReuseIndetifier";
        MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (!annotationView) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
            annotationView.image = [UIImage imageNamed:@"centerMarker"];
            annotationView.centerOffset = CGPointMake(0, -18);
            annotationView.highlighted = YES;
        }
        return annotationView;
    }
    return nil;
}

// 自定义定位图标
- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MAAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    //    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    //    {
    MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
    pre.showsAccuracyRing = NO;
    //        pre.fillColor = [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:0.3];
    //        pre.strokeColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.9 alpha:1.0];
    //        pre.image = [UIImage imageNamed:@"location.png"];
    //        pre.lineWidth = 3;
    //        pre.lineDashPattern = @[@6, @3];
    
    [_mapView updateUserLocationRepresentation:pre];
    
    view.calloutOffset = CGPointMake(0, 0);
    //    }
}

#pragma mark - 初始化
- (void)initMapView
{
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0,0, SCREEN_WIDTH, SCREEN_HEIGHT - LABEL_HEIGHT)];
    _mapView.delegate = self;
    // 不显示罗盘
    _mapView.showsCompass = NO;
    // 不显示比例尺
    _mapView.showsScale = NO;
    // 地图缩放等级
    _mapView.zoomLevel = 16;
    // 开启定位
    _mapView.showsUserLocation = YES;
    [self.view addSubview:_mapView];
}

- (void)initTitleLabel
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_mapView.frame), SCREEN_WIDTH, LABEL_HEIGHT)];
    backgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:backgroundView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, SCREEN_WIDTH - 15, 22)];
    titleLabel.text = _title;
    titleLabel.font = [UIFont systemFontOfSize:22];
    titleLabel.textColor = [UIColor blackColor];
    [backgroundView addSubview:titleLabel];
    
    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(titleLabel.frame)+12, SCREEN_WIDTH - 15, 16)];
    detailLabel.text = _position;
    detailLabel.font = [UIFont systemFontOfSize:16];
    detailLabel.textColor = [UIColor grayColor];
    [backgroundView addSubview:detailLabel];
}

- (void)initLocationButton
{
    _imageLocated = [UIImage imageNamed:@"gpsselected"];
    _imageNotLocate = [UIImage imageNamed:@"gpsnormal"];
    _locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(_mapView.bounds)-50, CGRectGetHeight(_mapView.bounds)-50, 40, 40)];
    _locationBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _locationBtn.backgroundColor = [UIColor colorWithRed:239.0/255 green:239.0/255 blue:239.0/255 alpha:1];
    _locationBtn.layer.cornerRadius = 3;
    [_locationBtn addTarget:self action:@selector(actionLocation) forControlEvents:UIControlEventTouchUpInside];
    [_locationBtn setImage:_imageNotLocate forState:UIControlStateNormal];
    [self.view addSubview:_locationBtn];
}

#pragma mark - Action
- (void)actionLocation
{
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
}

@end
