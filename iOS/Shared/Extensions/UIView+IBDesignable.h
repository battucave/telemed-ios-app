//
//  UIView+IBInspectable.h
//  TeleMed
//
//  Created by Shane Goodwin on 8/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

// This category is automatically used by Storyboard to provide extra properties on the Attributes Inspector

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface UIView (IBDesignable)

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
