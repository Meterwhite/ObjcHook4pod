//
//  ObjcHook4pod.m
//  ObjCHook4pod
//
//  Created by MeterWhite on 2021/2/25.
//  Copyright © 2021 Meterwhite. All rights reserved.
//  https://github.com/Meterwhite/ObjcHook4pod
//

#import "ObjcHook4pod.h"
#import <objc/runtime.h>

typedef enum : NSUInteger {
    H4pStorageTypeStrong,
    H4pStorageTypeWeak,
    H4pStorageTypeCopy,
} H4pStorageType;

@class H4pInstanceProperty;

void a2p_category_property_setter(id object, SEL sel, id value);

id a2p_category_property_getter(id object, SEL sel);

NS_INLINE NSArray <NSString *>* h4pAllFilesAtPath(NSString *path);

/// object(weak) --- propertys; property --- value
/// 对象映射属性集合，属性映射值
static NSMapTable<id, NSMutableSet<H4pInstanceProperty *> *>* _map_category_OP;

/// 缓存的原型，类映射属性；Class --- propertys
static NSMapTable<Class, NSMutableSet<H4pInstanceProperty *> *> * _map_category_CP;

/// 项目配置的bundle
static NSBundle *_h4pMainBundle;

/// 动态生成的
static NSBundle *_h4pDocBundle;

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

/// 返回0以使用isEqual:
- (NSUInteger)hash {
    return 0;
}

+ (instancetype)property:(objc_property_t)property {
    H4pInstanceProperty *_self = [H4pInstanceProperty.alloc init];
    NSString *pt_att           = [[NSString stringWithUTF8String:property_getAttributes(property)] copy];
    NSString *ptName           = [[NSString stringWithUTF8String:property_getName(property)] copy];
    NSArray  *flags            = [pt_att componentsSeparatedByString:@","];
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
        _map_category_OP = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        _map_category_CP = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        [self hookWork];
        [self categoryWork];
    });
}

+ (void)hookWork {
    unsigned int count  = 0;
    Class       *clzLi  = objc_copyClassList(&count);
    NSString    *suffix_hook    = @"_h4p";
    NSString    *suffix_h4m     = @"_h4m";
    NSString    *suffix_a2m     = @"_a2m";
    do {
        Class       clz         = clzLi[count - 1];
        NSString    *clzName    = NSStringFromClass(clz);
        if(![clzName hasSuffix:suffix_hook]) continue;
        do {
            /// 同步父类
            NSString*orgClzName = [clzName componentsSeparatedByString:suffix_hook].firstObject;
            Class   orgClz      = NSClassFromString(orgClzName);
            Class   superClz    = class_getSuperclass(clz);
            Class   orgSuperClz = class_getSuperclass(orgClz);
            if(superClz != orgSuperClz &&
               /// 排除分类
               superClz != orgClz) {
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
                if([methodName hasSuffix:suffix_h4m]) {
                    /// Hook method
                    Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                    NSString    *orgMethodName  = [methodName componentsSeparatedByString:suffix_h4m].firstObject;
                    Method      orgMethod       = class_getInstanceMethod(orgClz, NSSelectorFromString(orgMethodName));
                    method_setImplementation(orgMethod, method_getImplementation(method));
                } else if ([methodName hasSuffix:suffix_a2m]) {
                    /// Add method
                    Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                    class_addMethod(orgClz, NSSelectorFromString(methodName), method_getImplementation(method), method_getTypeEncoding(method));
                }
            }
            free(itMethodLi);
            /// 类型方法
            unsigned int clzMethodCount;
            clz     = object_getClass(clz);
            orgClz  = object_getClass(orgClz);
            Method *clzMethodLi = class_copyMethodList(clz, &clzMethodCount);
            for(int i = 0; i < clzMethodCount; i++) {
                NSString *methodName = NSStringFromSelector(method_getName(clzMethodLi[i]));
                if([methodName hasSuffix:suffix_h4m]) {
                    /// Hook method
                    Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                    NSString    *orgMethodName  = [methodName componentsSeparatedByString:suffix_h4m].firstObject;
                    Method      orgMethod       = class_getInstanceMethod(orgClz, NSSelectorFromString(orgMethodName));
                    method_setImplementation(orgMethod, method_getImplementation(method));
                } else if([methodName hasSuffix:suffix_a2m]) {
                    /// Add method
                    Method      method          = class_getInstanceMethod(clz, NSSelectorFromString(methodName));
                    class_addMethod(orgClz, NSSelectorFromString(methodName), method_getImplementation(method), method_getTypeEncoding(method));
                }
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
        if(![clzName hasSuffix:suffix_hook]) continue;
        objc_property_t *pli = class_copyPropertyList(clz, &count_p);
        while (count_p --) {
            NSString    *orgClzName;
            Class       orgClz;
            orgClzName  = [clzName componentsSeparatedByString:suffix_hook].firstObject;
            orgClz      = NSClassFromString(orgClzName);
            objc_property_t pt = pli[count_p];
            if(![@(property_getName(pt)) hasSuffix:suffix_a2p]) continue;
            /// 钩子文件增加属性xxx_a2p后，该方法被加到目标上
            H4pInstanceProperty *myPt = [H4pInstanceProperty property:pt];
            if(!myPt) continue;
            unsigned int count_att  = 0;
            objc_property_attribute_t *attli = property_copyAttributeList(pt, &count_att);
            class_addProperty(orgClz, property_getName(pt), attli, count_att);/// 目标类添加属性
            if(myPt.setter.length) {
                class_addMethod(orgClz, NSSelectorFromString(myPt.setter), ((IMP)(a2p_category_property_setter)), "v@:@");
            }
            if(myPt.getter.length) {
                class_addMethod(orgClz, NSSelectorFromString(myPt.getter), ((IMP)(a2p_category_property_getter)), "@@:");
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
        }
        free(pli);
    } while(--count_clz);
    free(clzLi);
}

+ (void)h4pResourceWork {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:NSStringFromClass(self) ofType:@"bundle"];
        _h4pMainBundle = [NSBundle bundleWithPath:bundlePath];
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *docBundlePath = [docPath  stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", NSStringFromClass(self)]];
        NSFileManager *fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:docBundlePath]) {
            if(![fm createDirectoryAtPath:docBundlePath withIntermediateDirectories:NO attributes:nil error:nil]) {
                _h4pDocBundle = nil;
            }
        }
        _h4pDocBundle = [NSBundle bundleWithPath:docBundlePath];
    });
    [self createH4pResource];
}

+ (void)createH4pResource {
    NSFileManager           *fm             = [NSFileManager defaultManager];
    NSArray <NSString *>    *dirs_sdk_main  = [fm contentsOfDirectoryAtPath:_h4pMainBundle.resourcePath error:nil];
    NSString *curVersion = [self h4pVersionWith:[_h4pMainBundle pathForResource:@"h4p" ofType:nil]];
    NSString *oldVersion = [self h4pVersionWith:[_h4pDocBundle  pathForResource:@"h4p" ofType:nil]];
    NSAssert(curVersion, @"Nonnull! Missing H4P configuration file.");
    /// 版本控制
    if([oldVersion isEqualToString:curVersion]) {
        return;
    }
    
    /// 合并资源
    /// 查找每一级目录下的根据配置文件，以此找到目标文件夹
    NSString *mbPath  = [NSBundle mainBundle].resourcePath;
    NSUInteger h4pIdx = [dirs_sdk_main indexOfObject:@"h4p"];
    for (int i = 0; i < dirs_sdk_main.count; i++) {
        if (i == h4pIdx) continue;
        NSString *dirName = dirs_sdk_main[i];
        NSString *dirPath = [_h4pMainBundle.resourcePath stringByAppendingPathComponent:dirName];
        NSString *h4pPath = [dirPath stringByAppendingPathComponent:@"h4p"];
        NSAssert([fm fileExistsAtPath:h4pPath], @"Nonnull! Missing H4P configuration file.");
        NSArray  *searchs = [self h4pContentsForPath:h4pPath];
        for (NSString *search in searchs) {
            NSString *searchPath = [mbPath stringByAppendingPathComponent:search];
            if([fm fileExistsAtPath:searchPath]){
                [self combineResource:dirName from:searchPath];
                break;
            }
        }
    }
    /// 覆盖版本号
    if(oldVersion) {
        [fm copyItemAtPath:[_h4pMainBundle pathForResource:@"h4p" ofType:nil] toPath:[_h4pDocBundle pathForResource:@"h4p" ofType:nil] error:nil];
    }
}

+ (NSBundle *)h4pBundleWithName:(NSString *)name {
    return [NSBundle bundleWithPath:[_h4pDocBundle pathForResource:name ofType:nil]];
}

/// h4p bundle与指定文件夹合并
/// @param name 资源文件夹名
/// @param path 目标资源文件夹路径，如果不存在则无为
+ (void)combineResource:(NSString *)name from:(NSString *)path {
    /// 拷贝旧资源
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path]) return;
    NSString *dstPath = [_h4pDocBundle.resourcePath stringByAppendingPathComponent:name];
    if([fm fileExistsAtPath:dstPath]) {
        [fm removeItemAtPath:dstPath error:nil];
    }
    [fm copyItemAtPath:path toPath:dstPath error:nil];
    
    /// 以新资源覆盖
    NSString * fromPath         = [_h4pMainBundle.resourcePath stringByAppendingPathComponent:name];
    NSAssert([fm fileExistsAtPath:fromPath], @"Missing resource!");
    NSArray <NSString *> *items = h4pAllFilesAtPath(fromPath);
    for (NSString *itemPath in items) {
        NSString *toPath        = [itemPath componentsSeparatedByString:_h4pMainBundle.resourcePath].lastObject; /// /SDK/...
        toPath                  = [_h4pDocBundle.resourcePath stringByAppendingPathComponent:toPath];
        if([fm fileExistsAtPath:toPath]) {
            [fm removeItemAtPath:toPath error:nil];
        }
        [fm copyItemAtPath:itemPath toPath:toPath error:nil];
    }
}

/// 取得h4p资源版本号
+ (NSString *)h4pVersionWith:(NSString *)path {
    return [self h4pContentsForPath:path].firstObject;
}

/// 取得h4p文件每行内容
+ (NSArray *)h4pContentsForPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path]) {
        return nil;
    }
    NSMutableArray *lines = [[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"] mutableCopy];
    for (int i = 0; i < lines.count; i++) {
        if(0 == [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length) {
            [lines removeObjectAtIndex:i];
        }
    }
    return lines.copy;
}

@end

/// 取得路径下所有文件路径
NS_INLINE NSArray <NSString *>* h4pAllFilesAtPath(NSString *path) {
    NSFileManager  *fm                      = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumerator    = [fm enumeratorAtURL:[NSURL URLWithString:path] includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles   errorHandler:nil];
    NSMutableArray *files                   =[NSMutableArray array];
    for (NSURL *pathURL in dirEnumerator) {
        NSNumber *isDirectory;
        [pathURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if([isDirectory boolValue] == NO) {
            NSString *path;
            [pathURL getResourceValue:&path forKey:NSURLPathKey error:NULL];
            [files addObject:path];
        }
    }
    return [files copy];
}

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

#pragma mark - 分类增加的属性 Category property getter and setter.

/// 分类添加的属性setter；开发者以在此处通过条件断点调试；
void a2p_category_property_setter(id object, SEL sel, id value) {
    H4pInstanceProperty *pt = propertyWithObjectSelector(object, sel, true);
    assert(pt);
    [pt setValue:value];
}

/// 分类添加的属性getter；开发者以在此处通过条件断点调试；
id a2p_category_property_getter(id object, SEL sel) {
    H4pInstanceProperty *pt = propertyWithObjectSelector(object, sel, false);
    assert(pt);
    return [pt getValue];
}
