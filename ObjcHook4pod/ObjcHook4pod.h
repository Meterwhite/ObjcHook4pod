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
 *   method { ... }
 *   ... ...
 * }
 *
 * My File
 * Class_h4p : NewSuper(If need) {
 *   @property (weak | strong | copy) property_a2p;
 *   ... ...
 *   method_h4m { self.property_a2p = ... }
 *   method_a2m { self.property_a2p = ... }
 * }
 */
@interface ObjcHook4pod : NSObject

/**
 *  Called manually after runtime loaded.
 */
+ (void)runtimeWork;

/**
 *  在ObjcHook4pod中创建一个和目的文件夹相同名称的文件夹并添加配置文件'h4p'。h4p文件中存放目标文件夹的父级文件可能的位置，该路径是相对mainBundle的路径，mainBundle表示在根目录搜索。
 *
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

