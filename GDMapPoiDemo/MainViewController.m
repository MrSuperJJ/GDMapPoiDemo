//
//  MainViewController.m
//  GDMapPlaceAroundDemo
//
//  Created by Mr.JJ on 16/6/14.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import "MainViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "PlaceAroundTableView.h"
#import "LocationDetailVC.h"

#define SCREEN_WIDTH                    CGRectGetWidth([UIScreen mainScreen].bounds)
#define SCREEN_HEIGHT                   CGRectGetHeight([UIScreen mainScreen].bounds)
#define TITLE_HEIGHT                    64.f
#define CELL_HEIGHT                     55.f
#define CELL_COUNT                      5

@interface MainViewController () <MAMapViewDelegate,PlaceAroundTableViewDelegate>

@end

@implementation MainViewController
{
    MAMapView *_mapView;
    // 地图中心点的标记
    UIImageView *_centerMaker;
    // 地图中心点POI列表
    PlaceAroundTableView *_tableView;
    // 高德API不支持定位开关，需要自己设置
    UIButton *_locationBtn;
    UIImage *_imageLocated;
    UIImage *_imageNotLocate;
    // 搜索API
    AMapSearchAPI *_searchAPI;
    
    // 第一次定位标记
    BOOL isFirstLocated;
    // 搜索页数
    NSInteger searchPage;

    // 禁止连续点击两次
    BOOL _isMapViewRegionChangedFromTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"地图";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(sendLocation)];
    
    [self initMapView];
    [self initCenterMarker];
    [self initLocationButton];
    [self initTableView];
    [self initSearch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // 首次定位
    if (updatingLocation && !isFirstLocated) {
        [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude)];
        isFirstLocated = YES;
    }
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!_isMapViewRegionChangedFromTableView && isFirstLocated) {
        AMapGeoPoint *point = [AMapGeoPoint locationWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
        [self searchReGeocodeWithAMapGeoPoint:point];
        [self searchPoiByAMapGeoPoint:point];
        // 范围移动时当前页面数重置
        searchPage = 1;
        NSLog(@"%lf,%lf",_mapView.centerCoordinate.latitude,_mapView.centerCoordinate.longitude);
        NSLog(@"%lf,%lf",_mapView.userLocation.coordinate.latitude,_mapView.userLocation.coordinate.longitude);
        // 设置定位图标
        if (fabs(_mapView.centerCoordinate.latitude-_mapView.userLocation.coordinate.latitude) < 0.0001f && fabs(_mapView.centerCoordinate.longitude - _mapView.userLocation.coordinate.longitude) < 0.0001f) {
            [_locationBtn setImage:_imageLocated forState:UIControlStateNormal];
        }
        else {
            [_locationBtn setImage:_imageNotLocate forState:UIControlStateNormal];
        }
    }
    _isMapViewRegionChangedFromTableView = NO;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *reuseIndetifier = @"anntationReuseIndetifier";
        MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (!annotationView) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
            annotationView.image = [UIImage imageNamed:@"msg_location"];
            annotationView.centerOffset = CGPointMake(0, -18);
        }
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MAAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
        pre.showsAccuracyRing = NO;
        //        pre.fillColor = [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:0.3];
        //        pre.strokeColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.9 alpha:1.0];
        //        pre.image = [UIImage imageNamed:@"location.png"];
        //        pre.lineWidth = 3;
        //        pre.lineDashPattern = @[@6, @3];
        [_mapView updateUserLocationRepresentation:pre];
        
        view.calloutOffset = CGPointMake(0, 0);
    }
}

#pragma mark - PlaceAroundTableViewDelegate
- (void)loadMorePOI
{
    searchPage++;
    AMapGeoPoint *point = [AMapGeoPoint locationWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    [self searchPoiByAMapGeoPoint:point];
}

- (void)setMapCenterWithPOI:(AMapPOI *)point isLocateImageShouldChange:(BOOL)isLocateImageShouldChange
{
//    if (_isMapViewRegionChangedFromTableView) {
//        return;
//    }
    // 切换定位图标
    if (isLocateImageShouldChange) {
        [_locationBtn setImage:_imageNotLocate forState:UIControlStateNormal];
    }
    _isMapViewRegionChangedFromTableView = YES;
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.location.latitude, point.location.longitude);
    [_mapView setCenterCoordinate:location animated:YES];
}

#pragma mark - 初始化
- (void)initMapView
{
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0,0, SCREEN_WIDTH, SCREEN_HEIGHT - CELL_HEIGHT*CELL_COUNT)];
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

- (void)initCenterMarker
{
    UIImage *image = [UIImage imageNamed:@"centerMarker"];
    _centerMaker = [[UIImageView alloc] initWithImage:image];
    _centerMaker.frame = CGRectMake(self.view.frame.size.width/2-image.size.width/2, _mapView.bounds.size.height/2-image.size.height, image.size.width, image.size.height);
    [self.view addSubview:_centerMaker];
}

- (void)initTableView
{
    _tableView = [[PlaceAroundTableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_mapView.frame), SCREEN_WIDTH, CELL_HEIGHT*CELL_COUNT + TITLE_HEIGHT)];
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
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

- (void)initSearch
{
    searchPage = 1;
    _searchAPI = [[AMapSearchAPI alloc] init];
    _searchAPI.delegate = _tableView;
}

#pragma mark - Action
- (void)actionLocation
{
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
}

- (void)sendLocation
{
    //添加Marker标记
//    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
//    pointAnnotation.coordinate = _mapView.centerCoordinate;
//    [_mapView addAnnotation:pointAnnotation];
//    UIImage *image = [_mapView takeSnapshotInRect:_mapView.bounds];
    LocationDetailVC *locationDetailVC = [[LocationDetailVC alloc] initWithLatitude:_tableView.selectedPoi.location.latitude longitude:_tableView.selectedPoi.location.longitude title:_tableView.selectedPoi.name position:_tableView.selectedPoi.address];
    [self.navigationController pushViewController:locationDetailVC animated:YES];
}

// 搜索中心点坐标周围的POI-AMapGeoPoint
- (void)searchPoiByAMapGeoPoint:(AMapGeoPoint *)location
{
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = location;
    // 搜索半径
    request.radius = 1000;
    // 搜索结果排序
    request.sortrule = 1;
    // 当前页数
    request.page = searchPage;
    [_searchAPI AMapPOIAroundSearch:request];
}

// 搜索逆向地理编码-AMapGeoPoint
- (void)searchReGeocodeWithAMapGeoPoint:(AMapGeoPoint *)location
{
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = location;
    // 返回扩展信息
    regeo.requireExtension = YES;
    [_searchAPI AMapReGoecodeSearch:regeo];
}

@end
