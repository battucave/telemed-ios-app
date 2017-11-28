//
//  MessageNewViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNewViewController.h"

@interface MessageNewViewController ()

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;

@end

@implementation MessageNewViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	/*UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 154, 22)];
	
	for(UITextField *textField in self.textFields)
	{
		[textField setLeftView:leftPaddingView];
		[textField setLeftViewMode:UITextFieldViewModeAlways];
	}*/
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSUInteger currentIndex = [self.textFields indexOfObject:textField];
	NSUInteger nextIndex = currentIndex + 1;
	
	if(nextIndex < [self.textFields count])
	{
		[[self.textFields objectAtIndex:nextIndex] becomeFirstResponder];
	}
	else
	{
		[[self.textFields objectAtIndex:currentIndex] resignFirstResponder];
	}
	
	return NO;
}

@end
