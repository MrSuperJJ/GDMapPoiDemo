//
//  SearchResultTableVC.m
//  GDMapPoiDemo
//
//  Created by Mr.JJ on 16/6/15.
//  Copyright © 2016年 Mr.JJ. All rights reserved.
//

#import "SearchResultTableVC.h"
#import <AMapSearchKit/AMapSearchKit.h>

@interface SearchResultTableVC() <UISearchResultsUpdating,AMapSearchDelegate>

@end

@implementation SearchResultTableVC
{
    NSString *_city;
    // 搜索key
    NSString *_searchString;
    // 搜索API
    AMapSearchAPI *_searchAPI;
    // 搜索结果数组
    NSMutableArray *_searchResultArray;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    _searchString = searchController.searchBar.text;
    [self searchPoiBySearchString:_searchString];
}

#pragma mark - AMapSearchDelegate
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.count > 0) {
        _searchResultArray = [response.pois mutableCopy];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchResultArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseIdentifier = @"searchResultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellReuseIdentifier];
    }
    AMapPOI *poi = [_searchResultArray objectAtIndex:indexPath.row];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:poi.name];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, text.length)];
    [text addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:NSMakeRange(0, text.length)];
    //高亮
    NSRange textHighlightRange = [poi.name rangeOfString:_searchString];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:textHighlightRange];
    cell.textLabel.attributedText = text;
    
    NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] initWithString:poi.address];
    [detailText addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(0, detailText.length)];
    [detailText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:NSMakeRange(0, detailText.length)];
    //高亮
    NSRange detailTextHighlightRange = [poi.address rangeOfString:_searchString];
    [detailText addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:detailTextHighlightRange];
    cell.detailTextLabel.attributedText = detailText;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate setSelectedLocationWithLocation:_searchResultArray[indexPath.row]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action
- (void)searchPoiBySearchString:(NSString *)searchString
{
    //POI关键字搜索
    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    request.keywords = searchString;
    request.city = _city;
    request.cityLimit = YES;
    [_searchAPI AMapPOIKeywordsSearch:request];
}

#pragma mark - 初始化
- (void)viewDidLoad
{
    [super viewDidLoad];
    _searchAPI = [[AMapSearchAPI alloc] init];
    _searchAPI.delegate = self;
    
    _searchResultArray = [NSMutableArray array];
//    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
//    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)setSearchCity:(NSString *)city
{
    _city = city;
}
@end
