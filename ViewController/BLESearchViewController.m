//
//  BLESearchViewController.m
//  BlueToothManager
//
//  Created by Huasali on 2021/11/22.
//

#import "BLESearchViewController.h"
#import "LANProfessionalWork.h"

@interface BLESearchViewController (){
    NSDateFormatter *_dateFormatter;
    NSMutableDictionary *_deviceDic;
    NSArray *_deviceArray;
    LANProfessionalWork *_LANWork;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation BLESearchViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    _deviceDic = [NSMutableDictionary dictionary];
    _LANWork = [LANProfessionalWork initWithLog:true options:nil];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_LANWork startScanGNDevice:^(NSDictionary * _Nonnull object) {
        NSString *identifier = object[@"identifier"];
        NSString *title = [NSString stringWithFormat:@"%@(%@)",identifier,object[@"rssi"]];
        NSString *message = object[@"data"];
        if (!self->_deviceDic[identifier]) {
            [self->_deviceDic setValue:@{@"title":title,@"message":message,@"rssi":object[@"rssi"]} forKey:identifier];
            [self reloadTableView];
        }
    }];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_LANWork stopWork];
}
- (void)reloadTableView{
    self->_deviceArray = [self->_deviceDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        return [_deviceDic[obj2][@"rssi"] compare:_deviceDic[obj1][@"rssi"]];
    }];
    [self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _deviceArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSString *deviceKey = _deviceArray[indexPath.row];
    NSDictionary *deviceData = _deviceDic[deviceKey];
    UILabel *titlelabel = [cell viewWithTag:2001];
    UILabel *messagelabel = [cell viewWithTag:2002];
    titlelabel.text = deviceData[@"title"];
    messagelabel.text = deviceData[@"message"];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
