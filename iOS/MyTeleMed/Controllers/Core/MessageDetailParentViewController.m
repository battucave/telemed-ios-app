//
//  MessageDetailParentViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/21/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageDetailParentViewController.h"
#import "ErrorAlertController.h"
#import "MessageEscalateViewController.h"
#import "MessageForwardViewController.h"
#import "MessageRedirectTableViewController.h"
#import "MessageTeleMedViewController.h"
#import "PhoneCallViewController.h"
#import "CallModel.h"
#import "MessageModel.h"
#import "MessageRedirectInfoModel.h"
#import "RegisteredDeviceModel.h"

@interface MessageDetailParentViewController ()

@property (nonatomic) BOOL shouldReturnCallAfterRegistration;

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
	
	#if TARGET_IPHONE_SIMULATOR
		// Disable return call button
		[self.buttonReturnCall setEnabled:NO];
	#endif
	
	// Set message priority color
	[self setMessagePriority];
}

- (IBAction)archiveMessage:(id)sender
{
	// Don't do anything if message isn't set yet (opened via push notification)
	if (! self.messageDeliveryID || ! self.message)
	{
		return;
	}
	
	UIAlertController *archiveMessageAlertController = [UIAlertController alertControllerWithTitle:@"Archive Message" message:@"Selecting Continue will archive this message. Archived messages can be accessed from the Main Menu." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		[self.messageModel modifyMessageState:self.messageDeliveryID state:@"Archive"];
	}];

	[archiveMessageAlertController addAction:continueAction];
	[archiveMessageAlertController addAction:cancelAction];

	// Set preferred action
	[archiveMessageAlertController setPreferredAction:continueAction];

	// Show alert
	[self presentViewController:archiveMessageAlertController animated:YES completion:nil];
}

- (IBAction)forwardMessage:(id)sender
{
	// Don't do anything if message isn't set yet (opened via push notification)
	if (! self.message)
	{
		return;
	}
	
	// Sent messages
	if ([self.messageType isEqualToString:@"Sent"])
	{
		// Reuse sent message recipients if they already exist
		if (self.sentMessageRecipients)
		{
			[self showMessageForward];
		}
		// Fetch sent message recipients
		else
		{
			// Initialize MessageRecipientModel
			MessageRecipientModel *messageRecipientModel = [[MessageRecipientModel alloc] init];
			
			[messageRecipientModel getMessageRecipientsForMessageID:self.message.MessageID withCallback:^(BOOL success, NSArray *messageRecipients, NSError *error)
			{
				if (success) {
					if ([messageRecipients count] > 0)
					{
						// Store sent message recipients so it can be reused if user presses forward button again
						[self setSentMessageRecipients:messageRecipients];
						
						[self showMessageForward];
					}
					// Message cannot be forwarded
					else
					{
						// Disable button
						[self.buttonForward setEnabled:NO];
						
						// Notify user that message cannot be forwarded
						[self showMessageCannotForwardError];
					}
				}
				// Show error
				else
				{
					ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
					
					[errorAlertController show:error];
				}
			}];
		}
	}
	// Received messages
	else if (self.messageDeliveryID)
	{
		// Reuse message redirect info if it already exists
		if (self.messageRedirectInfo)
		{
			[self processMessageRedirectOptions:self.messageRedirectInfo];
		}
		// Fetch message redirect info
		else
		{
			// Initialize MessageRedirectInfoModel
			MessageRedirectInfoModel *messageRedirectInfoModel = [[MessageRedirectInfoModel alloc] init];
			
			[messageRedirectInfoModel getMessageRedirectInfoForMessageDeliveryID:self.messageDeliveryID withCallback:^(BOOL success, MessageRedirectInfoModel *messageRedirectInfo, NSError *error)
			{
				if (success)
				{
					// Store message redirect info so it can be reused if user presses forward button again
					[self setMessageRedirectInfo:messageRedirectInfo];
					
					[self processMessageRedirectOptions:messageRedirectInfo];
				}
				// Show error
				else
				{
					ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
					
					[errorAlertController show:error];
				}
			}];
		}
	}
}

- (IBAction)returnCall:(id)sender
{
	// Don't do anything if message isn't set yet (opened via push notification)
	if (! self.messageDeliveryID || ! self.message)
	{
		return;
	}
	
	// NOTE: Return call recording options removed in commit "Remove the Return Call popup since all calls are recorded making the choice irrelevant" (3/01/2019)
	
	RegisteredDeviceModel *registeredDevice = RegisteredDeviceModel.sharedInstance;
	
	// Require device registration with TeleMed in order to return call
	if ([registeredDevice isRegistered])
	{
		// Go to PhoneCallViewController
		[self showPhoneCall];
	}
	// If device is not already registered with TeleMed, then prompt user to register it
	else
	{
		UIAlertController *registerDeviceAlertController = [UIAlertController alertControllerWithTitle:@"Return Call" message:@"Please register your device to enable the Return Call feature." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *registerAction = [UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			// Update the shouldReturnCallAfterRegistration flag to automatically return the call after device has successfully registered
			[self setShouldReturnCallAfterRegistration:YES];
			
			// Run CoreViewController's registerForRemoteNotifications:
			[self registerForRemoteNotifications];
		}];
		
		[registerDeviceAlertController addAction:registerAction];
		[registerDeviceAlertController addAction:cancelAction];

		// PreferredAction only supported in 9.0+
		if ([registerDeviceAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[registerDeviceAlertController setPreferredAction:registerAction];
		}

		// Show alert
		[self presentViewController:registerDeviceAlertController animated:YES completion:nil];
	}
}

// Unwind segue from MessageEscalateTableViewController
- (IBAction)unwindFromMessageEscalate:(UIStoryboardSegue *)segue
{
	NSLog(@"Unwind from Message Escalate");
}

// Unwind segue from MessageRedirectTableViewController
- (IBAction)unwindFromMessageRedirect:(UIStoryboardSegue *)segue
{
	NSLog(@"Unwind from Message Redirect");
}

// Override CoreViewController's didChangeRemoteNotificationAuthorization:
- (void)didChangeRemoteNotificationAuthorization:(BOOL)isEnabled
{
	NSLog(@"Remote notification authorization did change: %@", (isEnabled ? @"Enabled" : @"Disabled"));
	
	RegisteredDeviceModel *registeredDevice = RegisteredDeviceModel.sharedInstance;
	
	// If device is registered successfully, then enable the return call button and attempt to return call
	if (self.shouldReturnCallAfterRegistration && [registeredDevice isRegistered])
	{
		// Reset the shouldReturnCallAfterRegistration flag
		[self setShouldReturnCallAfterRegistration:NO];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self returnCall:nil];
		});
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
				[self performSegueWithIdentifier:@"unwindArchiveMessage" sender:self];
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
				[self performSegueWithIdentifier:@"unwindArchiveMessage" sender:self];
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
		ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
 
		[errorAlertController show:error];
	}
}*/

// Show error alert that message cannot be forwarded
- (void)showMessageCannotForwardError
{
	// Notify user that message cannot be forwarded
	UIAlertController *forwardMessageAlertController = [UIAlertController alertControllerWithTitle:@"Forward Message" message:@"This message cannot be forwarded." preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[forwardMessageAlertController addAction:okAction];

	// Set preferred action
	[forwardMessageAlertController setPreferredAction:okAction];

	// Show alert
	[self presentViewController:forwardMessageAlertController animated:YES completion:nil];
}

// Process options for forwarding a copy, redirecting, and/or escalating a message. Either present an alert with possible options or go to relevant screen if only 1 option is available
- (void)processMessageRedirectOptions:(MessageRedirectInfoModel *)messageRedirectInfo
{
	BOOL canEscalate = [messageRedirectInfo canEscalate];
	BOOL canForwardCopy = [messageRedirectInfo canForwardCopy];
	BOOL canRedirect = [messageRedirectInfo canRedirect];

	UIAlertController *forwardMessageAlertController = [UIAlertController alertControllerWithTitle:@"Forward Message" message:@"How you would like to forward your message?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	// Add forward a copy action if forward recipients exist
	if (canForwardCopy)
	{
		// If more than one forwarding option exists, then add an action
		if (canEscalate || canRedirect)
		{
			UIAlertAction *forwardCopyAction = [UIAlertAction actionWithTitle:@"Forward a Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				[self showMessageForward];
			}];
			
			[forwardMessageAlertController addAction:forwardCopyAction];
		}
		// If no other forwarding option exists, then go to ForwardMessageViewController
		else
		{
			[self showMessageForward];
			
			return;
		}
	}

	// Add redirect action if redirect recipients or redirect slots exist
	if (canRedirect)
	{
		// If more than one forwarding option exists, then add an action
		if (canEscalate || canForwardCopy)
		{
			UIAlertAction *redirectAction = [UIAlertAction actionWithTitle:@"Redirect" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				[self showMessageRedirect];
			}];
			
			[forwardMessageAlertController addAction:redirectAction];
		}
		// If no other forwarding option exists, then go to RedirectMessageViewController
		else
		{
			[self showMessageRedirect];
			
			return;
		}
	}

	// Add escalate action if an escalation slot exists
	if (canEscalate)
	{
		// If more than one forwarding option exists, then add an action
		if (canForwardCopy || canRedirect)
		{
			UIAlertAction *escalateAction = [UIAlertAction actionWithTitle:@"Escalate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				[self showMessageEscalate];
			}];
			
			[forwardMessageAlertController addAction:escalateAction];
		}
		// If no other forwarding option exists, then go to EscalateMessageViewController
		else
		{
			[self showMessageEscalate];
			
			return;
		}
	}

	if ([forwardMessageAlertController.actions count] > 0)
	{
		[forwardMessageAlertController addAction:cancelAction];
		
		// Show alert
		[self presentViewController:forwardMessageAlertController animated:YES completion:nil];
	}
	// Message cannot be forwarded
	else
	{
		// Disable button
		[self.buttonForward setEnabled:NO];
		
		// Notify user that message cannot be forwarded
		[self showMessageCannotForwardError];
	}

	
}

// Set message priority color (defaults to "Normal" green color)
- (void)setMessagePriority
{
	if (self.message && [self.message respondsToSelector:@selector(Priority)])
	{
		if ([self.message.Priority isEqualToString:@"Priority"])
		{
			[self.viewPriority setBackgroundColor:[UIColor systemYellowColor]];
		}
		else if ([self.message.Priority isEqualToString:@"Stat"])
		{
			[self.viewPriority setBackgroundColor:[UIColor systemRedColor]];
		}
	}
}

// Go to MessageEscalateViewController
- (void)showMessageEscalate
{
	[self performSegueWithIdentifier:@"showMessageEscalateFromMessageDetail" sender:self];
}

// Go to MessageForwardViewController
- (void)showMessageForward
{
	[self performSegueWithIdentifier:@"showMessageForwardFromMessageDetail" sender:self];
}

// Go to MessageRedirectViewController
- (void)showMessageRedirect
{
	[self performSegueWithIdentifier:@"showMessageRedirectFromMessageDetail" sender:self];
}

// Go to PhoneCallViewController
- (void)showPhoneCall
{
	[self performSegueWithIdentifier:@"showPhoneCallFromMessageDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Go to MessageEscalateViewController
	if ([segue.identifier isEqualToString:@"showMessageEscalateFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageEscalateFromMessageHistory"])
	{
		MessageEscalateViewController *messageEscalateViewController = segue.destinationViewController;
		
		// Set message and escalation slot
		[messageEscalateViewController setMessage:self.message];
		[messageEscalateViewController setSelectedOnCallSlot:self.messageRedirectInfo.EscalationSlot];
		
		// If escalation slot requires recipient selection, then set message recipients
		if (self.messageRedirectInfo.EscalationSlot.SelectRecipient)
		{
			[messageEscalateViewController setMessageRecipients:self.messageRedirectInfo.RedirectRecipients];
		}
	}
	// Go to MessageForwardViewController
	else if ([segue.identifier isEqualToString:@"showMessageForwardFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageForwardFromMessageHistory"])
	{
		MessageForwardViewController *messageForwardViewController = segue.destinationViewController;
		
		// Set message
		[messageForwardViewController setMessage:self.message];
		
		// Set message recipients for received message
		if ([self.messageRedirectInfo.ForwardRecipients count] > 0)
		{
			[messageForwardViewController setMessageRecipients:self.messageRedirectInfo.ForwardRecipients];
		}
		// Set message recipients for sent message
		else if ([self.sentMessageRecipients count] > 0)
		{
			[messageForwardViewController setMessageRecipients:self.sentMessageRecipients];
		}
	}
	// Go to MessageRedirectViewController
	else if ([segue.identifier isEqualToString:@"showMessageRedirectFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageRedirectFromMessageHistory"])
	{
		MessageRedirectTableViewController *messageRedirectTableViewController = segue.destinationViewController;
		
		// Set message, message recipients, and on call slots
		[messageRedirectTableViewController setMessage:self.message];
		[messageRedirectTableViewController setMessageRecipients:self.messageRedirectInfo.RedirectRecipients];
		[messageRedirectTableViewController setOnCallSlots:self.messageRedirectInfo.RedirectSlots];
	}
	// Go to MessageTeleMedViewController
	else if ([segue.identifier isEqualToString:@"showMessageTeleMedFromMessageDetail"] || [segue.identifier isEqualToString:@"showMessageTeleMedFromMessageHistory"])
	{
		MessageTeleMedViewController *messageTeleMedViewController = segue.destinationViewController;
		
		// Set message
		[messageTeleMedViewController setMessage:self.message];
	}
	// Go to PhoneCallViewController
	else if ([segue.identifier isEqualToString:@"showPhoneCallFromMessageDetail"] || [segue.identifier isEqualToString:@"showPhoneCallFromMessageHistory"])
	{
		PhoneCallViewController *phoneCallViewController = segue.destinationViewController;
		
		// Set message
		[phoneCallViewController setMessage:self.message];
		
		// Request a call from TeleMed
		CallModel *callModel = [[CallModel alloc] init];

		[callModel setDelegate:phoneCallViewController];

		[callModel callSenderForMessage:self.message.MessageDeliveryID recordCall:@"false"];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
