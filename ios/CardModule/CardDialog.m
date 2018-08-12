//
//  CardDialog.m
//  CardModule
//
//  Created by admin on 2018/8/2.
//  Copyright © 2018年 Erdem Başeğmez. All rights reserved.
//

#import "CardDialog.h"
#define linSpace 5

@implementation CardDialog

-(instancetype)initWithFrame:(CGRect)frame

{
    self = [super initWithFrame:frame];
    if (self)
    {
        
    }
    return self;
}

//按了确定按钮
-(void)cfirmAction
{
    NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
    
    if (self.backString != nil && self.backString != NULL) {
        
        [dic setValue:@"confirm" forKey:@"type"];
        NSMutableArray *arry=[[NSMutableArray alloc]init];
        [dic setValue:self.backString forKey:@"voiceResult"];
        
        self.bolock(dic);
        
    }else{
        [self getNOselectinfo];
        [dic setValue:self.backString forKey:@"voiceResult"];
        [dic setValue:@"confirm" forKey:@"type"];
        
        self.bolock(dic);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.2f animations:^{
            
            [self setFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 250)];
        }];
    });
    
}

-(void)getNOselectinfo
{
    self.backString = @"";
}


@end
