//
//  NSBundle+HXPhotopicker.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/7/25.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "NSBundle+HXPhotoPicker_h4p.h"
#import "NSBundle+HXPhotoPicker.h"
#import "HXPhotoCommon.h"
#import "ObjcHook4pod.h"

@implementation NSBundle_h4p

/// Look this.
+ (id)hx_photoPickerBundle_h4m {
    static NSBundle *hxBundle = nil;
    if (hxBundle == nil) {
        hxBundle = [ObjcHook4pod h4pBundleWithName:@"HXPhotoPicker.bundle"];
    }
    return (id)hxBundle;
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key {
    return [self hx_localizedStringForKey:key value:nil];
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [HXPhotoCommon photoCommon].languageBundle;
    value = [bundle localizedStringForKey:key value:value table:nil];
    if (!value) {
        value = key;
    }
    return value;
}
@end
