//
//  SomeDSK.m
//  H4pDemo
//
//  Created by MeterWhite on 2021/4/22.
//

#import "SomeDSK.h"

@interface SomeDSK ()

@property (nullable,nonatomic,copy) NSString *internalString;

@end

@implementation SomeDSK

- (void)myMethod1 {
    NSLog(@"%@", _myString);
}

- (void)myMethod2 {
    [self myMethod];
}

@end
