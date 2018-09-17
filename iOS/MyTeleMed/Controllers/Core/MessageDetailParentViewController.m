//
//  MessageDetailParentViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/21/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageDetailParentViewController.h"
#import "MessageForwardViewController.h"
#import "MessageTeleMedViewController.h"
#import "CallModel.h"
#import "MessageModel.h"

@interface MessageDetailParentViewController ()

@property (nonatomic) CallModel *callModel;

@end

@implementation MessageDetailParentViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Initialize MessageModel
	[self setMessageModel:[[MessageModel alloc] init]];
	[self.messageModel setDelegate:self];
	
	// Initialize filtered basic events
	[self setFilteredMessageEvents:[NSMutableArray array]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set buttons for archived message details
	if ([self.messageType isEqualToString:@"Archived"])
	{
		[self.buttonArchive setEnabled:NO];
	}
	// Set buttons for sent message details
	else if ([self.messageType isEqualToString:@"Sent"])
	{
		CGFloat buttonWidth = self.buttonReturnCall.frame.size.width;
		CGFloat spaceAdjustment = (buttonWidth / 2);
		
		// Disable archive and return call buttons
		[self.buttonArchive setEnabled:NO];
		[self.buttonArchive.superview setHidden:YES];
		[self.buttonReturnCall setEnabled:NO];
		[self.buttonReturnCall.superview setHidden:YES];
		
		[self.constraintButtonForwardLeadingSpace setConstant:-spaceAdjustment];
		[self.constraintButtonForwardTrailingSpace setConstant:spaceAdjustment];
		[self.constraintButtonHistoryLeadingSpace setConstant:spaceAdjustment];
		[self.constraintButtonHistoryTrailingSpace setConstant:-spaceAdjustment];
	}
	
	// Set message priority color
	[self setMessagePriority];
}

- (IBAction)returnCall:(id)sender
{
	// Don't do anything if message isn't set yet (opened via push notification)
	if (! self.message)
	{
		return;
	}
	
	UIAlertController *returnCallAlertController = [UIAlertController alertControllerWithTitle:@"Return Call" message:@"To keep your number private, TeleMed will call you to connect your party. There will be a brief hold while connecting. There is a fee for recording." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *actionReturnCall = [UIAlertAction actionWithTitle:@"Return Call" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		[self setCallModel:[[CallModel alloc] init]];
		[self.callModel setDelegate:self];
		[self.callModel callSenderForMessage:self.message.MessageDeliveryID recordCall:@"false"];
	}];
	UIAlertAction *actionReturnRecordCall = [UIAlertAction actionWithTitle:@"Return & Record Call" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		[self setCallModel:[[CallModel alloc] init]];
		[self.callModel setDelegate:self];
		[self.callModel callSenderForMessage:self.message.MessageDeliveryID recordCall:@"true"];
	}];

	[returnCallAlertController addAction:actionCancel];
	[returnCallAlertController addAction:actionReturnCall];
	[returnCallAlertController addAction:actionReturnRecordCall];

	// PreferredAction only supported in 9.0+
	if ([returnCallAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[returnCallAlertController setPreferredAction:actionReturnCall];
	}

	// Show alert
	[self presentViewController:returnCallAlertController animated:YES completion:nil];
}

- (IBAction)archiveMessage:(id)sender
{
	// Don't do anything if message isn't set yet (opened via push notification)
	if (! self.message)
	{
		return;
	}
	
	UIAlertController *archiveMessageAlertController = [UIAlertController alertControllerWithTitle:@"Archive Message" message:@"Selecting Continue will archive this message. Archived messages can be accessed from the Main Menu." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *actionContinue = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		[self.messageModel modifyMessageState:self.message.MessageDeliveryID state:@"Archive"];
	}];

	[archiveMessageAlertController addAction:actionCancel];
	[archiveMessageAlertController addAction:actionContinue];

	// PreferredAction only supported in 9.0+
	if ([archiveMessageAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[archiveMessageAlertController setPreferredAction:actionContinue];
	}

	// Show alert
	[self presentViewController:archiveMessageAlertController animated:YES completion:nil];
}

/*/ Return success from CallTeleMedModel delegate (no longer used)
- (void)callSenderSuccess
{
	NSLog(@"Call Message Sender request sent successfully");
}

// Return error from CallTeleMedModel delegate (no longer used)
- (void)callSenderError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
 
	[errorAlertController show:error];
}*/

// Set message priority color (defaults to "Normal" green color)
- (void)setMessagePriority
{
	if (self.message && [self.message respondsToSelector:@selector(Priority)])
	{
		if ([self.message.Priority isEqualToString:@"Priority"])
		{
			[self.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
		}
		else if ([self.message.Priority isEqualToString:@"Stat"])
		{
			[self.viewPriority setBackgroundColor:[UIColor colorWithRed:182.0/255.0 green:42.0/255.0 blue:19.0/255.0 alpha:1]];
		}
	}
}

/*/ Return message state pending from MessageModel delegate (not used because client noticed "bug" when on a slow network connection - the message will still show in messages list until the archive process completes)
- (void)modifyMessageStatePending:(NSString *)state
{
	// If finished archiving message, send user back
	if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			// First try to unwind back to MessagesViewController so that archived message can immediately be hidden
			@try
			{
				[self performSegueWithIdentifier:@"archiveFromMessageDetailArchive" sender:self];
			}
			// Just in case the unwind segue isn't found, simply pop the view controller
			@catch(NSException *exception)
			{
				[self.navigationController popViewControllerAnimated:YES];
			}
		});
	}
}*/

// Return message state success from MessageModel delegate
- (void)modifyMessageStateSuccess:(NSString *)state
{
	// If finished archiving message, send user back
	if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			// First try to unwind back to MessagesViewController so that archived message can immediately be hidden
			@try
			{
				[self performSegueWithIdentifier:@"archiveFromMessageDetailArchive" sender:self];
			}
			// Just in case the unwind segue isn't found, simply pop the view controller
			@catch(NSException *exception)
			{
				[self.navigationController popViewControllerAnimated:YES];
			}
		});
	}
}

/*/ Return message state error from MessageModel delegate
- (void)modifyMessageStateError:(NSError *)error forState:(NSString *)state
{
	// Show error message
	if ([state isEqualToString:@"Archive"])
	{
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
 
		[errorAlertController show:error];
	}
}*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageForwardFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageForwardFromMessageHistory"])
	{
		MessageForwardViewController *messageForwardViewController = segue.destinationViewController;
		
		[messageForwardViewController setMessage:self.message];
	}
	else if ([segue.identifier isEqualToString:@"showMessageTeleMedFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageTeleMedFromMessageHistory"])
	{
		MessageTeleMedViewController *messageTeleMedViewController = segue.destinationViewController;
		
		[messageTeleMedViewController setMessage:self.message];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
