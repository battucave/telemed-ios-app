//
//  UIView+IBInspectable.m
//  TeleMed
//
//  Created by Shane Goodwin on 8/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "UIView+IBDesignable.h"

IB_DESIGNABLE

@implementation UIView (IBDesignable)

- (UIColor *)borderColor;
{
	return [UIColor colorWithCGColor:self.layer.borderColor];
}
 
- (void) setBorderColor:(UIColor *)borderColor
{
	self.layer.borderColor = borderColor.CGColor;
}
 
//-------------------------------------------------------------------
 
- (UIColor *)layerBackgroundColor;
{
	return [UIColor colorWithCGColor:self.layer.backgroundColor];
}
 
- (void) setLayerBackgroundColor:(UIColor *)layerBackgroundColor
{
	self.layer.backgroundColor = layerBackgroundColor.CGColor;
}
 
//-------------------------------------------------------------------
 
- (CGFloat)borderWidth;
{
	return self.layer.borderWidth;
}
 
- (void) setBorderWidth:(CGFloat)borderWidth;
{
	self.layer.borderWidth = borderWidth;
}
 
//-------------------------------------------------------------------
 
- (CGFloat)cornerRadius;
{
	return self.layer.cornerRadius;
}
 
- (void) setCornerRadius:(CGFloat)cornerRadius;
{
	self.layer.cornerRadius = cornerRadius;
}

@end
