//
//  SomeSDK_h4p.h
//  H4pDemo
//
//  Created by MeterWhite on 2021/4/22.
//

#import <Foundation/Foundation.h>

/**
 * 拷贝目标文件并添加正确的方法名后缀在目标方法后，即可修改任意Cocoapods的源代码。
 *
 * 如何理解改SDK的行为
 * Objc是消息机制，继承没有消息重要。
 */

NS_ASSUME_NONNULL_BEGIN

/// 标识要修改的类型
@interface SomeSDK_h4p : NSObject

@property (nullable,nonatomic,copy) NSString *myString;

- (void)myMethod;

@end

NS_ASSUME_NONNULL_END
