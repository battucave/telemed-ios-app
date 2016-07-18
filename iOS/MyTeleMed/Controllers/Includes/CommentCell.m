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
	
	// Add corner radius to View Comment Container
	self.viewCommentContainer.layer.masksToBounds = YES;
	self.viewCommentContainer.layer.cornerRadius = 5;
	
	// Add corner radius to View Comment Shadow
	self.viewCommentShadow.layer.cornerRadius = 5;
	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
