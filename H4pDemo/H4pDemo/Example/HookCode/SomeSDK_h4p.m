//
//  SomeSDK_h4p.m
//  H4pDemo
//
//  Created by MeterWhite on 2021/4/22.
//

#import "SomeSDK_h4p.h"

@interface SomeSDK_h4p ()

@property (nullable,nonatomic,copy) NSString *internalString;

@property (nullable,nonatomic,copy) NSString *addStringProperty_a2p;

@end

@implementation SomeSDK_h4p

- (void)myMethod_h4m {
    /// self.class -> SomeSDK
    /// NSLog(@"%@", _myString); // Wrong code.
    
    /// Right code
    NSLog(@"%@", self.myString);
    /// Or
    NSLog(@"%@", [self valueForKey:@"_myString"]);
    
    self.addStringProperty_a2p = @"a2p";
}

- (void)addMethod_h2m {
    NSLog(@"%@", self.addStringProperty_a2p);
}

@end
