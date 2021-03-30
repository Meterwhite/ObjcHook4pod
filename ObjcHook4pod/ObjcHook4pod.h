//
//  ObjcHook4pod.h
//  ObjCHook4pod
//
//  Created by MeterWhite on 2021/2/25.
//  Copyright © 2021 Meterwhite. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 解决问题：想修改CocoaPods代码又想每次更新版本使用最新功能。此开源库以文件的方式侵入源码，实现重写目标类的指定方法，添加目标类的新属性，甚至更换目标类的基类。
 * 1. 拷贝目标类文件
 * 2. 在类名增加后缀'_h4p'(是ObjcHook4pod的缩写)；
 * 3. 在方法名增加后缀'_h4m'则作为钩子替换原方法；
 * 4. 添加一个后缀为'_a2p'的属性可以为目标类添加一个示例属性，并且支持weak,strong,copy；
 * 5. 如果需要替换目标类的基类可以指定你的类型的基类为相异类型；
 *
 * Destination File
 * Class : Super {
 *   method { ... }
 *   ... ...
 * }
 *
 * My File
 * Class_hook4pod : NewSuper(If need) {
 *   @property (weak | strong | copy) property_a2p;
 *   ... ...
 *   method_hook4pod { self.property_a2p = ... }
 * }
 */
@interface ObjcHook4pod : NSObject

/// 该方法是同步执行的，请手动触发
+ (void)runtimeWork;

@end

