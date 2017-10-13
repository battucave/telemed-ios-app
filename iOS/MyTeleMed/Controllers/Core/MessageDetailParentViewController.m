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
	
    // Initialize Message Model
    [self setMessageModel:[[MessageModel alloc] init]];
	[self.messageModel setDelegate:self];
	
	// Initialize Filtered Basic Events
	[self setFilteredMessageEvents:[NSMutableArray array]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set Buttons for Archived Message Details
	if(self.message.messageType == 1)
	{
		[self.buttonArchive setEnabled:NO];
	}
	// Set buttons for Sent Message Details
	else if(self.message.messageType == 2)
	{
		CGFloat buttonWidth = self.buttonReturnCall.frame.size.width;
		CGFloat spaceAdjustment = (buttonWidth / 2);
		
		// Disable Archive and Return Call buttons
		[self.buttonArchive setEnabled:NO];
		[self.buttonArchive.superview setHidden:YES];
		[self.buttonReturnCall setEnabled:NO];
		[self.buttonReturnCall.superview setHidden:YES];
		
		[self.constraintButtonForwardLeadingSpace setConstant:-spaceAdjustment];
		[self.constraintButtonForwardTrailingSpace setConstant:spaceAdjustment];
		[self.constraintButtonHistoryLeadingSpace setConstant:spaceAdjustment];
		[self.constraintButtonHistoryTrailingSpace setConstant:-spaceAdjustment];
	}
	
	// Set Message Priority color (defaults to "Normal" green color)
	if([self.message.Priority isEqualToString:@"Priority"])
	{
		[self.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
	}
	else if([self.message.Priority isEqualToString:@"Stat"])
	{
		[self.viewPriority setBackgroundColor:[UIColor colorWithRed:182.0/255.0 green:42.0/255.0 blue:19.0/255.0 alpha:1]];
	}
}

- (IBAction)returnCall:(id)sender
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Return Call" message:@"To keep your number private, TeleMed will call you to connect your party. There will be a brief hold while connecting. There is a fee for recording." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Return Call", @"Return & Record Call", nil];
	
	[alertView setTag:1];
	[alertView show];
}

- (IBAction)archiveMessage:(id)sender
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Archive Message" message:@"Selecting Continue will archive this message. Archived messages can be accessed from the Main Menu." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
	
	[alertView setTag:2];
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// Prevent Sent Messages from Returning Call or Archiving (should never reach this point)
	if( ! self.message.MessageDeliveryID)
	{
		return;
	}
	
	switch(alertView.tag)
    {
		// Return Call
        case 1:
        {
            if(buttonIndex > 0)
            {
                [self setCallModel:[[CallModel alloc] init]];
                [self.callModel setDelegate:self];
                
                NSString *recordCall = (buttonIndex == 2) ? @"true" : @"false";
                
                [self.callModel callSenderForMessage:self.message.MessageDeliveryID recordCall:recordCall];
            }
            
            break;
        }
		
		// Archive Message
        case 2:
        {
            if(buttonIndex > 0)
            {
                [self.messageModel modifyMessageState:self.message.MessageDeliveryID state:@"archive"];
            }
            
            break;
        }
    }
}

// Return Message State pending from MessageModel delegate
- (void)modifyMessageStatePending:(NSString *)state
{
    // If finished Archiving message, send user back
    if([state isEqualToString:@"archive"] || [state isEqualToString:@"unarchive"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

/*/ Return Message State success from MessageModel delegate
- (void)modifyMessageStateSuccess:(NSString *)state
{
    // If finished Archiving message, send user back
    if([state isEqualToString:@"archive"] || [state isEqualToString:@"unarchive"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

// Return Message State error from MessageModel delegate
- (void)modifyMessageStateError:(NSError *)error forState:(NSString *)state
{
	// Show error message
	if([state isEqualToString:@"archive"])
    {
		[self.messageModel showError:error];
    }
}*/

/*/ Return success from CallTeleMedModel delegate (no longer used)
- (void)callSenderSuccess
{
	NSLog(@"Call Message Sender request sent successfully");
}

// Return error from CallTeleMedModel delegate (no longer used)
- (void)callSenderError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet)
	{
		return [self.callModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Return Call Error" message:@"There was a problem requesting a Return Call. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"showMessageForwardFromMessageDetail"] || [[segue identifier] isEqualToString:@"showMessageForwardFromMessageHistory"])
    {
        MessageForwardViewController *messageForwardViewController = [segue destinationViewController];
        
        [messageForwardViewController setMessage:self.message];
    }
	else if([[segue identifier] isEqualToString:@"showMessageTeleMedFromMessageDetail"] || [[segue identifier] isEqualToString:@"showMessageTeleMedFromMessageHistory"])
	{
		MessageTeleMedViewController *messageTeleMedViewController = [segue destinationViewController];
		
		[messageTeleMedViewController setMessage:self.message];
	}
}

@end
