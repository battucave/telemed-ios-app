//
//  OnCallSummaryCell.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/6/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "OnCallSummaryCell.h"

@interface OnCallSummaryCell()

@property (weak, nonatomic) IBOutlet UIView *viewDateContainerInnerIOS10; // Remove when iOS 10 support is dropped

@end

@implementation OnCallSummaryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self)
	{
		// Initialization code
	}
	
	return self;
}

// iOS 11+ - When iOS 10 support is dropped, update storyboard to set these colors directly (instead of Separator Color and custom color) and remove this method
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (@available(iOS 11.0, *))
	{
		[self.viewDateContainerInnerIOS10 setBackgroundColor:[UIColor colorNamed:@"tableHeaderColor"]];
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
