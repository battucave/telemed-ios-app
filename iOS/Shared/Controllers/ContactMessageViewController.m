//
//  ContactEmailViewController.m
//  TeleMed
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	#ifdef MEDTOMED
		[self.navigationItem setTitle:@"Contact TeleMed"];
	
	// Remove menu button if showing Back button. This MUST happen before [super viewWillAppear] so that Back Button will be added in its place (Back button only shown when navigating from Login.storyboard View Controllers)
	#else
		self.navigationItem.leftBarButtonItem = nil;
	#endif
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
	#ifdef MEDTOMED
		// Reset message text
		[self.messageTeleMedComposeTableViewController.textViewMessage setText:@""];
		[self.messageTeleMedComposeTableViewController.textViewMessage resignFirstResponder];

		// Invalidate form
		[self.buttonSend setEnabled:NO];
	
		// Show succcess message (assume success)
		UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Contact TeleMed" message:@"Message sent successfully." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

		[successAlertController addAction:actionOK];

		// PreferredAction only supported in 9.0+
		if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[successAlertController setPreferredAction:actionOK];
		}

		// Show Alert
		[self presentViewController:successAlertController animated:YES completion:nil];
	
	// Go back to Messages (assume success)
	#else
		[self.navigationController popViewControllerAnimated:YES];
	#endif
}

/*/ Return success from EmailTelemedModel delegate (no longer used)
- (void)sendMessageSuccess
{
	// Go back to Message Detail
	[self.navigationController popViewControllerAnimated:YES];
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
	if ([segue.identifier isEqualToString:@"embedContactEmailTable"])
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
