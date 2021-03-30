//
//  ObjcHook4pod.m
//  ```
//
//  Created by MeterWhite on 2021/2/25.
//  Copyright © 2021 Meterwhite. All rights reserved.
//

#import "ObjcHook4pod.h"
#import <objc/runtime.h>

typedef enum : NSUInteger {
    H4pStorageTypeStrong,
    H4pStorageTypeWeak,
    H4pStorageTypeCopy,
} H4pStorageType;

@class H4pInstanceProperty;

void called_category_property_setter(id object, SEL sel, id value);

id called_category_property_getter(id object, SEL sel);

/// object(weak) --- propertys; property --- value
/// 对象映射属性集合，属性映射值
static NSMapTable<id, NSMutableSet<H4pInstanceProperty *> *>* _map_category_OP;

/// 缓存的原型，类映射属性；Class --- propertys
static NSMapTable<Class, NSMutableSet<H4pInstanceProperty *> *> * _map_category_CP;

#pragma mark - H4pA2pValue
/// 扩展属性的代理值，实现重写geeter和setter
@interface H4pA2pValue : NSProxy

/// 重写getter的方式
//@property (nullable,nonatomic,copy) id _Nullable(^overwriteGetter)(id _Nullable value);

/// 重写setter的方式
//@property (nullable,nonatomic,copy) id _Nullable(^overwriteSetter)(id _Nullable value);

@property (nullable,nonatomic,strong) id strongValue;

@property (nullable,nonatomic,weak)   id weakValue;

@property (nullable,nonatomic,copy)   id copyyValue;

@end

@implementation H4pA2pValue

@end

#pragma mark - H4pInstanceProperty
/// 实例方法属性
@interface H4pInstanceProperty : NSObject

/// 所属类
@property(nullable,nonatomic) Class src;

@property (nullable,nonatomic,copy) NSString *getter;

@property (nullable,nonatomic,copy) NSString *setter;

@property bool isAtomic;

/// 存储类型
@property H4pStorageType storage;

@property (nonnull,nonatomic,strong) NSLock *atomicLock;

/// 值对象
@property (nullable,nonatomic,strong) H4pA2pValue *val;

- (id)getValue;

- (void)setValue:(id)object;

@end

@implementation H4pInstanceProperty

- (instancetype)init
{
    self = [super init];
    if (self) {
        _atomicLock = [NSLock.alloc init];
        _val        = [H4pA2pValue alloc];
        _isAtomic   = false;
        _storage    = 0;
    }
    return self;
}

- (BOOL)isEqual:(H4pInstanceProperty *)object {
    if([self.getter isEqualToString:object.getter]) {
        return YES;
    }
    if([self.setter isEqualToString:object.setter]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return 0;
}

+ (instancetype)property:(objc_property_t)property {
    H4pInstanceProperty *_self = [H4pInstanceProperty.alloc init];
    NSString *pt_att    = [[NSString stringWithUTF8String:property_getAttributes(property)] copy];
    NSString *ptName    = [[NSString stringWithUTF8String:property_getName(property)] copy];
    NSArray  *flags     = [pt_att componentsSeparatedByString:@","];
    for (NSString *flag in flags) {
        // readonly 不支持
        if ([flag hasPrefix:@"R"]) {
            return nil;
        }
        // dynamic 不支持
        if ([flag hasPrefix:@"D"]) {
            return nil;
        }
        // gc 不支持
        if ([flag hasPrefix:@"P"]) {
            return nil;
        }
        // copy
        if ([flag hasPrefix:@"C"]) {
            _self.storage = H4pStorageTypeCopy;
        }
        // strong/retain
        if ([flag hasPrefix:@"&"]) {
            _self.storage = H4pStorageTypeStrong;
        }
        // weak
        if ([flag hasPrefix:@"W"]) {
            _self.storage = H4pStorageTypeWeak;
        }
        // atomicocity
        if ([flag hasPrefix:@"N"]) {
            _self.isAtomic = YES;
        }
        // custom getter
        if ([flag hasPrefix:@"G"]) {
            _self.getter = [flag substringFromIndex:1];
        }
        // custom setter
        if ([flag hasPrefix:@"S"]) {
            _self.setter = [flag substringFromIndex:1];
        }
    }
    if (_self.getter.length == 0) {
        _self.getter = ptName;
    }
    if (_self.setter.length == 0) {
        NSString *capitalized = [ptName stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[ptName substringToIndex:1] capitalizedString]];
        _self.setter = [NSString stringWithFormat:@"set%@:", capitalized];
    }
    return _self;
}

+ (instancetype)comparativePropertyWithGetter:(NSString *)sel {
    H4pInstanceProperty *_self = [H4pInstanceProperty.alloc init];
    [_self setGetter:sel];
    return _self;
}

+ (instancetype)comparativePropertyWithSetter:(NSString *)sel {
    H4pInstanceProperty *_self = [H4pInstanceProperty.alloc init];
    [_self setSetter:sel];
    return _self;
}

- (id)getValue {
    switch (self.storage) {
        case H4pStorageTypeStrong:
            return self.val.strongValue;
        case H4pStorageTypeWeak:
            return self.val.weakValue;
        case H4pStorageTypeCopy:
            return self.val.copyyValue;
        default:
            return self.val.strongValue;
    }
}

- (void)setValue:(id)object {
    if(_isAtomic) {
        [_atomicLock lock];
    }
    switch (self.storage) {
        case H4pStorageTypeStrong: {
            [self.val setStrongValue:object];
            break;
        }
        case H4pStorageTypeWeak: {
            [self.val setWeakValue:object];
            break;
        }
        case H4pStorageTypeCopy: {
            [self.val setCopyyValue:object];
            break;
        }
    }
    if(_isAtomic) {
        [_atomicLock unlock];
    }
}

-(id)copy {
    H4pInstanceProperty *nw = [[H4pInstanceProperty alloc] init];
    [nw setSrc:_src];
    [nw setGetter:_getter];
    [nw setSetter:_setter];
    [nw setIsAtomic:_isAtomic];
    [nw setStorage:_storage];
    /// 锁不拷贝
    /// 值不拷贝
    return nw;
}

@end


#pragma mark - ObjcHook4pod

@implementation ObjcHook4pod

+ (void)runtimeWork {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _map_category_OP = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality];
        _map_category_CP = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality];
        [self hookWork];
        [self categoryWork];
    });
}

+ (void)hookWork {
    unsigned int count  = 0;
    Class       *clzLi  = objc_copyClassList(&count);
    NSString    *suffix_hook    = @"_h4p";
    NSString    *suffix_md      = @"_h4m";
    do {
        Class       clz         = clzLi[count - 1];
        NSString    *clzName    = NSStringFromClass(clz);
        if(![clzName containsString:suffix_hook]) continue;
        do {
            NSString *orgClzName;
            Class    orgClz;
            /// 同步父类
            orgClzName= [clzName componentsSeparatedByString:suffix_hook].firstObject;
            orgClz      = NSClassFromString(orgClzName);
            Class   superClz    = class_getSuperclass(clz);
            Class   orgSuperClz = class_getSuperclass(orgClz);
            if(superClz != orgSuperClz) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
                class_setSuperclass(orgClz, superClz);
#pragma clang diagnostic pop
            }
            /// 实例方法
            unsigned int itMethodCount;
            Method *itMethodLi = class_copyMethodList(clz, &itMethodCount);
            for(int i = 0; i < itMethodCount; i++) {
                NSString *methodName = NSStringFromSelector(method_getName(itMethodLi[i]));
                if([methodName containsString:suffix_md]) {
                    /// Hook
                    Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                    NSString    *orgMethodName  = [methodName componentsSeparatedByString:suffix_md].firstObject;
                    Method      orgMethod       = class_getInstanceMethod(orgClz, NSSelectorFromString(orgMethodName));
                    method_setImplementation(orgMethod, method_getImplementation(method));
                }
            }
            free(itMethodLi);
            /// 类型方法
            unsigned int clzMethodCount;
            clz = object_getClass(clz);
            Method *clzMethodLi = class_copyMethodList(clz, &clzMethodCount);
            for(int i = 0; i < clzMethodCount; i++) {
                NSString *methodName = NSStringFromSelector(method_getName(clzMethodLi[i]));
                if(![methodName containsString:suffix_md]) continue;
                Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                NSString    *orgMethodName  = [methodName componentsSeparatedByString:suffix_md].firstObject;
                Method      orgMethod       = class_getInstanceMethod(orgClz, NSSelectorFromString(orgMethodName));
                method_setImplementation(orgMethod, method_getImplementation(method));
            }
            free(clzMethodLi);
            
        } while (0);
    }while(--count);
    free(clzLi);
}

+ (void)categoryWork {
    unsigned int count_clz  = 0;
    Class       *clzLi  = objc_copyClassList(&count_clz);
    NSString    *suffix_hook    = @"_h4p";
    NSString    *suffix_a2p     = @"_a2p";
    do {
        unsigned int count_p  = 0;
        Class       clz         = clzLi[count_clz - 1];
        NSString    *clzName    = NSStringFromClass(clz);
        if(![clzName containsString:suffix_hook]) continue;
        objc_property_t *pli = class_copyPropertyList(clz, &count_p);
        do {
            NSString    *orgClzName;
            Class       orgClz;
            orgClzName  = [clzName componentsSeparatedByString:suffix_hook].firstObject;
            orgClz      = NSClassFromString(orgClzName);
            objc_property_t pt = pli[count_p - 1];
            if(![@(property_getName(pt)) containsString:suffix_a2p]) continue;
            /// 钩子文件增加属性xxx_a2p后，该方法被加到目标上
            H4pInstanceProperty *myPt = [H4pInstanceProperty property:pt];
            if(!myPt) continue;
            unsigned int count_att  = 0;
            objc_property_attribute_t *attli = property_copyAttributeList(pt, &count_att);
            class_addProperty(orgClz, property_getName(pt), attli, count_att);/// 目标类添加属性
            if(myPt.setter.length) {
                class_addMethod(orgClz, NSSelectorFromString(myPt.setter), ((IMP)(called_category_property_setter)), "v@:@");
            }
            if(myPt.getter.length) {
                class_addMethod(orgClz, NSSelectorFromString(myPt.getter), ((IMP)(called_category_property_getter)), "@@:");
            }
            myPt.src = orgClz;
            /// 维护映射表
            NSMutableSet *map_pts = [_map_category_CP objectForKey:orgClz];
            if(!map_pts) {
                map_pts = [NSMutableSet set];
                [_map_category_CP setObject:map_pts forKey:orgClz];
            }
            [map_pts addObject:myPt];
            free(attli);
        } while (--count_p);
        free(pli);
    }while(--count_clz);
    free(clzLi);
}

@end

NS_INLINE H4pInstanceProperty *_Nonnull propertyWithObjectSelector(id _Nonnull object, SEL _Nonnull sel, bool isSetter) {
    H4pInstanceProperty *comp;/// 索引对象
    if(isSetter) {
        comp = [H4pInstanceProperty comparativePropertyWithSetter:NSStringFromSelector(sel)];
    } else {
        comp = [H4pInstanceProperty comparativePropertyWithGetter:NSStringFromSelector(sel)];
    }
    NSMutableSet<H4pInstanceProperty *> *pts        =   [_map_category_OP objectForKey:object];
    H4pInstanceProperty                 *property   =   nil;
    if(nil == pts) {
        pts = [NSMutableSet set];
        [_map_category_OP setObject:pts forKey:object];
    } else {
        property = [pts objectsPassingTest:^BOOL(H4pInstanceProperty * _Nonnull obj, BOOL * _Nonnull stop) {
            return [obj isEqual:comp];
        }].anyObject;
    }
    if(property == nil) {
        /// 创建新的属性；首先查找缓存的原型
        NSMutableSet<H4pInstanceProperty *> *prototypes = [_map_category_CP objectForKey:[object class]];
        if(!prototypes.count) {
            return nil;
        } else if (![prototypes containsObject:comp]) {
            return nil;
        }
        property = [prototypes objectsPassingTest:^BOOL(H4pInstanceProperty * _Nonnull obj, BOOL * _Nonnull stop) {
            return [obj isEqual:comp];
        }].anyObject;
        property = [property copy];
        [pts addObject:property];
    } else {
        return property;
    }
    return property;
}

/// 被触发setter；在此处条件断点调试；
void called_category_property_setter(id object, SEL sel, id value) {
    H4pInstanceProperty *pt = propertyWithObjectSelector(object, sel, true);
    assert(pt);
    [pt setValue:value];
}

/// 被触发getter；在此处条件断点调试；
id called_category_property_getter(id object, SEL sel) {
    H4pInstanceProperty *pt = propertyWithObjectSelector(object, sel, false);
    assert(pt);
    return [pt getValue];
}
