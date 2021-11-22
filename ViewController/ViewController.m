//
//  ViewController.m
//  BlueToothManager
//
//  Created by Huasali on 2021/11/22.
//

#import "ViewController.h"

#import "ViewController.h"

@interface ViewController()<UITableViewDataSource,UITableViewDelegate>{
    NSArray *_componentsArray;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Page List";
    _componentsArray = @[@"BLESearch"];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _componentsArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = _componentsArray[indexPath.row];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self pushViewControllerWithIdentifier:_componentsArray[indexPath.row]];
}
- (void)pushViewControllerWithIdentifier:(NSString *)identifier{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    vc.title = identifier;
    [self.navigationController pushViewController:vc animated:true];
}


@end
