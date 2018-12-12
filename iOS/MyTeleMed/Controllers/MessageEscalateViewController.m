//
//  MessageEscalateViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/20/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "MessageEscalateViewController.h"
#import "EscalateMessageModel.h"

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
	EscalateMessageModel *escalateMessageModel = [[EscalateMessageModel alloc] init];
	
	[escalateMessageModel setDelegate:self];
	[escalateMessageModel escalateMessage:self.message];
}

// Return pending from EscalateMessageModel delegate
- (void)escalateMessagePending
{
	// Go back to message detail (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

@end
