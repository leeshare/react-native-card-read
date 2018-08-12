//
//  CardModule.m
//  CardModule
//
//  Created by wj on 2018/8/12.
//  Copyright © 2018年 hc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardModule.h"
#import <React/RCTEventDispatcher.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureDevice.h>

#import <objc/runtime.h>

#import "CardDialog.h"

#pragma mark - const values

#pragma mark -

@interface CardModule (){
    NSTimer *_timer; //定时器
    NSInteger countDown;  //倒计时
}

@property(nonatomic,strong)CardDialog *pick;


@end


@implementation CardModule

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

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



@end