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
#import "RedirectMessageModel.h"

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

// Redirect message to an on call slot (called from OnCallSlotPickerViewController)
- (void)redirectMessageToOnCallSlot:(OnCallSlotModel *)onCallSlot
{
	RedirectMessageModel *redirectMessageModel = [[RedirectMessageModel alloc] init];
	
	[redirectMessageModel setDelegate:self];
	[redirectMessageModel redirectMessage:self.message messageRecipient:nil onCallSlot:onCallSlot];
}

// Redirect message to a message recipient or to an on call slot with SelectRecipient enabled (called from MessageRecipientPickerViewController)
- (void)redirectMessageToRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot
{
	RedirectMessageModel *redirectMessageModel = [[RedirectMessageModel alloc] init];
	
	[redirectMessageModel setDelegate:self];
	[redirectMessageModel redirectMessage:self.message messageRecipient:messageRecipient onCallSlot:onCallSlot];
}

// Return pending from RedirectMessageModel delegate
- (void)redirectMessagePending
{
	// Go back to message detail (assume success)
	[self performSegueWithIdentifier:@"unwindFromMessageRedirect" sender:self];
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
