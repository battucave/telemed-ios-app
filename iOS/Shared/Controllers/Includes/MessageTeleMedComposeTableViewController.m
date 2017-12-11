//
//  MessageTeleMedComposeTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 5/3/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "MessageTeleMedComposeTableViewController.h"
#import "ProfileProtocol.h"

#ifdef MYTELEMED
	#import "MyProfileModel.h"
#endif

#ifdef MEDTOMED
	#import "UserProfileModel.h"
#endif

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
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	self.cellMessageHeight = self.cellMessage.frame.size.height;
	
	// Only set placeholder if it has not already been set (otherwise the placeholder will update to anything the user previously typed when returning from MessageRecipientPickerTableViewController)
	if ( ! self.textViewMessagePlaceholder)
	{
		self.textViewMessagePlaceholder = self.textViewMessage.text;
	}
	
	// Set User Email Address
	id <ProfileProtocol> profile;
	
	#ifdef MYTELEMED
		profile = [MyProfileModel sharedInstance];

	#elif defined MEDTOMED
		profile = [UserProfileModel sharedInstance];
	#endif
	
	if (profile)
	{
		[self.textFieldSender setText:profile.Email];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Resize Message Text View to match available space between top of Table Cell and Keyboard
- (void)keyboardDidShow:(NSNotification *)notification
{
	// Obtain Keyboard Size
	CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	
	// Calculate New Height for Message Cell
	int cellMessagePadding = 20;
	[self setCellMessageHeight:self.parentViewController.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - keyboardSize.height - self.cellMessageRecipient.frame.size.height - cellMessagePadding];
	
	// Force a refresh on the table
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	
	// Scroll back to Top of Table
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewMessagePlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:16.0]];
	}
	
	[textView becomeFirstResponder];
}

- (IBAction)textFieldDidChangeEditing:(UITextField *)textField
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
		[textView setTextColor:[UIColor colorWithRed:98.0/255.0 green:98.0/255.0 blue:98.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
	}
	
	[textView resignFirstResponder];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 2)
	{
		return self.cellMessageHeight;
	}
	
	// Can't use super here because it would call MessageComposeTableViewController which has different heights
	return [[[UITableViewController alloc] init] tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
