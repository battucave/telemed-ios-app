//
//  InsetTextField.m
//  TeleMed
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "InsetTextField.h"

IB_DESIGNABLE

@implementation InsetTextField

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (!self)
	{
		return nil;
	}
	
	[self inspectableDefaults];
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (!self)
	{
		return nil;
	}
	
	[self inspectableDefaults];
	
	return self;
}

- (void)inspectableDefaults
{
    _bottomInset = 0;
    _leftInset = 0;
    _rightInset = 0;
    _topInset = 0;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
	UIEdgeInsets insets = UIEdgeInsetsMake(self.topInset, self.leftInset, self.bottomInset, self.rightInset);
	
	return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], insets);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
	UIEdgeInsets insets = UIEdgeInsetsMake(self.topInset, self.leftInset, self.bottomInset, self.rightInset);
	
	return UIEdgeInsetsInsetRect([super editingRectForBounds:bounds], insets);
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
	CGRect rect = [super clearButtonRectForBounds:bounds];
	
	return CGRectOffset(rect, -5, 0);
}

@end
