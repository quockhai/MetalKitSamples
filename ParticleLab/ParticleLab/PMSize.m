//
//  PMSize.m
//  ReverserCamera
//
//  Created by Quốc Khải on 5/10/17.
//  Copyright © 2017 Polymath. All rights reserved.
//

#import "PMSize.h"

@interface PMSize () {
    CGFloat topPadding;
    CGFloat bottomPadding;
}

@end

@implementation PMSize

+(PMSize*) sharedInstance {
    static PMSize *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

-(void)setupPadding:(UIWindow*)window {
    if (@available(iOS 11.0, *)) {
        topPadding = window.safeAreaInsets.top;
        bottomPadding = window.safeAreaInsets.bottom;
    }
}

-(instancetype)init {
    if (self = [super init]) {
        topPadding = 0.0;
        bottomPadding = 0.0;
    }
    return self;
}

-(CGFloat)top {
    return topPadding;
}

-(CGFloat)bottom {
    return bottomPadding;
}

-(CGFloat)screenWidth {
    return [[UIScreen mainScreen] bounds].size.width;
}

-(CGFloat)screenHeight {
    return [[UIScreen mainScreen] bounds].size.height;
}
@end
