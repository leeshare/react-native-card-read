//
//  CardModule.m
//  CardModule
//
//  Created by wj on 2018/8/12.
//  Copyright © 2018年 hc. All rights reserved.
//

#import "CardModule.h"
#import <React/RCTEventDispatcher.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureDevice.h>

#import <objc/runtime.h>

#import "CardDialog.h"

//蓝牙扫描
//#import "BlueToothViewController.h"
#import <STIDCardReader/STIDCardReader.h>
#import "BlueManager.h"

#pragma mark - const values

#pragma mark -

@interface CardModule (){
    NSTimer *_timer; //定时器
    NSInteger countDown;  //倒计时
    
    STIDCardReader *scaleManager;
    NSMutableArray *deviceList;
}

@property(nonatomic,strong)CardDialog *pick;


@end


@implementation CardModule

@synthesize bridge = _bridge;
RCTResponseSenderBlock _callback;

RCT_EXPORT_MODULE();

//功能列表
//1 设备列表
//2 点击某一个设备进行 蓝牙连接
//3 蓝牙读卡
//4 获取到的图片信息 得到。

//1 获取并返回一个设备列表
RCT_EXPORT_METHOD(show_peripher_list: (RCTResponseSenderBlock)callback){
    _callback = callback;
    //NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    
    /**
     *  <#Description#>
     */
    if(UDValue(SERVER)== nil){
        SETUDValue(@"senter-online.cn", SERVER);
    }
    
    if(UDValue(PORT) == nil){
        SETUDValue(@"10002", PORT);
    }
    scaleManager = [STIDCardReader instance];
    //scaleManager.delegate = (id)self;
    [scaleManager setServerIp:UDValue(SERVER) andPort:[UDValue(PORT) intValue]];
    
    //[self setRightNavbarHide:NO];
    //[self setRightNavbarImage:nil withTitle:@"扫描" withImageLeft:NO];
    
    BlueManager *manager = [BlueManager instance];
    //manager.deleagte = (id)self;
    [manager startScan];
    
}


RCT_EXPORT_METHOD(connect_peripher: (NSDictionary *)options){
    NSString *standardTxt = @"";
    if ([options count] != 0) {
        standardTxt = options[@"standardTxt"];
    }
    
    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    [dic setValue:@"confirm" forKey:@"type"];
    [dic setValue:@"2" forKey:@"peripherResult"];
    //_pick.bolock(dic);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.bridge.eventDispatcher sendAppEventWithName:@"confirmEvent" body:dic];
    });
}

//------------------------------------------
#pragma mark BlueManagerDelegate
//蓝牙扫描回调
- (void)didFindNewPeripheral:(STMyPeripheral *)periperal{
    if(deviceList == nil){
        deviceList = [[NSMutableArray alloc] init];
    }
    if(deviceList != nil){
        if([deviceList count] == 0){
            [deviceList addObject:periperal];
            //[self.table reloadData];
        }else{
            BOOL isexit = NO;
            for (uint8_t i = 0; i < [deviceList count]; i++) {
                STMyPeripheral *myPeripherali = [deviceList objectAtIndex:i];
                if(myPeripherali != nil){
                    if([periperal.advName isEqualToString:myPeripherali.advName] && [periperal.mac isEqualToString:myPeripherali.mac]){
                        isexit = YES;
                        break;
                    }
                }
            }
            if(!isexit){
                [deviceList addObject:periperal];
                //[self.table reloadData];
            }
        }
    }
    //    if(![deviceList containsObject:periperal]){
    //        [deviceList addObject:periperal];
    //        [self.table reloadData];
    //    }
    
    
    //[self.bridge.eventDispatcher sendDeviceEventWithName:@"RNUploaderDidFailWithError" body:[error localizedDescription]];
    //_callback(@[[error localizedDescription], [NSNull null]]);
    
    //[self.bridge.eventDispatcher sendDeviceEventWithName:@"ReturnPeripherList" body:nil];
    //_callback(deviceList);
    
    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    [dic setValue:@"confirm" forKey:@"type"];
    [dic setValue:deviceList forKey:@"peripherResult"];
    //_pick.bolock(dic);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bridge.eventDispatcher sendAppEventWithName:@"confirmEvent" body:dic];
    });

}

//------------------------------------------

//测试用  弹出 对话框
RCT_EXPORT_METHOD(alert:(NSString *)message){
    //alert
    
    NSString *title = NSLocalizedString(@"", nil);
    NSString *message2 = NSLocalizedString(message, nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message2 preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert's cancel action occured.");
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert's other action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:cancelAction];
    [alertController addAction:otherAction];
    
    //[self presentViewController:alertController animated:YES completion:nil];
    [self.class presentViewController:alertController animated:YES completion:nil];
}

RCT_EXPORT_METHOD(checkPermissionCamera: (RCTResponseSenderBlock)callback){
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        //无权限
        [output setValue:@(FALSE) forKey:@"is_success"];
    }else {
        [output setValue:@(TRUE) forKey:@"is_success"];
    }
    callback(@[output]);
}

RCT_EXPORT_METHOD(checkPermissionMic: (RCTResponseSenderBlock)callback){
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        //无权限
        [output setValue:@(FALSE) forKey:@"is_success"];
    }else {
        [output setValue:@(TRUE) forKey:@"is_success"];
    }
    callback(@[output]);
}

RCT_EXPORT_METHOD(openSettings:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (@(UIApplicationOpenSettingsURLString != nil)) {
        
        NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
        id __block token = [center addObserverForName:UIApplicationDidBecomeActiveNotification
                                               object:nil
                                                queue:nil
                                           usingBlock:^(NSNotification *note) {
                                               [center removeObserver:token];
                                               resolve(@YES);
                                           }];
        
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}


@end
