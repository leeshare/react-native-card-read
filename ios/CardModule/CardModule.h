//
//  CardModule.h
//  CardModule
//
//  Created by wj on 2018/8/12.
//  Copyright © 2018年 hc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>
//#import <STIDCardReader/STIDCardReader.h>
#import <STIDCardReader/STMyPeripheral.h>

//#define ERROR
#define UDValue(key) [[NSUserDefaults standardUserDefaults]objectForKey:key]
#define SETUDValue(value,key) [[NSUserDefaults standardUserDefaults] setObject:value forKey:key]

#define SERVER @"SERVERIP"  //@"192.168.1.10"//@"222.134.70.138" //
#define PORT @"SERVERPORT" //10002//8088 //

@interface CardModule : NSObject <RCTBridgeModule> {
    NSString * lb_begintime;
    NSString * lb_endtime;
    int successrcount;
    int failcount;
    Boolean isStartRead;
}
- (NSString *)getTimeNow;

-(void) startScareCard;
-(void) disconnectCurrentPeripher:(STMyPeripheral *)peripheral;
-(void) dealyReadCard;

@end
