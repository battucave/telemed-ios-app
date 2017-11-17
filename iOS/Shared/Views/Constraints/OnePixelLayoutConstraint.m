//
//  OnePixelLayoutConstraint.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/11/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "OnePixelLayoutConstraint.h"

@implementation OnePixelLayoutConstraint

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if(self.constant == 1.0)
	{
		self.constant = 1.0 / [UIScreen mainScreen].scale;
	}
}

@end
