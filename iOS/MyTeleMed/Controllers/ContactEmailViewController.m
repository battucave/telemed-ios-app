//
//  ContactEmailViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ContactEmailViewController.h"
#import "MessageTeleMedComposeTableViewController.h"
#import "EmailTelemedModel.h"

@interface ContactEmailViewController ()

@property (nonatomic) MessageTeleMedComposeTableViewController *messageTeleMedComposeTableViewController;

@property (nonatomic) EmailTelemedModel *emailTelemedModel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@end

@implementation ContactEmailViewController

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

// Return success from EmailTelemedModel delegate
- (void)sendMessageSuccess
{
	UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Message TeleMed" message:@"Message sent successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];
	
	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from EmailTelemedModel delegate
- (void)sendMessageError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.emailTelemedModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Message TeleMed Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

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
