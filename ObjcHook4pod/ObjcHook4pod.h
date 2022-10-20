//
//  ObjcHook4pod.h
//  ObjCHook4pod
//
//  Created by MeterWhite on 2021/2/25.
//  Copyright © 2021 Meterwhite. All rights reserved.
//  https://github.com/Meterwhite/ObjcHook4pod
//

#import <Foundation/Foundation.h>

/**
 *
 * Destination File
 * Class : Super {
 *   property_super
 *   method_super { ... }
 *   ... ...
 * }
 *
 * My File
 * Class_h4p : NewSuper(If need) {
 *   property_super
 *   @property (weak | strong | copy) propertyNew_a2p;
 *   ... ...
 *   
 *   method_super_h4m {
 *      /// 不应在方法内调用任何后缀为'_h4m'的方法，h4m方法只提供函数实现的地址不向目标类型增加方法名。
 *      self.property_a2p = ...
 *      [self setValueForKey:@"_property_super"]; /// Access Ivar。访问成员变量请使用属性或者KVC，无法使用下划线形式。
 *      id value = self.property_super; /// Access Ivar or property。
 *   }
 *   methodNew_a2m {
 *      /// 使用h2m方法增加方法。在文件外调用编译器无法提示，可以通过performSelector等runtime形式调用
 *      self.property_a2p = ...
 
 *   }
 * }
 *
 * 如果继承了修改过父类的类型，而你需要在编译器中访问真的的父类的方法和属性可以使用宏定义在类定义中声明
 * If you inherit a class from a hooked class, and you need access to the real properties and methods, the methods and properties can be declared in the class definition using the macro definition.
 * Class_sub : Class_h4p {
 *   H4P_SUPER_IS(NewSuper)
 *   ...
 *   someMethod { [super_h4p method_super];  }
 * }
 *
 *  分类 Category
 *  NSString_h4p : NSString {
 *      method_h4m { ... ... }
 *      ... ...
 * }
 * 注意：修改父类的目的是为了快速地进行方法转发，修改父类并不会修改类的真实结构，这意味着你不能访问原始类型中不存在的ivar变量地址。解决该问题只能通过Category为原始类型的属性实现动态的成员变量ivar，如果所有属性都是动态实现的则是安全的。
 * PS: The purpose of changing a superclass is to forward many methods quickly.Changing a super class does not change the real structure of the class, which means you cannot access ivar variable addresses that do not exist in the original class.The only way to solve this problem is to implement the dynamic member variable ivar by Category as a property of original class.It is safe if all properties are implemented dynamically.
 *
 */
@interface ObjcHook4pod : NSObject

/**
 *  Called manually after runtime loaded.
 */
+ (void)runtimeWork;

@end
