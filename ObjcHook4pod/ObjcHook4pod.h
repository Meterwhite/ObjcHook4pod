//
//  ObjcHook4pod.h
//  ObjCHook4pod
//
//  Created by MeterWhite on 2021/2/25.
//  Copyright © 2021 Meterwhite. All rights reserved.
//  https://github.com/Meterwhite/ObjcHook4pod
//

#import <Foundation/Foundation.h>

#ifndef H4P_SUPER_IS
#define H4P_SUPER_IS(...) \
    \
    @property __kindof __VA_ARGS__ * __h4p_kind_super__;
#endif


#ifndef super_h4p
#define super_h4p \
    \
    ((typeof(self.__h4p_kind_super__))self)
#endif


/**
 *
 * Destination File
 * Class : Super {
 *   method_super { ... }
 *   ... ...
 * }
 *
 * My File
 * Class_h4p : NewSuper(If need) {
 *   @property (weak | strong | copy) propertyNew_a2p;
 *   ... ...
 *   method_super_h4m { self.property_a2p = ... }
 *   methodNew_a2m { self.property_a2p = ... }
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
 */
@interface ObjcHook4pod : NSObject

/**
 *  Called manually after runtime loaded.
 */
+ (void)runtimeWork;

/**
 *
 *  替换资源文件:
 *  在ObjcHook4pod中创建一个和目的文件夹相同名称的文件夹并添加配置文件'h4p'。h4p文件中存放目标文件夹的父级文件可能的位置，该路径是相对mainBundle的路径，mainBundle表示在根目录搜索。
 *
 *  Cover project resource:
 *  Create a folder with the same name as the destination folder in ObjcHook4pod and add the configuration file'h4p'. The possible location of the parent file of the target folder is stored in the h4p file. The path is relative to the mainBundle, and the mainBundle means searching in the root directory.
 *
 * ▼ ObjcHook4pod.bundle
 *      ▼ mainBundle
 *      ... files you want to copy to main bundle.
 *      ▼ DestinationDirectory
 *          ▼ h4p (Create a txt file named 'h4p' and config the search infomation.)
 *              mainBundle
 *              Frameworks/SomeSDK.framework/UIFace.bundle
 *      ▼ ... ...
 *
 * Replace once.
 */
+ (void)resourceHook;

@end

