//
//  SomeSDK_h4p.h
//  H4pDemo
//
//  Created by MeterWhite on 2021/4/22.
//

#import <Foundation/Foundation.h>

/**
 * 拷贝你的目标文件过来添加后缀。你为什么要这样子做？
 * 这样模拟编程上下文环境省只需要少量改的即可，你知道继承会面对父类的屏蔽，拖进去改又不能跟随最新版本。单方面Runtime入侵，维护困难。
 *
 * 如何理解改SDK的行为
 * Objc是消息机制，继承没有消息重要，消息的发送是可以改变的，这便改变了最终方法的目的地，也轻易的打破了继承的稳定性。
 */

NS_ASSUME_NONNULL_BEGIN

@interface SomeSDK_h4p : NSObject

@property (nullable,nonatomic,copy) NSString *myString;

- (void)myMethod_h4m;


@end

NS_ASSUME_NONNULL_END
