//
//  PlaceAroundTableView.m
//  GDMapPlaceAroundDemo
//
//  Created by Mr.JJ on 16/6/14.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import "MapPoiTableView.h"
#import "MJRefresh.h"

#define CELL_HEIGHT                     55.f

@implementation MapPoiTableView
{
    UITableView *_tableView;
    // Poi搜索结果数组
    NSMutableArray *_searchPoiArray;
    
    // 下拉更多请求数据的标记
    BOOL isFromMoreLoadRequest;
    // 选中的IndexPath
    NSIndexPath *_selectedIndexPath;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
        [self addSubview:_tableView];
        
        // 初始化时保证_searchPoiArray长度为1
        _searchPoiArray = [NSMutableArray array];
        AMapPOI *point = [[AMapPOI alloc] init];
        [_searchPoiArray addObject:point];
    }
    return self;
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }
    AMapPOI *point = _searchPoiArray[indexPath.row];
    cell.textLabel.text = point.name;
    cell.textLabel.textColor = [UIColor blackColor];
    if (indexPath.row == 0) {
        cell.textLabel.frame = cell.frame;
        cell.textLabel.font = [UIFont systemFontOfSize:20];
        cell.detailTextLabel.text = @"";
    }
    else {
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.detailTextLabel.text = point.address;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    cell.accessoryType = (_selectedIndexPath.row == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchPoiArray.count;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 单选打勾
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger newRow = indexPath.row;
    NSInteger oldRow = _selectedIndexPath != nil ? _selectedIndexPath.row : -1;
    if (newRow != oldRow) {
        UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:_selectedIndexPath];
        lastCell.accessoryType = UITableViewCellAccessoryNone;
    }
    _selectedIndexPath = indexPath;
    
    // 将地图中心移到选中的位置
    _selectedPoi = _searchPoiArray[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(setMapCenterWithPOI:isLocateImageShouldChange:)]) {
        BOOL isShouldChange = indexPath.row == 0 ? NO : YES;
        [self.delegate setMapCenterWithPOI:_selectedPoi isLocateImageShouldChange:isShouldChange];
    }
}

#pragma mark - AMapSearchDelegate
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if (response.regeocode != nil) {
        // 去掉逆地理编码结果的省份和城市
        NSString *address = response.regeocode.formattedAddress;
        AMapAddressComponent *component = response.regeocode.addressComponent;
        address = [address stringByReplacingOccurrencesOfString:component.province withString:@""];
        address = [address stringByReplacingOccurrencesOfString:component.city withString:@""];
        // 将逆地理编码结果保存到数组第一个位置，并作为选中的POI点
        _selectedPoi = [[AMapPOI alloc] init];
        _selectedPoi.name = address;
        _selectedPoi.address = response.regeocode.formattedAddress;
        _selectedPoi.location = request.location;
        [_searchPoiArray setObject:_selectedPoi atIndexedSubscript:0];
        // 刷新TableView第一行数据
        NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [_tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        NSLog(@"_selectedPoi.name:%@",_selectedPoi.name);
        // 刷新后TableView返回顶部
        [_tableView setContentOffset:CGPointMake(0, 0) animated:NO];
        
        NSString *city = response.regeocode.addressComponent.city;
        [self.delegate setCurrentCity:city];
        
        [_delegate setSendButtonEnabledAfterLoadFinished];
    }
}

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    // 刷新POI后默认第一行为打勾状态
    _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    // 判断搜索结果是否来自于下拉刷新
    if (isFromMoreLoadRequest) {
        isFromMoreLoadRequest = NO;
    }
    else{
        //保留数组第一行数据
        if (_searchPoiArray.count > 1) {
            [_searchPoiArray removeObjectsInRange:NSMakeRange(1, _searchPoiArray.count-1)];
        }
    }
    
    // 刷新完成,没有数据时不显示footer
    if (response.pois.count == 0) {
        _tableView.mj_footer.state = MJRefreshStateNoMoreData;
    }
    else {
        _tableView.mj_footer.state = MJRefreshStateIdle;
    }
    
    // 添加数据并刷新TableView
    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
        [_searchPoiArray addObject:obj];
    }];
    [_tableView reloadData];
}

#pragma mark - Action
- (void)loadMoreData
{
    if ([self.delegate respondsToSelector:@selector(loadMorePOI)]) {
        [self.delegate loadMorePOI];
        isFromMoreLoadRequest = YES;
    }
}
@end
