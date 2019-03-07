//
//  PMSize.h
//  ReverserCamera
//
//  Created by Quốc Khải on 5/10/17.
//  Copyright © 2017 Polymath. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PMSize : NSObject

+(PMSize*) sharedInstance;

-(void)setupPadding:(UIWindow*)window;

-(CGFloat)screenWidth;
-(CGFloat)screenHeight;

-(CGFloat)top;
-(CGFloat)bottom;

@end
