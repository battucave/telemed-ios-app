//
//  MessageTeleMedComposeTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 5/3/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "MessageTeleMedComposeTableViewController.h"
#import "ProfileProtocol.h"
#import "MyProfileModel.h"

@interface MessageTeleMedComposeTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageRecipient;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageSender;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessage;

@property (nonatomic) CGFloat cellMessageHeight;

@end

@implementation MessageTeleMedComposeTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Add keyboard observers
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	//[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// Remove empty separator lines (by default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	self.cellMessageHeight = self.cellMessage.frame.size.height;
	
	// Only set placeholder if it has not already been set (otherwise the placeholder will update to anything the user previously typed when returning from MessageRecipientPickerTableViewController)
	if (! self.textViewMessagePlaceholder)
	{
		self.textViewMessagePlaceholder = self.textViewMessage.text;
	}
	
	// Set user's email address
	id <ProfileProtocol> profile = MyProfileModel.sharedInstance;
	
	[self.textFieldSender setText:profile.Email];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove keyboard observers
	[NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	//[NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Resize message text view to match available space between top of table cell and keyboard
- (void)keyboardDidShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	
	// Calculate new height for message cell
	int cellMessagePadding = 20;
	[self setCellMessageHeight:self.parentViewController.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - keyboardSize.height - self.cellMessageRecipient.frame.size.height - cellMessagePadding];
	
	// Force a refresh on the table
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	
	// Scroll back to top of table
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewMessagePlaceholder])
	{
		[textView setText:@""];
		[textView setFont:[UIFont systemFontOfSize:16.0]];
		
		// iOS 13+ - Support dark mode
		if (@available(iOS 13.0, *))
		{
			[textView setTextColor:[UIColor labelColor]];
		}
		// iOS < 13 - Fallback to use Label Color light appearance
		else
		{
			[textView setTextColor:[UIColor blackColor]];
		}
	}
	
	[textView becomeFirstResponder];
}

- (IBAction)textFieldDidEditingChange:(UITextField *)textField
{
	// Validate form in delegate
	if ([self.delegate respondsToSelector:@selector(validateForm:senderEmailAddress:)])
	{
		[self.delegate validateForm:self.textViewMessage.text senderEmailAddress:self.textFieldSender.text];
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if ([self.delegate respondsToSelector:@selector(validateForm:senderEmailAddress:)])
	{
		[self.delegate validateForm:self.textViewMessage.text senderEmailAddress:self.textFieldSender.text];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if ([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewMessagePlaceholder];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
		
		// iOS 13+ - Support dark mode
		if (@available(iOS 13.0, *))
		{
			[textView setTextColor:[UIColor secondaryLabelColor]];
		}
		// iOS < 13 - Fallback to use Secondary Label Color light appearance
		else
		{
			[textView setTextColor:[UIColor colorWithRed:60.0f/255.0f green:60.0f/255.0f blue:67.0f/255.0f alpha:0.6]];
		}
	}
	
	[textView resignFirstResponder];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 2)
	{
		return self.cellMessageHeight;
	}
	
	return UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
