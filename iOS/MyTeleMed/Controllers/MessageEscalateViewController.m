//
//  MessageEscalateViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/20/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "MessageEscalateViewController.h"

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
}

- (IBAction)escalateMessage:(id)sender
{
	NSLog(@"ESCALATE MESSAGE DELIVERY ID %@ TO %@ (%@)", self.message.MessageDeliveryID, self.selectedOnCallSlot.Name, self.selectedOnCallSlot.CurrentOncall);
	
	/* EscalateMessageModel *escalateMessageModel = [[EscalateMessageModel alloc] init];
	
	[escalateMessageModel setDelegate:self];
	[escalateMessageModel escalateMessage:self.message onCallSlot:self.selectedOnCallSlot]; */
	
	// TEMPORARY (remove when Escalate Message web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Escalate Message Incomplete" message:@"Web services are incomplete for escalating a message." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Go back to message detail (assume success)
		[self.navigationController popViewControllerAnimated:YES];
	}];

	[successAlertController addAction:okAction];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:okAction];
	}

	// Show Alert
	[self presentViewController:successAlertController animated:YES completion:nil];
	// END TEMPORARY
}

// Return pending from EscalateMessageModel delegate
- (void)escalateMessagePending
{
	// Go back to message detail (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

@end
