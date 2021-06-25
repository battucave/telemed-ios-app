//
//  MessageEscalateViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/20/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "MessageEscalateViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "MessageRecipientModel.h"
#import "MessageRedirectRequestModel.h"

@interface MessageEscalateViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelEscalationSlotCurrentOnCall;
@property (weak, nonatomic) IBOutlet UILabel *labelEscalationSlotName;

@end

@implementation MessageEscalateViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set escalation slot labels
	[self.labelEscalationSlotCurrentOnCall setText:self.selectedOnCallSlot.CurrentOncall];
	[self.labelEscalationSlotName setText:self.selectedOnCallSlot.Name];
	
	// Change send button title if escalation slot requires recipient selection (SelectRecipient is enabled)
	if (self.selectedOnCallSlot.SelectRecipient)
	{
		[self.navigationItem.rightBarButtonItem setTitle:@"Next"];
	}
}

- (IBAction)escalateMessage:(id)sender
{
	// If escalation slot requires recipient selection (SelectRecipient is enabled), then go to MessageRecipientPickerViewController
	if (self.selectedOnCallSlot.SelectRecipient)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageEscalate" sender:self];
	}
	// Otherwise, escalate the message
	else
	{
		MessageRedirectRequestModel *messageRedirectRequestModel = [[MessageRedirectRequestModel alloc] init];
		
		[messageRedirectRequestModel setDelegate:self];
		[messageRedirectRequestModel escalateMessage:self.message];
	}
}

// Escalate message to escalation slot with recipient selection (SelectRecipient is enabled) (called from MessageRecipientPickerViewController)
- (void)escalateMessageWithRecipient:(MessageRecipientModel *)messageRecipient
{
	MessageRedirectRequestModel *messageRedirectRequestModel = [[MessageRedirectRequestModel alloc] init];

	[messageRedirectRequestModel setDelegate:self];
	[messageRedirectRequestModel escalateMessage:self.message withMessageRecipient:messageRecipient];
}

// Return error from MessageRedirectRequestModel delegate
- (void)redirectMessageError:(NSError *)error
{
	// Empty
}

// Return pending from MessageRedirectRequestModel delegate
- (void)redirectMessagePending
{
	// Go back to message detail (assume success)
	[self performSegueWithIdentifier:@"unwindFromMessageEscalate" sender:self];
}

// Return success from MessageRedirectRequestModel delegate
- (void)redirectMessageSuccess
{
	// Empty
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageEscalate"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set delegate, message recipients, and recipient type (don't set message because it should not be used to fetch message recipients for redirect)
		[messageRecipientPickerViewController setDelegate:self];
		[messageRecipientPickerViewController setMessageRecipients:self.messageRecipients];
		[messageRecipientPickerViewController setMessageRecipientType:@"Escalate"];
		[messageRecipientPickerViewController setTitle:@"Choose Recipient"];
	}
}

@end
