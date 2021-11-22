//
//  GNBlueToothWork.m
//  GNBlueToothWork
//
//  Created by Huasali on 2018/12/18.
//  Copyright © 2018 JH. All rights reserved.
//

#import "GNBlueToothWork.h"
#import <UIKit/UIKit.h>

@interface GNBlueToothWork ()<CBCentralManagerDelegate,CBPeripheralDelegate>{
    NSString *_searchName;
    NSArray  *_searchServiceIDs;
    NSMutableArray  *_sendDataArray;
    dispatch_queue_t  _sendDataQueue;
    NSMutableDictionary *_disconnectDic;
    BOOL _isScan;
    BOOL _isSendData;
    BOOL _isShowLog;
    
}

@property (nonatomic, strong) NSMutableArray *observeArr;

@end

@implementation GNBlueToothWork

#pragma mark ---------------方法---------------
- (void)initBlueToothWithOptions:(NSDictionary *)launchOptions{
    if (!_centralManager) {
        dispatch_queue_t  bluetoothQueue = dispatch_queue_create("com.gn.bluetooth", DISPATCH_QUEUE_SERIAL);
        NSArray *backgroundModes = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"UIBackgroundModes"];
        if ([backgroundModes containsObject:@"bluetooth-central"]) {
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey,
                                     (launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey]?:[[NSUUID UUID] UUIDString]),CBCentralManagerOptionRestoreIdentifierKey,
                                     nil];
            _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:bluetoothQueue options:options];
        }else{
            _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:bluetoothQueue];
        }
    }
    if (!_sendDataQueue) {
        _sendDataQueue = dispatch_queue_create("com.gn.bluetooth.SendDataQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    if (!_sendDataArray) {
        _sendDataArray = [NSMutableArray array];
    }
    if (!_disconnectDic) {
        _disconnectDic = [NSMutableDictionary dictionary];
    }
}
- (void)initBlueTooth{
    if (!_centralManager) {
        dispatch_queue_t  bluetoothQueue = dispatch_queue_create("com.gn.bluetooth", DISPATCH_QUEUE_SERIAL);
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:bluetoothQueue];
    }
    if (!_sendDataQueue) {
        _sendDataQueue = dispatch_queue_create("com.gn.bluetooth.SendDataQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    if (!_sendDataArray) {
        _sendDataArray = [NSMutableArray array];
    }
    if (!_disconnectDic) {
        _disconnectDic = [NSMutableDictionary dictionary];
    }
}

- (void)startScanWitnName:(NSString *)name sids:( NSArray *)sids{
    [self.scanDic removeAllObjects];
    _isScan = YES;
    _searchName = name;
    _searchServiceIDs = sids;
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES,CBCentralManagerRestoredStateScanOptionsKey:@YES};
    NSMutableArray *serviceArr = nil;
    if (sids) {
        serviceArr = [NSMutableArray array];
        for (NSString *tempSid in sids) {
            [serviceArr addObject:[CBUUID UUIDWithString:tempSid]];
        }
    }
    [_centralManager scanForPeripheralsWithServices:serviceArr options:scanForPeripheralsWithOptions];
}
- (void)stopScan{
    if (_centralManager.isScanning) {
        BTLog(@"停止扫描");
        _isScan = NO;
        //        [self.scanDic removeAllObjects];
        _searchName = nil;
        [_centralManager stopScan];
    }
}
- (BOOL)isOpenBlueTooth{
    BTLog(@"centralManager.state = %@ - %ld",_centralManager,(long)_centralManager.state)
    return  (_centralManager.state == CBManagerStatePoweredOn);
}
- (CBPeripheral *)peripheralForConnected:(NSString *)sid did:(NSString *)did{
    NSArray *deviceList = [_centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:sid]]];
    CBPeripheral *tempDevice = nil;
    for (CBPeripheral *device in deviceList) {
        if ([device.identifier.UUIDString isEqualToString:did]) {
            tempDevice = device;
        }
    }
    return tempDevice;
}
- (void)getConnectedBluetoothDevices{
    [_centralManager retrieveConnectedPeripheralsWithServices:@[]];
}
- (void)connectDeviceWithDid:(NSString *)did{
    CBPeripheral *peripheral = self.scanDic[did];
    if (peripheral) {
        [_centralManager connectPeripheral:peripheral options:nil];
    }
    else{
        BTLog(@"设备连接为空 %@-%@",did,self.scanDic);
    }
}
- (void)clearDisconnectDid:(NSString *)did{
    if (_disconnectDic[did]) {
        [_disconnectDic removeObjectForKey:did];
    }
}
- (void)disConnectDeviceWithSid:(NSString *)sid{
    NSArray *deviceList = [_centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:sid]]];
    for (CBPeripheral *device in deviceList) {
        [_centralManager cancelPeripheralConnection:device];
    }
}
- (void)disconnectCacheDevice{
    if (_disconnectDic.count > 0) {
        NSArray *tempArr = [_disconnectDic.allKeys copy];
        for (NSString *key  in tempArr) {
            [self disconnectWithDid:key];
            [_disconnectDic removeObjectForKey:key];
        }
    }
}
- (void)disconnectWithDid:(NSString *)did{
    CBPeripheral *peripheral = self.deviceDic[did];
    if (peripheral) {
        if (_isSendData) {
            if (!_disconnectDic[did]) {
                [_disconnectDic setObject:did forKey:did];
            }
        }
        else{
            [_centralManager cancelPeripheralConnection:peripheral];
        }
    }
    else{
        BTLog(@"设备未连接 did = %@",did);
    }
}
- (void)disConnectWithOutDid:(NSString *)did{
    NSArray *tempArr = self.deviceDic.allValues;
    for (int i = 0;i < tempArr.count;i++) {
        CBPeripheral *peripheral = tempArr[i];
        if (![peripheral.identifier.UUIDString isEqualToString:did]) {
            [_centralManager cancelPeripheralConnection:tempArr[i]];
        }
    }
}
- (void)disConnectAll{
    BTLog(@"断开连接");
    NSArray *tempArr = self.deviceDic.allValues;
    for (int i = 0;i < tempArr.count;i++) {
        [_centralManager cancelPeripheralConnection:tempArr[i]];
    }
}
- (int)numForWriteValueLengthDid:(NSString *)did type:(CBCharacteristicWriteType)type{
    CBPeripheral *peripheral = self.deviceDic[did];
    if (peripheral) {
        return (int)[peripheral maximumWriteValueLengthForType:type];
    }
    else{
        BTLog(@"设备未连接 did = %@",did);
        return 0;
    }
}
- (void)writeCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid data:(NSData *)data type:(CBCharacteristicWriteType)type{
    if (did) {
        CBPeripheral *peripheral = self.deviceDic[did];
        CBCharacteristic *characteristic = _characteristicDic[[NSString stringWithFormat:@"%@-%@-%@",did,sid,cid]];
        if (peripheral&&characteristic&&data) {
            [peripheral writeValue:data forCharacteristic:characteristic type:type];
            BTLog(@"开始发送%@ : %@",characteristic.UUID.UUIDString,data);
        }
        else{
            BTLog(@"发送失败 peripheral = %@，characteristic = %@ data = %@",peripheral,characteristic,data);
        }
    }
    else{
        BTLog(@"did为空");
    }
}
- (void)writeCacheCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid data:(NSData *)data type:(CBCharacteristicWriteType)type time:(float)time{
    if (did&&data) {
        NSMutableDictionary *tempDataDic = [NSMutableDictionary dictionary];
        [tempDataDic setValue:did forKey:@"did"];
        [tempDataDic setValue:[NSString stringWithFormat:@"%@-%@-%@",did,sid,cid] forKey:@"cidkey"];
        [tempDataDic setValue:data forKey:@"data"];
        [tempDataDic setValue:[NSNumber numberWithInteger:type] forKey:@"type"];
        [tempDataDic setValue:[NSNumber numberWithFloat:time] forKey:@"time"];
        [self addItem:tempDataDic];
        if (!_isSendData) {
            _isSendData = YES;
            [self writeData];
        }
    }
    else{
        BTLog(@"did或者数据为空 %@ - %@",did,data);
    }
}
- (void)writeData{
    NSDictionary *dataDic = [self lastItem];
    if (dataDic) {
        CBPeripheral *peripheral = self.deviceDic[dataDic[@"did"]];
        CBCharacteristic *characteristic = _characteristicDic[dataDic[@"cidkey"]];
        NSData *sendData = dataDic[@"data"];
        CBCharacteristicWriteType type = [dataDic[@"type"] integerValue];
        if (peripheral&&characteristic&&sendData) {
            [peripheral writeValue:sendData forCharacteristic:characteristic type:type];
            BTLog(@"蓝牙发送数据 data = %@",sendData);
        }
        else{
            BTLog(@"蓝牙发送失败 peripheral = %@，characteristic = %@ data = %@",peripheral,characteristic,sendData);
        }
        [self removeLastItem];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(writeData) withObject:nil afterDelay:[dataDic[@"time"] floatValue]];
        });
    }
    else{
        BTLog(@"蓝牙发送数据结束");
        _isSendData = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(disconnectCacheDevice) withObject:nil afterDelay:0.6];
        });
    }
}
-(void)addItem:(id)item{
    dispatch_barrier_async(_sendDataQueue, ^{
        [self->_sendDataArray insertObject:item atIndex:0];
    });
}
-(void)addLastItem:(id)item{
    dispatch_barrier_async(_sendDataQueue, ^{
        [self->_sendDataArray addObject:item];
    });
}
- (void)removeLastItem{
    dispatch_barrier_async(_sendDataQueue, ^{
        [self->_sendDataArray removeLastObject];
    });
}
- (id)lastItem{
    __block id obj;
    dispatch_sync(_sendDataQueue, ^{
        obj = self->_sendDataArray.lastObject;
    });
    return obj;
}
- (void)readCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid{
    if (did) {
        CBPeripheral *peripheral = self.deviceDic[did];
        CBCharacteristic *characteristic = _characteristicDic[[NSString stringWithFormat:@"%@-%@-%@",did,sid,cid]];
        if (peripheral&&characteristic) {
            [peripheral readValueForCharacteristic:characteristic];
            BTLog(@"读取特征值: %@",characteristic.UUID.UUIDString);
        }
        else{
            BTLog(@"读取失败 peripheral = %@，characteristic = %@",peripheral,characteristic);
        }
    }
    else{
        BTLog(@"did为空");
    }
}
- (void)removeAllDevice{
    [self.scanDic removeAllObjects];
    [self.deviceDic removeAllObjects];
    [self.characteristicDic removeAllObjects];
}
+ (void)initWithLog:(BOOL)isOpen options:(NSDictionary *)launchOptions{
    if (launchOptions) {
        [[GNBlueToothWork manager] initBlueToothWithOptions:launchOptions];
    }
    else{
        [[GNBlueToothWork manager] initBlueTooth];
    }
    [GNBlueToothWork manager]->_isShowLog = isOpen;
}
+ (void)printLogWithStr:(NSString *)string{
    if ([GNBlueToothWork manager]->_isShowLog) {
        NSLog(@"[app]%@",string);
    }
//    [[self manager] didPrintLog:string];
}

#pragma mark ---------------centralManager Delegate---------------
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBManagerStateUnknown:
            break;
        case CBManagerStateResetting:
            break;
        case CBManagerStateUnsupported:
            break;
        case CBManagerStateUnauthorized:
            break;
        case CBManagerStatePoweredOff:
            [self dataForCentralState:@{@"enable":[NSNumber numberWithBool:false]}];
            [self removeAllDevice];
            break;
        case CBManagerStatePoweredOn:{
            [self dataForCentralState:@{@"enable":[NSNumber numberWithBool:true]}];
            if (_isScan) {
                [self startScanWitnName:_searchName sids:_searchServiceIDs];
            }
        }
            break;
        default:
            break;
    }
    if (central.state != CBManagerStatePoweredOn) {
        [self dataForStatus:@{@"name":@"",@"did":@"",@"connectStatus":@"disconnected"}];
    }
}
- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict{
    BTLog(@"[per]willRestoreState");
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSString *deviceName = peripheral.name?peripheral.name:@"";
    if (RSSI.integerValue == 127) {
        return;
    }
    if (_searchName) {
        if (![deviceName hasPrefix:_searchName]) {
            return;
        }
    }
//    BTLog(@"扫描到设备 name = %@ uuid = %@ RSSI = %@",deviceName,peripheral.identifier.UUIDString,RSSI);
    NSMutableDictionary *advDic = [NSMutableDictionary dictionaryWithDictionary:advertisementData];
    [advDic setValue:RSSI forKey:@"rssi"];
    [advDic setValue:peripheral forKey:@"peripheral"];
    if (!self.scanDic[peripheral.identifier.UUIDString]) {
//        BTLog(@"扫描到新设备 %@",[self stringForJsonDic:[self advDicWithData:advDic]]);
        [self.scanDic setValue:peripheral forKey:peripheral.identifier.UUIDString];
    }
    [self dataForScan:advDic];
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSString *deviceName = peripheral.name?peripheral.name:@"";
    NSString *did = peripheral.identifier.UUIDString;
    [self.deviceDic setValue:peripheral forKey:did];
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    [self dataForStatus:@{@"name":deviceName,@"did":did,@"connectStatus":@"connected"}];
    BTLog(@"%@---连接成功",peripheral.name);
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSString *deviceName = peripheral.name?peripheral.name:@"";
    NSString *did = peripheral.identifier.UUIDString;
    [self dataForStatus:@{@"name":deviceName,@"did":did,@"connectStatus":@"connectfail"}];
    BTLog(@"%@---连接失败 error = %@",peripheral.name,error);
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSString *deviceName = peripheral.name?peripheral.name:@"";
    NSString *did = peripheral.identifier.UUIDString;
    if (self.deviceDic[did]) {
        [self.deviceDic removeObjectForKey:did];
    }
    [self dataForStatus:@{@"name":deviceName,@"did":did,@"connectStatus":@"disconnected"}];
    BTLog(@"%@---连接断开 error = %@",peripheral.name,error);
}

#pragma mark peripheral --------------------Delegate--------------------
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    [self dataForError:error did:@"" cid:@"" block:^{
        for (CBService *ser in peripheral.services) {
            [peripheral discoverCharacteristics:nil forService:ser];
        }
    }];
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    NSString *did = peripheral.identifier.UUIDString;
    NSString *sid = service.UUID.UUIDString;
    BTLog(@"服务 特征值 \ndid = %@ sid = %@ cids = %@",did,sid,service.characteristics);
    [self dataForError:error did:did cid:@"" block:^{
        for (CBCharacteristic *character in service.characteristics) {
            int propertie = ((int)[character properties]&0xf0);
            if (propertie == CBCharacteristicPropertyNotify||propertie == CBCharacteristicPropertyIndicate) {
                [peripheral setNotifyValue:YES forCharacteristic:character];
            }
            [self.characteristicDic setObject:character forKey:[NSString stringWithFormat:@"%@-%@-%@",did,sid,character.UUID.UUIDString]];
        }
    }];
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSString *did = peripheral.identifier.UUIDString;
    NSString *cid = characteristic.UUID.UUIDString;
    [self dataForError:error did:did cid:cid block:^{
        [self dataForRead:@{@"did":did,@"cid":cid,@"data":characteristic.value?characteristic.value:[NSData data]}];
        BTLog(@"通知数据 data = %@ cid = %@",characteristic.value,cid);
    }];
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSString *did = peripheral.identifier.UUIDString;
    NSString *cid = characteristic.UUID.UUIDString;
    [self dataForError:error did:did cid:cid block:^{
        //        [self dataForStatus:@{@"did":did,@"cid":cid,@"state":@"didWrite"}];
        BTLog(@"发送成功 cid = %@",cid);
    }];
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSString *did = peripheral.identifier.UUIDString;
    NSString *cid = characteristic.UUID.UUIDString;
    [self dataForError:error did:did cid:cid block:^{
        [self dataForNotify:@{@"did":did,@"cid":cid}];
        BTLog(@"通知状态 characteristic = %@",characteristic);
    }];
}
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral NS_AVAILABLE(NA, 6_0){
    BTLog(@"[per]peripheralDidUpdateName");
}
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices NS_AVAILABLE(NA, 7_0){
    BTLog(@"[per]didModifyServices");
}
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error NS_AVAILABLE(NA, 8_0){
    BTLog(@"[per]didReadRSSI");
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error{
    BTLog(@"[per]didDiscoverIncludedServicesForService");
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    BTLog(@"[per]didDiscoverDescriptorsForCharacteristic");
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    BTLog(@"[per]didUpdateValueForDescriptor");
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    BTLog(@"[per]didWriteValueForDescriptor");
}

#pragma mark ---------------数据通知---------------
- (void)dataForCentralState:(NSDictionary *)dataDic{
    [self observeRespondsToSelector:@selector(dataForCentralState:) block:^(id delegate) {
        [delegate dataForCentralState:dataDic];
    }];
}
- (void)dataForScan:(NSDictionary *)dataDic{
    [self observeRespondsToSelector:@selector(dataForScan:) block:^(id delegate) {
        [delegate dataForScan:dataDic];
    }];
}
- (void)dataForStatus:(NSDictionary *)dataDic{
    [self observeRespondsToSelector:@selector(dataForStatus:) block:^(id delegate) {
        [delegate dataForStatus:dataDic];
    }];
}
- (void)dataForNotify:(NSDictionary *)dataDic{
    [self observeRespondsToSelector:@selector(dataForNotify:) block:^(id delegate) {
        [delegate dataForNotify:dataDic];
    }];
}
- (void)dataForRead:(NSDictionary *)dataDic{
    [self observeRespondsToSelector:@selector(dataForRead:) block:^(id delegate) {
        [delegate dataForRead:dataDic];
    }];
}
- (void)didPrintLog:(NSString *)logString{
    [self observeRespondsToSelector:@selector(didPrintLog:) block:^(id delegate) {
        [delegate didPrintLog:logString];
    }];
}
- (void)dataForError:(nullable NSError *)error did:(NSString *)did cid:(NSString *)cid block:(void(^)(void))block{
    if (!error) {
        block();
    }
    else{
        [self dataForStatus:@{@"did":did,@"cid":cid,@"state":@"error",@"data":[NSString stringWithFormat:@"%@",error.userInfo]}];
        BTLog(@"[error] cid = %@ error = %@",cid,error);
    }
}

#pragma mark --------------------init--------------------
static  id _instance = nil;
+ (GNBlueToothWork *)manager{
    return [self shareManager];
}
+ (instancetype)shareManager{
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    return _instance;
}
+ (id)allocWithZone:(NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
- (NSMutableDictionary *)scanDic{
    if (!_scanDic) {
        _scanDic = [NSMutableDictionary dictionary];
    }
    return _scanDic;
}
- (NSMutableDictionary *)deviceDic{
    if (!_deviceDic) {
        _deviceDic = [NSMutableDictionary dictionary];
    }
    return _deviceDic;
}
- (NSMutableDictionary *)characteristicDic{
    if (!_characteristicDic) {
        _characteristicDic = [NSMutableDictionary dictionary];
    }
    return _characteristicDic;
}
- (NSMutableArray *)observeArr{
    if (!_observeArr) {
        _observeArr = [NSMutableArray array];
    }
    return _observeArr;
}

#pragma mark -----------------delegate---------------
- (void)addObserve:(id)observe{
    if (!observe) { return;}
    if (![self.observeArr containsObject:observe]) {
        [self.observeArr addObject:observe];
    }
    BTLog(@"self.observeArr %@",self.observeArr);
}
- (void)removeObserve:(id)observe{
    if (!observe) {return;}
    if ([self.observeArr containsObject:observe]) {
        [self.observeArr removeObject:observe];
    }
    BTLog(@"self.observeArr %@",self.observeArr);
}
- (void)removeObserveWithClass:(Class)class{
    NSArray *array = self.observeArr;
    for (id observe in array) {
        if ([observe isKindOfClass:class]) {
            if ([self.observeArr containsObject:observe]) {
                [self.observeArr removeObject:observe];
            }
        }
    }
}
- (void)observeRespondsToSelector:(SEL)aSelector block:(void(^)(id delegate))block{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id observeDelegate in self.observeArr) {
            if ([observeDelegate respondsToSelector:aSelector]) {
                block(observeDelegate);
            }
        }
    });
}

#pragma mark Tool
- (NSString *)stringForArray:(NSArray *)array{
    return [array componentsJoinedByString:@","];
}
- (NSMutableDictionary *)advDicWithData:(NSDictionary *)advData{
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
    for (id key in advData.allKeys) {
        id data = advData[key];
        if ([data isKindOfClass:[NSDictionary class]]) {
            [tempDic setObject:[self advDicWithData:data] forKey:[NSString stringWithFormat:@"%@",key]];
        }
        else if ([data isKindOfClass:[NSArray class]]){
            [tempDic setObject:[self advArrWithData:data] forKey:[NSString stringWithFormat:@"%@",key]];
        }
        else if ([data isKindOfClass:[NSData class]]){
            [tempDic setObject:[self stringWithData:data] forKey:[NSString stringWithFormat:@"%@",key]];
        }
        else if ([data isKindOfClass:[CBUUID class]]){
            [tempDic setObject:[(CBUUID *)data UUIDString] forKey:[NSString stringWithFormat:@"%@",key]];
        }
        else{
            [tempDic setObject:[NSString stringWithFormat:@"%@",data] forKey:[NSString stringWithFormat:@"%@",key]];
        }
    }
    return tempDic;
}
- (NSArray *)advArrWithData:(NSArray *)advData{
    NSMutableArray *tempArr = [NSMutableArray array];
    for (id data in advData) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            [tempArr addObject:[self advDicWithData:data]];
        }
        else if ([data isKindOfClass:[NSArray class]]){
            [tempArr addObject:[self advArrWithData:data]];
        }
        else if ([data isKindOfClass:[NSData class]]){
            [tempArr addObject:[self stringWithData:data]];
        }
        else if ([data isKindOfClass:[CBUUID class]]){
            [tempArr addObject:[(CBUUID *)data UUIDString]];
        }
        else{
            [tempArr addObject:data];
        }
    }
    return tempArr;
}
- (NSString *)stringWithData:(NSData *)data{
    if (data) {
        Byte *byte = (Byte *)[data bytes];
        NSString *string = [NSString new];
        for (int i=0; i<data.length; i++) {
            NSString *tempStr = [NSString stringWithFormat:@"%02X",byte[i]];
            string = [string stringByAppendingString:tempStr];
        }
        return [string uppercaseString];
    }
    else{
        return @"";
    }
}
- (NSString *)stringForJsonDic:(NSDictionary *)jsonDic{
    if (!jsonDic) {
        return @"";
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        BTLog(@"%@",error);
        return @"";
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}
+ (NSString *)macStringWithData:(NSData *)data{
    if (data) {
        Byte *value = (Byte *)[data bytes];
        NSMutableString *tempMacStr = [NSMutableString string];
        for (int i = 0; i < data.length; i++) {
            [tempMacStr appendFormat:@"%02x",value[i]];
        }
        return [tempMacStr uppercaseString];
    }
    else{
        return @"";
    }
};


@end

