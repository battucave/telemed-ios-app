//
//  CommentCell.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 2/24/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CommentCell.h"

@interface CommentCell()

@property (weak, nonatomic) IBOutlet UIView *viewCommentContainer;
@property (weak, nonatomic) IBOutlet UIView *viewCommentShadow;

@end

@implementation CommentCell

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// Add corner radius to view comment container
	self.viewCommentContainer.layer.masksToBounds = YES;
	self.viewCommentContainer.layer.cornerRadius = 5;
	
	// Add corner radius to view comment shadow
	self.viewCommentShadow.layer.cornerRadius = 5;
	
	// iOS 11+ - When iOS 10 support is dropped, update storyboard to set this color directly (instead of Opaque Separator Color) and remove this logic
	if (@available(iOS 11.0, *))
	{
		[self.viewCommentShadow setBackgroundColor:[UIColor colorNamed:@"secondarySeparatorColor"]];
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
