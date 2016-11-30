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
#import "MessageRecipientModel.h"

@interface MessageForwardViewController ()

@property (nonatomic) MessageComposeTableViewController *messageComposeTableViewController;

@property (nonatomic) CommentModel *commentModel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@end

@implementation MessageForwardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Selected Message Recipients Array
	self.selectedMessageRecipients = [[NSMutableArray alloc] init];
	
	// Update Placeholder to custom message
	[self.messageComposeTableViewController.textViewMessage setText:@"Add Optional Comment:"];
}

// Unwind Segue from MessageRecipientPickerViewController
- (IBAction)setMessageRecipients:(UIStoryboardSegue *)segue
{
	// Obtain reference to Source View Controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected Message Recipients
	[self setSelectedMessageRecipients:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Update MessageComposeTableViewController with selected Message Recipient Names
	if([self.messageComposeTableViewController respondsToSelector:@selector(updateSelectedMessageRecipients:)])
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
	if([self.messageComposeTableViewController.textViewMessage.text isEqualToString:self.messageComposeTableViewController.textViewMessagePlaceholder])
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
	// Go back to Messages (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from ForwardMessageModel delegate (no longer used)
- (void)sendMessageSuccess
{
	NSString *messageText = self.messageComposeTableViewController.textViewMessage.text;
	
	// Add comment if necessary
	if( ! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.messageComposeTableViewController.textViewMessagePlaceholder])
	{
		[self setCommentModel:[[CommentModel alloc] init]];
		[self.commentModel setDelegate:self];
		
		[self.commentModel addMessageComment:self.message.ID comment:messageText];
	}
	// If no comment needs to be added then show success
	else
	{
		UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Forward Message" message:@"Message forwarded successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[successAlertView show];
		
		// Go back to Message Detail
		[self.navigationController popViewControllerAnimated:YES];
	}
}

// Return error from ForwardMessageModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet)
	{
		return [self.forwardMessageModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Forward Message Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Return success from CommentModel delegate (no longer used)
- (void)saveCommentSuccess:(NSString *)commentText
{
	UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Forward Message" message:@"Message forwarded successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];

	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from CommentModel delegate (no longer used)
- (void)saveCommentError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet)
	{
		[self.commentModel showOfflineError];
	}
	else
	{
		UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Forward Message" message:@"Message forward successfully, but there was a problem adding your comment. Please retry your comment on the Message Detail screen." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[errorAlertView show];
	}

	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
}*/

// Check required fields to determine if Form can be submitted - Fired from setRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.buttonSend setEnabled:(self.selectedMessageRecipients != nil && [self.selectedMessageRecipients count] > 0)];
}

// Fired from MessageComposeTable to perform segue to MessageRecipientPickerTableViewController - simplifies passing of data to the picker
- (void)performSegueToMessageRecipientPicker:(id)sender
{
	[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageForward" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"embedMessageForwardTable"])
	{
		[self setMessageComposeTableViewController:segue.destinationViewController];
		
		[self.messageComposeTableViewController setDelegate:self];
	}
	else if([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageForward"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Message Recipient Type
		[messageRecipientPickerViewController setMessageRecipientType:@"Forward"];
		
		// Set Message
		[messageRecipientPickerViewController setMessage:self.message];
		
		// Set selected Message Recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
