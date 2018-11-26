//
//  MessageRedirectTableViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/21/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "MessageRedirectTableViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "OnCallSlotPickerViewController.h"
#import "MessageRecipientModel.h"

@interface MessageRedirectTableViewController ()

@end

@implementation MessageRedirectTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
}

- (void)redirectMessageToOnCallSlot:(OnCallSlotModel *)onCallSlot
{
	NSLog(@"REDIRECT MESSAGE DELIVERY ID %@ TO ON CALL SLOT %@", self.message.MessageDeliveryID, onCallSlot.Name);
	
	/* RedirectMessageModel *redirectMessageModel = [[RedirectMessageModel alloc] init];
	
	[redirectMessageModel setDelegate:self];
	[redirectMessageModel redirectMessage:self.message onCallSlot:onCallSlot]; */
	
	// TEMPORARY (remove when Redirect Message web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Redirect Message Incomplete" message:@"Web services are incomplete for redirecting a message." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Go back to message detail (assume success)
		[self performSegueWithIdentifier:@"unwindFromMessageRedirect" sender:self];
	}];

	[successAlertController addAction:okAction];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:okAction];
	}

	// Show Alert
	[self.navigationController presentViewController:successAlertController animated:YES completion:nil];
	// END TEMPORARY
}

- (void)redirectMessageToRecipient:(MessageRecipientModel *)messageRecipient withChase:(BOOL)chase
{
	NSLog(@"REDIRECT MESSAGE DELIVERY ID %@ TO RECIPIENT %@ WITH CHASE %@", self.message.MessageDeliveryID, messageRecipient.Name, (chase ? @"Yes" : @"No"));
	
	/* RedirectMessageModel *redirectMessageModel = [[RedirectMessageModel alloc] init];
	
	[redirectMessageModel setDelegate:self];
	[redirectMessageModel redirectMessage:self.message recipient:messageRecipient withChase:chase]; */
	
	// TEMPORARY (remove when Redirect Message web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Redirect Message Incomplete" message:@"Web services are incomplete for redirecting a message." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Go back to message detail (assume success)
		[self performSegueWithIdentifier:@"unwindFromMessageRedirect" sender:self];
	}];

	[successAlertController addAction:okAction];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:okAction];
	}

	// Show Alert
	[self.navigationController presentViewController:successAlertController animated:YES completion:nil];
	// END TEMPORARY
}

// Return pending from ForwardMessageModel delegate
- (void)sendMessagePending
{
	// Go back to message detail (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Hide redirect to on call slot cell if no slots available for redirect
	if (indexPath.row == 0 && [self.onCallSlots count] == 0)
	{
		return 0;
	}
	// Hide redirect to recipient cell if no message recipients available for redirect
	else if (indexPath.row == 1 && [self.messageRecipients count] == 0)
	{
		return 0;
	}
	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageRedirect"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set delegate, message recipients, and recipient type (don't set message because it should not be used to fetch message recipients for redirect)
		[messageRecipientPickerViewController setDelegate:self];
		[messageRecipientPickerViewController setMessageRecipients:self.messageRecipients];
		[messageRecipientPickerViewController setMessageRecipientType:@"Redirect"];
		[messageRecipientPickerViewController setTitle:@"Choose Recipient"];
	}
	else if ([segue.identifier isEqualToString:@"showOnCallSlotPickerFromMessageRedirect"])
	{
		OnCallSlotPickerViewController *onCallSlotPickerViewController = segue.destinationViewController;
		
		// Set delegate and on call slots
		[onCallSlotPickerViewController setDelegate:self];
		[onCallSlotPickerViewController setMessageRecipients:self.messageRecipients];
		[onCallSlotPickerViewController setOnCallSlots:self.onCallSlots];
	}
}

@end
