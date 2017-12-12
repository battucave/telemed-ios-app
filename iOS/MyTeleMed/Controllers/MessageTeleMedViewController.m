//
//  MessageTeleMedViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 2/4/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "MessageTeleMedViewController.h"
#import "MessageTeleMedComposeTableViewController.h"
#import "EmailTelemedModel.h"

@interface MessageTeleMedViewController ()

@property (nonatomic) MessageTeleMedComposeTableViewController *messageTeleMedComposeTableViewController;

@property (nonatomic) EmailTelemedModel *emailTelemedModel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@end

@implementation MessageTeleMedViewController

- (IBAction)sendTeleMedMessage:(id)sender
{
	[self setEmailTelemedModel:[[EmailTelemedModel alloc] init]];
	[self.emailTelemedModel setDelegate:self];
	
	// If Active or Archived Message, include its Message Delivery ID
	if ([self.message respondsToSelector:@selector(MessageDeliveryID)] && self.message.MessageDeliveryID)
	{
		[self.emailTelemedModel sendTelemedMessage:self.messageTeleMedComposeTableViewController.textViewMessage.text fromEmailAddress:self.messageTeleMedComposeTableViewController.textFieldSender.text withMessageDeliveryID:self.message.MessageDeliveryID];
	}
	// If Sent Message
	else
	{
		[self.emailTelemedModel sendTelemedMessage:self.messageTeleMedComposeTableViewController.textViewMessage.text fromEmailAddress:self.messageTeleMedComposeTableViewController.textFieldSender.text];
	}
}

// Return pending from EmailTelemedModel delegate
- (void)sendMessagePending
{
	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from EmailTelemedModel delegate (no longer used)
- (void)sendMessageSuccess
{
 
}

// Return error from EmailTelemedModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];

	[errorAlertController show:error];
}*/

// Check required fields to determine if Form can be submitted - Fired from setRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText senderEmailAddress:(NSString *)senderEmailAddress
{
	senderEmailAddress = [senderEmailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.buttonSend setEnabled:( ! [senderEmailAddress isEqualToString:@""] && ! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.messageTeleMedComposeTableViewController.textViewMessagePlaceholder])];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"embedMessageTeleMedTable"])
	{
		[self setMessageTeleMedComposeTableViewController:segue.destinationViewController];
		
		[self.messageTeleMedComposeTableViewController setDelegate:self];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
