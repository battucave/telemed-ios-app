//
//  ContactEmailViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ContactMessageViewController.h"
#import "MessageTeleMedComposeTableViewController.h"
#import "EmailTelemedModel.h"

@interface ContactMessageViewController ()

@property (nonatomic) MessageTeleMedComposeTableViewController *messageTeleMedComposeTableViewController;

@property (nonatomic) EmailTelemedModel *emailTelemedModel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@end

@implementation ContactMessageViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (IBAction)sendTeleMedMessage:(id)sender
{
	[self setEmailTelemedModel:[[EmailTelemedModel alloc] init]];
	[self.emailTelemedModel setDelegate:self];
	
	[self.emailTelemedModel sendTelemedMessage:self.messageTeleMedComposeTableViewController.textViewMessage.text fromEmailAddress:self.messageTeleMedComposeTableViewController.textFieldSender.text];
}

// Return pending from EmailTeleMedModel delegate
- (void)sendMessagePending
{
	// Go back to Messages (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from EmailTelemedModel delegate (no longer used)
- (void)sendMessageSuccess
{
	UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Message TeleMed" message:@"Message sent successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];
	
	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from EmailTelemedModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:error.localizedFailureReason message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
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
	if([segue.identifier isEqualToString:@"embedContactEmailTable"])
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
