//
//  GNBlueToothWork.h
//  GNBlueToothWork
//
//  Created by Huasali on 2018/12/18.
//  Copyright © 2018 JH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define GNLog(fmt, ...) \
[GNBlueToothWork printLogWithStr:[NSString stringWithFormat:fmt,##__VA_ARGS__]];\

#define BTLog(fmt, ...)     GNLog((@"[BLE]"fmt),##__VA_ARGS__);

@protocol GNBlueToothDelegate <NSObject>
@optional

/// 蓝牙的状态
/// @param dataDic 数据
- (void)dataForCentralState:(NSDictionary *)dataDic;
/// 扫描的回调
/// @param dataDic 数据
- (void)dataForScan:(NSDictionary *)dataDic;
/// 设备的状态
/// @param dataDic 数据
- (void)dataForStatus:(NSDictionary *)dataDic;
/// 通知的回调
/// @param dataDic 数据
- (void)dataForNotify:(NSDictionary *)dataDic;
/// 读取数据的回调
/// @param dataDic 数据
- (void)dataForRead:(NSDictionary *)dataDic;
/// log输出
/// @param logString log
- (void)didPrintLog:(NSString *)logString;
@end

@interface GNBlueToothWork : NSObject{
@public CBCentralManager *_centralManager;
}
/// 扫描到的设备
@property (nonatomic, strong) NSMutableDictionary *scanDic;
/// 已连接的设备
@property (nonatomic, strong) NSMutableDictionary *deviceDic;
/// 已连接的特征值
@property (nonatomic, strong) NSMutableDictionary *characteristicDic;

/// 初始化
+ (GNBlueToothWork *)manager;

/// 初始化参数
/// @param isOpen 打开日志
/// @param launchOptions APP启动时参数
+ (void)initWithLog:(BOOL)isOpen options:(NSDictionary *)launchOptions;

///log
+ (void)printLogWithStr:(NSString *)string;

/// 添加代理事件
/// @param observe 代理
- (void)addObserve:(id <GNBlueToothDelegate>)observe;

/// 移除代理
/// @param observe 代理
- (void)removeObserve:(id)observe;
- (void)removeObserveWithClass:(Class)class;

/// 初始化蓝牙
/// @param launchOptions 初始化参数
- (void)initBlueToothWithOptions:(NSDictionary *)launchOptions;
- (void)initBlueTooth;

/// 扫描蓝牙设备
/// @param name 名称过滤 空则不过滤
/// @param sids 服务ID过滤 空则不过滤
- (void)startScanWitnName:(NSString *)name sids:(NSArray *)sids;

/// 停止扫描
- (void)stopScan;

/// 蓝牙是否打开
- (BOOL)isOpenBlueTooth;
/// 已连接的设备
- (CBPeripheral *)peripheralForConnected:(NSString *)sid did:(NSString *)did;
/// 连接蓝牙设备
/// @param did 设备的uuid
- (void)connectDeviceWithDid:(NSString *)did;
/// 清除断开设备的标志
/// @param did 设备的uuid
- (void)clearDisconnectDid:(NSString *)did;

/// 断开指定的设备
/// @param sid 服务的id
- (void)disConnectDeviceWithSid:(NSString *)sid;
/// 断开指定的设备
/// @param did 设备的uuid
- (void)disconnectWithDid:(NSString *)did;

/// 断开指定外的设备
/// @param did 设备的uuid
- (void)disConnectWithOutDid:(NSString *)did;

/// 断开所有的设备
- (void)disConnectAll;

/// 获取最大写数据大小
/// @param did 设备uuid
/// @param type 写类型
- (int)numForWriteValueLengthDid:(NSString *)did type:(CBCharacteristicWriteType)type;

/// 发送数据
/// @param did 设备uuid
/// @param sid 设备读物id
/// @param cid 设备的特征值id
/// @param data 发送的数据
/// @param type 发送的类型 响应或者不响应
- (void)writeCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid data:(NSData *)data type:(CBCharacteristicWriteType)type;

/// 队列发送
/// @param time 数据包之间的间隔
- (void)writeCacheCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid data:(NSData *)data type:(CBCharacteristicWriteType)type time:(float)time;
/// 读取数据
/// @param did 设备uuid
/// @param sid 设备读物id
/// @param cid 设备的特征值id
- (void)readCharacteristicWithDid:(NSString *)did sid:(NSString *)sid cid:(NSString *)cid;


@end
