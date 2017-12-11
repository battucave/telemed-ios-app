//
//  MessageNew2ViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNew2TableViewController.h"

@interface MessageNew2TableViewController ()

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (nonatomic) IBOutlet UITextView *textViewAdditionalInformation;

@property (nonatomic) NSString *textViewAdditionalInformationPlaceholder;

@end

@implementation MessageNew2TableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Only set placeholder if it has not already been set
	if ( ! self.textViewAdditionalInformationPlaceholder)
	{
		self.textViewAdditionalInformationPlaceholder = self.textViewAdditionalInformation.text;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSUInteger currentIndex = [self.textFields indexOfObject:textField];
	NSUInteger nextIndex = currentIndex + 1;
	
	if (nextIndex < [self.textFields count])
	{
		[[self.textFields objectAtIndex:nextIndex] becomeFirstResponder];
	}
	else
	{
		[self.textViewAdditionalInformation becomeFirstResponder];
	}
	
	return NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewAdditionalInformationPlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:14.0]];
	}
	
	[textView becomeFirstResponder];
}

/*- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if ([self.delegate respondsToSelector:@selector(validateForm:)])
	{
		[self.delegate validateForm:self.textViewMessage.text];
	}
}*/

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if ([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewAdditionalInformationPlaceholder];
		[textView setTextColor:[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:15.0]];
	}
	
	[textView resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
