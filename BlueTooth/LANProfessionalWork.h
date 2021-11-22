//
//  LANProfessionalWork.h
//  BlueToothManager
//
//  Created by Huasali on 2021/11/22.
//

#import <Foundation/Foundation.h>

#define LANLog(fmt, ...)     GNLog((@"[LAN]"fmt),##__VA_ARGS__);

NS_ASSUME_NONNULL_BEGIN

@interface LANProfessionalWork : NSObject


/// 初始化sdk
/// @param isOpen 是否打开日志
/// @param launchOptions APP初始化参数
+ (LANProfessionalWork *)initWithLog:(BOOL)isOpen options:(nullable NSDictionary *)launchOptions;
- (void)stopWork;
/// 开始扫描 GN设备
- (void)startScanGNDevice:(nullable void(^)(NSDictionary *object))completion;
/// 停止扫描
- (void)stopScan;
/// 连接指定的设备
/// @param udid 设备id
- (void)connectDevice:(NSString *)udid;
/// 断开指定的设备
/// @param udid 设备id
- (void)disconnectWithUdid:(NSString *)udid;

@end

NS_ASSUME_NONNULL_END
