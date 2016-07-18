//
//  NSObject+Swizzle.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "NSObject+Swizzle.h"
#import <objc/runtime.h>

@implementation NSObject (Swizzle)

+ (void)swizzleSelector:(SEL)originalSelector withNewSelector:(SEL)newSelector
{
	Method originalMethod = class_getInstanceMethod(self, originalSelector);
	Method newMethod = class_getInstanceMethod(self, newSelector);
	
	BOOL methodAdded = class_addMethod([self class], originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
	
	if(methodAdded)
	{
		class_replaceMethod([self class], newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else
	{
		method_exchangeImplementations(originalMethod, newMethod);
	}
}

@end