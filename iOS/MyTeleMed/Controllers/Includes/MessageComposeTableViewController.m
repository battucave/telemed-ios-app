//
//  MessageComposeTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageComposeTableViewController.h"
#import "MessageRecipientPickerViewController.h"

@interface MessageComposeTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageRecipient;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessage;

@end

@implementation MessageComposeTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.textViewMessage setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	self.cellMessageHeight = self.cellMessage.frame.size.height;
	
	[self.textViewMessage setAutocorrectionType:UITextAutocorrectionTypeNo];
	
	// Only set placeholder if it has not already been set (otherwise the placeholder will update to anything the user previously typed when returning from MessageRecipientPickerTableViewController)
	if( ! self.textViewMessagePlaceholder)
	{
		self.textViewMessagePlaceholder = self.textViewMessage.text;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Perform Segue to MessageAccountPickerTableViewController or MessageRecipientPickerTableViewController from MessageForwardViewController/MessageNewViewController delegate to simplify the passing of data to Message Recipient Picker
- (IBAction)performSegueToMessageRecipientPicker:(id)sender
{
	[self.delegate performSegueToMessageRecipientPicker:(id)sender];
}

// Method fired from MessageNewViewController/MessageForwardViewController
- (void)updateSelectedMessageRecipients:(NSArray *)messageRecipients
{
	NSString *messageRecipientNames = @"";
	NSInteger messageRecipientsCount = [messageRecipients count];
	
	if(messageRecipientsCount > 0)
	{
		messageRecipientNames = [[messageRecipients objectAtIndex:0] Name];
		
		if(messageRecipientsCount > 1)
		{
			messageRecipientNames = [messageRecipientNames stringByAppendingFormat:@" & %ld more...", (long)messageRecipientsCount - 1];
		}
	}
	
	// Update Message Recipient Label with Message Recipient Name
	[self.buttonMessageRecipient setTitle:messageRecipientNames forState:UIControlStateNormal];
	[self.buttonMessageRecipient setTitle:messageRecipientNames forState:UIControlStateSelected];
}

// Resize Message Text View to match available space between top of Table Cell and Keyboard
- (void)keyboardDidShow:(NSNotification *)notification
{
	// Obtain Keyboard Size
	CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	
	// Calculate New Height for Message Cell -> Use Parent View Controller to account for Navigation Controller
	[self setCellMessageHeight:self.parentViewController.view.frame.size.height - keyboardSize.height - self.cellMessageRecipient.bounds.size.height];
	
	// Force a refresh on the table
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	
	// Scroll back to Top of Table
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if([textView.text isEqualToString:self.textViewMessagePlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:16.0]];
	}
	
	[textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if([self.delegate respondsToSelector:@selector(validateForm:)])
	{
		[self.delegate validateForm:self.textViewMessage.text];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewMessagePlaceholder];
		[textView setTextColor:[UIColor colorWithRed:98.0/255.0 green:98.0/255.0 blue:98.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
	}
	
	[textView resignFirstResponder];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set each row's height independently
	return (indexPath.row == 1 ? self.cellMessageHeight : [super tableView:tableView heightForRowAtIndexPath:indexPath]);
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
