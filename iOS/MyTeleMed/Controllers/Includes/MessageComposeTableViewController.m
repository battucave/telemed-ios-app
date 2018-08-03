//
//  MessageComposeTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageComposeTableViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "MessageRecipientModel.h"

@interface MessageComposeTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageRecipient;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessage;
@property (weak, nonatomic) IBOutlet UILabel *labelMessageRecipient;

@property (nonatomic) CGFloat cellMessageHeight;

@end

@implementation MessageComposeTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	self.cellMessageHeight = self.cellMessage.frame.size.height;
	
	// Only set placeholder if it has not already been set (otherwise the placeholder will update to anything the user previously typed when returning from MessageRecipientPickerTableViewController)
	if (! self.textViewMessagePlaceholder)
	{
		self.textViewMessagePlaceholder = self.textViewMessage.text;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Perform segue to AccountPickerTableViewController or MessageRecipientPickerTableViewController from MessageForwardViewController/MessageNewTableViewController delegate to simplify the passing of data to MessageRecipientPickerViewController
- (IBAction)performSegueToMessageRecipientPicker:(id)sender
{
	[self.delegate performSegueToMessageRecipientPicker:(id)sender];
}

// Method fired from MessageNewTableViewController/MessageForwardViewController
- (void)updateSelectedMessageRecipients:(NSArray *)messageRecipients
{
	NSString *messageRecipientNames = @"";
	NSInteger messageRecipientsCount = [messageRecipients count];
	
	if (messageRecipientsCount > 0)
	{
		MessageRecipientModel *messageRecipient1 = [messageRecipients objectAtIndex:0];
		MessageRecipientModel *messageRecipient2 = (messageRecipientsCount > 1 ? [messageRecipients objectAtIndex:1] : nil);
	
		switch (messageRecipientsCount)
		{
			case 1:
				messageRecipientNames = messageRecipient1.Name;
				break;
			
			case 2:
				messageRecipientNames = [NSString stringWithFormat:@"%@ & %@", messageRecipient1.LastName, messageRecipient2.LastName];
				break;
			
			default:
				messageRecipientNames = [NSString stringWithFormat:@"%@, %@ & %ld more...", messageRecipient1.LastName, messageRecipient2.LastName, (long)messageRecipientsCount - 2];
				break;
		}
	}
	
	// Update message recipient label with message recipient name
	[self.labelMessageRecipient setText:messageRecipientNames];
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
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:16.0]];
	}
	
	[textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if ([self.delegate respondsToSelector:@selector(validateForm:)])
	{
		[self.delegate validateForm:self.textViewMessage.text];
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
	// Set each row's height independently
	return (indexPath.row == 1 ? self.cellMessageHeight : UITableViewAutomaticDimension);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
