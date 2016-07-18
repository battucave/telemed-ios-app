//
//  OnePixelLayoutConstraint.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/11/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//
//
//  This class can be used to easily create a 1px line across all devices. To use:
//    In Storyboard, create a 1px line and add a constraint (either width or height)
//    Change the class of that constraint from NSLayoutConstraint to OnePixelLayoutConstraint
//

#import <UIKit/UIKit.h>

@interface OnePixelLayoutConstraint : NSLayoutConstraint

@end
