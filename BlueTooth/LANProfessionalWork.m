//
//  LANProfessionalWork.m
//  BlueToothManager
//
//  Created by Huasali on 2021/11/22.
//

#import "LANProfessionalWork.h"
#import "GNBlueToothWork.h"

NSString *const BT_GATT_SERVICE  = @"FEB3";

@interface LANProfessionalWork ()<GNBlueToothDelegate>{
    id _scanBlock;
}
@end

@implementation LANProfessionalWork

+ (LANProfessionalWork *)initWithLog:(BOOL)isOpen options:(NSDictionary *)launchOptions{
    LANProfessionalWork *LANWork = [[LANProfessionalWork alloc] init];
    [GNBlueToothWork initWithLog:isOpen options:launchOptions];
    [[GNBlueToothWork manager] addObserve:LANWork];
    return LANWork;
}
- (void)stopWork{
    _scanBlock = nil;
    [[GNBlueToothWork manager] removeObserve:self];
}
- (void)startScanGNDevice:(nullable void(^)(NSDictionary *object))completion{
    _scanBlock = [completion copy];
    [[GNBlueToothWork manager] disConnectDeviceWithSid:BT_GATT_SERVICE];
    [[GNBlueToothWork manager] startScanWitnName:nil sids:nil];
}
- (void)stopScan{
    _scanBlock = nil;
    [[GNBlueToothWork manager] stopScan];
}
- (void)connectDevice:(NSString *)udid{
    [[GNBlueToothWork manager] connectDeviceWithDid:udid];
}
- (void)disconnectWithUdid:(NSString *)udid{
    [[GNBlueToothWork manager] disconnectWithDid:udid];
}
- (void)disConnectAllDevice{
    [[GNBlueToothWork manager] disConnectDeviceWithSid:BT_GATT_SERVICE];
}
- (void)dataForCentralState:(NSDictionary *)dataDic{
    [self sendNotify:dataDic type:@"BLEState"];
}
- (void)dataForScan:(NSDictionary *)dataDic{
    NSData *manufacturerData = dataDic[@"kCBAdvDataManufacturerData"];
    if (manufacturerData) {
        NSMutableDictionary *tempDic = [self advDicFromData:manufacturerData];
        if (tempDic.count > 0) {
            CBPeripheral *peripheral = dataDic[@"peripheral"];
            [tempDic setValue:dataDic[@"rssi"] forKey:@"rssi"];
            [tempDic setValue:peripheral.identifier forKey:@"identifier"];
            [self sendNotify:tempDic type:@"scan"];
            if (_scanBlock) {
                void(^completion)(id object) = [_scanBlock copy];
                completion(tempDic);
            }
        }
    }
}
- (void)dataForStatus:(NSDictionary *)dataDic{
    [self sendNotify:dataDic type:@"connectStatus"];
}
- (void)dataForNotify:(NSDictionary *)dataDic{
    [self sendNotify:dataDic type:@"notify"];
}
- (void)dataForRead:(NSDictionary *)dataDic{
    [self sendNotify:dataDic type:@"read"];
}
- (void)sendNotify:(id)nDic type:(NSString *)type{
    LANLog(@"%@:%@",type,nDic);
}
- (NSMutableDictionary *)advDicFromData:(NSData *)manufacturerData{
    NSMutableDictionary *tempDataDic = [NSMutableDictionary dictionary];
    [tempDataDic setValue:[self hexStringFromData:manufacturerData] forKey:@"data"];
    return tempDataDic;
}

- (NSString *)hexStringFromData:(NSData *)data{
    if (data) {
        Byte *value = (Byte *)[data bytes];
        NSMutableString *mutableString = [NSMutableString string];
        for (int i = 0; i < data.length; i++) {
            NSString *tempStr = [NSString stringWithFormat:@"%02X",value[i]];
            [mutableString appendString:[tempStr lowercaseString]];
        }
        return mutableString;
    }
    else{
        return @"";
    }
}

@end
