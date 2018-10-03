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

//蓝牙扫描
//#import "BlueToothViewController.h"
#import <STIDCardReader/STIDCardReader.h>
#import "BlueManager.h"
#import <STIDCardReader/STMyPeripheral.h>


#define DDEBUG
@interface CardModule (){
    NSTimer *_timer; //定时器
    NSInteger countDown;  //倒计时

    STIDCardReader *scaleManager;       //蓝牙扫描函数
    NSMutableArray *deviceList;     //蓝牙列表
}

@property CBCentralManager *cm;
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

//0 初始化
RCT_EXPORT_METHOD(init: (NSDictionary *)options){
    successrcount = 0;
    failcount = 0;
    [[STIDCardReader instance] setDelegate:self];
    
    /**
     *  <#Description#>
     */
    //if(UDValue(SERVER)== nil){
    SETUDValue(@"senter-online.cn", SERVER);
    //}
    
    //if(UDValue(PORT) == nil){
    SETUDValue(@"10002", PORT);
    //}
    scaleManager = [STIDCardReader instance];
    scaleManager.delegate = (id)self;
    [scaleManager setServerIp:UDValue(SERVER) andPort:[UDValue(PORT) intValue]];
}

//1 获取并返回一个设备列表
RCT_EXPORT_METHOD(show_peripher_list: (NSDictionary *)options){
    
    //[[STIDCardReader instance] setDelegate:self];
    
    
    //_callback = callback;
    //NSMutableDictionary *output = [[NSMutableDictionary alloc] init];


    BlueManager *manager = [BlueManager instance];
    manager.deleagte = (id)self;
    [manager startScan];
}

//2 点击某一个设备进行 蓝牙连接
RCT_EXPORT_METHOD(connect_peripher: (NSDictionary *)options){
    NSString *peripherMac = @"";
    if ([options count] != 0) {
        peripherMac = options[@"mac"];
    }
    isStartRead = false;
    
    STMyPeripheral * peripher;
    if([deviceList count] > 0){
        for (int i = 0; i < deviceList.count; i++)
        {
            peripher = [deviceList objectAtIndex:i];
            if([peripher.mac isEqualToString:peripherMac]){
                break;
            }
        }
    }
    
    if(peripher != nil){
        [[BlueManager instance] stopScan];
        NSLog(@"点选设备,开始连接蓝牙设备");
        lb_begintime = [self getTimeNow];
        //先建立连接，连接上以后 传给SDK
        BlueManager *bmanager = [BlueManager instance];
        //bmanager.linkedPeripheral = peripheral;
        bmanager.linkedPeripheral = peripher;
        [bmanager connectPeripher:peripher];
    }
}

//3 蓝牙读卡
RCT_EXPORT_METHOD(read_card_info: (NSDictionary *)options){
    isStartRead = true;
    [self startScareCard];
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
            if(periperal.advName == nil || [periperal.advName isEqualToString:@""] || periperal.mac == nil || [periperal.mac isEqualToString:@""]){
            }else {
                [deviceList addObject:periperal];
            }
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
                if(periperal.advName == nil || [periperal.advName isEqualToString:@""] || periperal.mac == nil || [periperal.mac isEqualToString:@""]){
                }else{
                    [deviceList addObject:periperal];
                }
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
    
    NSString *strs = @"";
    
    for (int i = 0; i < deviceList.count; i++)
    {
        STMyPeripheral * peripher = [deviceList objectAtIndex:i];
        if(peripher.advName == nil || [peripher.advName isEqualToString:@""] || peripher.mac == nil || [peripher.mac isEqualToString:@""]){
            
        }else {
            strs = [[[strs stringByAppendingString:peripher.advName] stringByAppendingString:@"H-C"] stringByAppendingString:peripher.mac];
            strs = [strs stringByAppendingString:@"H,C"];
        }
    }

    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    [dic setValue:@"confirm" forKey:@"type"];
    [dic setValue:@"1" forKey:@"peripherType"];
    //[dic setValue:deviceList forKey:@"peripherResult"];
    [dic setValue:strs forKey:@"peripherResult"];
    //_pick.bolock(dic);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bridge.eventDispatcher sendAppEventWithName:@"confirmEvent" body:dic];
    });

}
//连接设备的回调，成功 error为nil
- (void)connectperipher:(STMyPeripheral *)peripheral withError:(NSError *)error{
    NSString *type;
    NSString *result;
    if(error){
        NSString *errMsg = [NSString stringWithFormat:@"错误代码:%ld,错误信息:%@!", (long)[error code], [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:errMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        
        type = @"-2";
        result = [@"连接失败:" stringByAppendingString:[error localizedDescription]];
    }else{
        NSLog(@"已连接上 %@",peripheral.advName);
        [scaleManager setLisentPeripheral:peripheral];          //设置SDK的监听蓝牙设备
        lb_endtime = [self getTimeNow];
        NSString *msg = [NSString stringWithFormat:@"已连接上 %@,开始时间 %@,结束时间 %@",peripheral.advName,lb_begintime,lb_endtime];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        
//        if(isStartRead){
            [[STIDCardReader instance] setDelegate:(id)self];
            [[STIDCardReader instance] setLisentPeripheral:peripheral];
            [[STIDCardReader instance] startScaleCard];
//        }else {
//            [alert show];
//        }
        
        type = @"2";
        result = [[peripheral.advName stringByAppendingString:@"H-C"] stringByAppendingString:peripheral.mac];
    }
    
    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    [dic setValue:@"confirm" forKey:@"type"];
    [dic setValue:type forKey:@"peripherType"];
    [dic setValue:result forKey:@"peripherResult"];
    //_pick.bolock(dic);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bridge.eventDispatcher sendAppEventWithName:@"confirmEvent" body:dic];
    });
}

#pragma ScaleDelegate
- (void)failedBack:(STMyPeripheral *)peripheral withError:(NSError *)error{
    //[progressView stopAnimating];
    
    if(error){
        //DLog(@"aaa");
        failcount++;
        NSString *countstr = [[NSString alloc] initWithFormat:@"成功:%d次,失败:%d次",successrcount,failcount];
        //[counttotal setText:countstr];
        NSString *errMsg = [NSString stringWithFormat:@"错误代码:%ld,错误信息:%@!", (long)[error code], [error localizedDescription]];
        
        //[lb_error setText:errMsg];
        NSLog(errMsg);
        
        NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
        [dic setValue:@"confirm" forKey:@"type"];
        [dic setValue:@"-3" forKey:@"peripherType"];
        [dic setValue:errMsg forKey:@"peripherResult"];
    }
}

- (void)successBack:(STMyPeripheral *)peripheral withData:(id)data{
    
    id result;
    if(data && [data isKindOfClass:[NSDictionary class]]){
        
        //--新增 flag == 49 说明是外国人永久居住身份证
        if([[data objectForKey:@"flag"]  isEqual: @"49"]){
            //-----外国人永久居留身份证----
            //[lb_name setText:[data objectForKey:@"EnglishName"]];       //英文名字
            //[lb_name setText:[data objectForKey:@"chinaname"]];         //中文名字
            
            NSString *allname = [NSString stringWithFormat:@"%@-%@",[data objectForKey:@"EnglishName"],[data objectForKey:@"chinaname"]];
            //[lb_name setText:allname];         //英文名字-中文名字
            
            //[lb_sex setText:[data objectForKey:@"Sex"]];
            
            //[lb_nation setText:[data objectForKey:@"Conuntry"]];
            
            //[lb_birth setText:[data objectForKey:@"Born"]];
            
            //[lb_address setText:[data objectForKey:@"CardVer"]];    //证件版本号
            
            //[lb_card setText:[data objectForKey:@"CardNo"]];        //证件号码
            
            //[lb_organization setText:[data objectForKey:@"IssuedAt"]];
            
        }else{
            //[lb_name setText:[data objectForKey:@"Name"]];
            
            //[lb_sex setText:[data objectForKey:@"Sex"]];
            
            //[lb_nation setText:[data objectForKey:@"Nation"]];
            
            //[lb_birth setText:[data objectForKey:@"Born"]];
            
            //[lb_address setText:[data objectForKey:@"Address"]];
            
            //[lb_card setText:[data objectForKey:@"CardNo"]];
            
            //[lb_organization setText:[data objectForKey:@"IssuedAt"]];
        }
        
        
        //[lb_etime setText:[self getTimeNow]];
        
        NSString *date = [NSString stringWithFormat:@"%@-%@",[data objectForKey:@"EffectedDate"],[data objectForKey:@"ExpiredDate"]];
        
        //[lb_date setText:date];
        
        NSString *devnum = [[STIDCardReader instance] getSerialNumber];
        NSLog(@"获取到的设备的序列号: %@",devnum);
        
        result = data;
        
    }else if (data &&[data isKindOfClass:[NSData class]]){
        
        UIImage *img = [UIImage imageWithData:data];
        
        NSString *imageBase64Str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        
        //[headerView setImage:img];
        //[progressView stopAnimating];
        
        successrcount++;
        NSString *countstr = [[NSString alloc] initWithFormat:@"成功:%d次,失败:%d次",successrcount,failcount];
        //[counttotal setText:countstr];
        //[lb_error setText:@"读卡成功!"];
        //----照片解析出来之后，发送断开蓝牙的指令，如果想要保持长连接，可以不关闭蓝牙连接----
        [self disconnectCurrentPeripher:peripheral];
        
        result = imageBase64Str;
    }
    
    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    [dic setValue:@"confirm" forKey:@"type"];
    [dic setValue:@"30" forKey:@"peripherType"];
    [dic setValue:result forKey:@"peripherResult"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bridge.eventDispatcher sendAppEventWithName:@"confirmEvent" body:dic];
    });
    
}

-(void)startScareCard{
    BlueManager *bmanager = [BlueManager instance];
    bmanager.deleagte = (id)self;
    if(bmanager.linkedPeripheral == nil){
        //[lb_error setText:@"请先选中要连接的蓝牙设备!"];
        //[progressView stopAnimating];
        
        NSString *msg = @"请先选中要连接的蓝牙设备!";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }else{
        if(bmanager.linkedPeripheral.peripheral.state != CBPeripheralStateConnected){
            NSLog(@"蓝牙处于未连接状态,先连接蓝牙!");
            [[BlueManager instance] connectPeripher:bmanager.linkedPeripheral];
        }else{
            NSLog(@"蓝牙处在连接状态,直接进行读卡的操作!");
            [[STIDCardReader instance] setDelegate:(id)self];
            [[STIDCardReader instance] startScaleCard];
        }
    }
    
}

//--MainVewi中断开蓝牙的连接，在读卡成功或者失败的时候都要执行断开的操作
-(void) disconnectCurrentPeripher:(STMyPeripheral *)peripheral{
    NSLog(@"MainView进入断开蓝牙的操作!");
    if(peripheral.peripheral.state == CBPeripheralStateConnected){
        NSLog(@"蓝牙处于连接状态,需要关闭!");
        BlueManager *bmanager = [BlueManager instance];
        bmanager.deleagte = (id)self;
        [bmanager disConnectPeripher:peripheral];
    }
}

-(void) dealyReadCard{
    //[[STIDCardReader instance] setDelegate:(id)self];
    //[[STIDCardReader instance] setLisentPeripheral:peripheral];
    //[[STIDCardReader instance] startScaleCard];
}

- (NSString*)getTimeNow{
    NSString* date;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSS"];
    date = [formatter stringFromDate:[NSDate date]];
    NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
    
    return timeNow;
}

//------------------------------------------

/*
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
*/

@end
