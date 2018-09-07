//
//  MessageForwardViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageForwardViewController.h"
#import "MessageComposeTableViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "CommentModel.h"
#import "MessageModel.h"
#import "ForwardMessageModel.h"

@interface MessageForwardViewController ()

@property (nonatomic) MessageComposeTableViewController *messageComposeTableViewController;

@property (nonatomic) CommentModel *commentModel;

@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@end

@implementation MessageForwardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Selected message recipients array
	self.selectedMessageRecipients = [[NSMutableArray alloc] init];
	
	// Update placeholder to custom message
	[self.messageComposeTableViewController.textViewMessage setText:@"Add Optional Comment:"];
}

// Unwind Segue from MessageRecipientPickerViewController
- (IBAction)setMessageRecipients:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected message recipients
	[self setSelectedMessageRecipients:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Update MessageComposeTableViewController with selected message recipient names
	if ([self.messageComposeTableViewController respondsToSelector:@selector(updateSelectedMessageRecipients:)])
	{
		[self.messageComposeTableViewController updateSelectedMessageRecipients:self.selectedMessageRecipients];
	}
	
	// Validate form
	[self validateForm:self.messageComposeTableViewController.textViewMessage.text];
}

- (IBAction)sendForwardMessage:(id)sender
{
	NSString *comment = self.messageComposeTableViewController.textViewMessage.text;
	
	// Remove placeholder comment
	if ([comment isEqualToString:self.messageComposeTableViewController.textViewMessagePlaceholder])
	{
		comment = @"";
	}
	
	ForwardMessageModel *forwardMessageModel = [[ForwardMessageModel alloc] init];
	
	[forwardMessageModel setDelegate:self];
	[forwardMessageModel forwardMessage:self.message messageRecipientIDs:[self.selectedMessageRecipients valueForKey:@"ID"] withComment:self.messageComposeTableViewController.textViewMessage.text];
}

// Return pending from ForwardMessageModel delegate
- (void)sendMessagePending
{
	// Go back to messages (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from ForwardMessageModel delegate (no longer used)
- (void)sendMessageSuccess
{
	// Go back to MessageDetailViewController
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from ForwardMessageModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}*/

// Check required fields to determine if form can be submitted - Fired from setRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.navigationItem.rightBarButtonItem setEnabled:(self.selectedMessageRecipients != nil && [self.selectedMessageRecipients count] > 0)];
}

// Fired from message compose table to perform segue to MessageRecipientPickerTableViewController - simplifies passing of data to the picker
- (void)performSegueToMessageRecipientPicker:(id)sender
{
	[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageForward" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"embedMessageForwardTable"])
	{
		[self setMessageComposeTableViewController:segue.destinationViewController];
		
		[self.messageComposeTableViewController setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageForward"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set message recipient type
		[messageRecipientPickerViewController setMessageRecipientType:@"Forward"];
		
		// Set message
		[messageRecipientPickerViewController setMessage:self.message];
		
		// Set selected message recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
