//
//  MessageCell.m
//  TeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageCell.h"

@interface MessageCell()

@property (nonatomic) IBOutlet NSLayoutConstraint *constraintViewLeftSpace;

@property (nonatomic) UIEdgeInsets defaultEdgeInsets;

@end

@implementation MessageCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	// Set default separator inset
	if ([self respondsToSelector:@selector(setSeparatorInset:)])
	{
		[self setDefaultEdgeInsets:self.separatorInset];
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (self.editing)
	{
		// Indentation width in storyboard attributes has no effect on custom table Cells. Therefore, assume the default indentation of 38.0f and add additional indentation separately
		//CGFloat indentation = self.indentationLevel * self.indentationWidth;
		CGFloat defaultEditIndentation = 38.0f;
		CGFloat additionalEditIndentation = 8.0f;
		
		// Use leading constraint on viewPriority to add additional indentation
		[self.constraintViewLeftSpace setConstant:additionalEditIndentation];
		
		// Adjust separator inset to account for editing indentation (the default left edge inset seems to be off so subtracting 3 fixes it)
		if ([self respondsToSelector:@selector(setSeparatorInset:)])
		{
			[self setSeparatorInset:UIEdgeInsetsMake(self.defaultEdgeInsets.top, self.defaultEdgeInsets.left - 3.0f + self.viewPriority.frame.size.width + defaultEditIndentation + additionalEditIndentation, self.defaultEdgeInsets.bottom, self.defaultEdgeInsets.right)];
		}
	}
	else
	{
		// Reset left indentation constraint
		[self.constraintViewLeftSpace setConstant:0.0f];
		
		// Remove extra indentation from separator inset
		if ([self respondsToSelector:@selector(setSeparatorInset:)])
		{
			[self setSeparatorInset:self.defaultEdgeInsets];
		}
	}
}

// Configure the view for the highlighted state
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	// Cancel default functionality
	//[super setHighlighted:highlighted animated:animated];
}

// Configure the view for the selected state. By default, setSelected sets all of the cell's subviews to a clear background color. Override this functionality
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	NSMutableArray *backgroundViewColors = [[NSMutableArray alloc] init];
	
	[self.contentView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop)
	{
		UIColor *color = view.backgroundColor ?: [UIColor clearColor];
		
		[backgroundViewColors addObject:color];
	}];
	
	[self setSelectedBackgroundView:(self.isEditing && selected ? [UIView new] : nil)];
	
	[super setSelected:selected animated:animated];
	
	[self.contentView.subviews enumerateObjectsUsingBlock:^(id view, NSUInteger idx, BOOL *stop)
	{
		if ([view respondsToSelector:@selector(setHighlighted:)])
		{
			[view setValue:@NO forKey:@"highlighted"];
		}
		
		[view setBackgroundColor:backgroundViewColors[idx]];
	}];
}

@end
