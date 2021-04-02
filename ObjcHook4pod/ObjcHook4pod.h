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
 *   method_h4p { self.property_a2p = ... }
 * }
 */
@interface ObjcHook4pod : NSObject

/**
 *  Called manually after runtime loaded.
 */
+ (void)runtimeWork;

@end

