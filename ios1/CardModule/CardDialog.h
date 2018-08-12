//
//  CardDialog.h
//  CardModule
//
//  Created by admin on 2018/8/2.
//  Copyright © 2018年 Erdem Başeğmez. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)


typedef void(^backBolock)(NSDictionary * );

@interface CardDialog : UIView<UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong,nonatomic)UIPickerView *pick;

@property(nonatomic,copy)backBolock bolock;

//创建一个数组来传递返回的值
@property(nonatomic,strong)NSString *backString;

-(instancetype)initWithFrame:(CGRect)frame;

@end
