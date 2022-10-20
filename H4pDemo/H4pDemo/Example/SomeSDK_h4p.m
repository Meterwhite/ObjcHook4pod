//
//  SomeSDK_h4p.m
//  H4pDemo
//
//  Created by MeterWhite on 2021/4/22.
//

#import "SomeSDK_h4p.h"

@interface SomeSDK_h4p ()

@property (nullable,nonatomic,copy) NSString *internalString;

/// 增加一个属性
@property (nullable,nonatomic,copy) NSString *addStringProperty_a2p;

@end

@implementation SomeSDK_h4p

#pragma mark - Your new code

/// 标识要修改的方法
- (void)myMethod1_h4m {
    /// self是SomeSDK类型，SomeSDK_h4p在真实运行环境中并不存在
    
    /// NSLog(@"%@", _myString);
    /// =>
    NSLog(@"%@", [self valueForKey:@"_myString"]); // KVC确保访问到原始变量
}

/// 标识要修改的方法
- (void)myMethod2_h4m {
    [self myMethod];
    self.addStringProperty_a2p = @"123"; // 访问新增变量
}

#pragma mark - Original code

- (void)myMethod1 {
    NSLog(@"%@", _myString);
}

- (void)myMethod2 {
    [self myMethod];
}

@end
