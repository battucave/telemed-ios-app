//
//  NSObject+Swizzle.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Swizzle)

+ (void)swizzleSelector:(SEL)originalSelector withNewSelector:(SEL)newSelector;

@end
