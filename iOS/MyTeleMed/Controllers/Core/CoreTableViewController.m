//
//  CoreTableViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "CoreTableViewController.h"

@implementation CoreTableViewController

// NOTE: All functionality from this file is duplicated in CoreViewController.m

- (void)viewWillAppear:(BOOL)animated
{
	[self showCDMAVoiceDataViewController:nil];
	
	[super viewWillAppear:animated];
	
	// Add Application Did Become Active Notification Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCDMAVoiceDataViewController:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// Add Application Did Receive Remote Notification Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
}

- (void)showCDMAVoiceDataViewController:(NSNotification *)notification
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Show CDMA Voice Data screen if it hasn't already been disabled or hidden
	if(self.storyboard && [[self.storyboard valueForKey:@"name"] isEqualToString:@"Main"] && ! [settings boolForKey:@"CDMAVoiceDataDisabled"] && ! [settings boolForKey:@"CDMAVoiceDataHidden"])
	{
		UIViewController *CDMAVoiceDataViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDMAVoiceDataViewController"];
		
		[self presentViewController:CDMAVoiceDataViewController animated:NO completion:nil];
	}
}

- (void)didReceiveRemoteNotification:(NSNotification *)notification
{
	NSDictionary *userInfo = notification.object;
	
	NSLog(@"CoreTableViewController Remote Notification: %@", userInfo);
	
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
	NSString *notificationType = [userInfo objectForKey:@"NotificationType"];
	id alert = [aps objectForKey:@"alert"];
	NSNumber *deliveryID;
	NSString *message = nil;
	
	// If no NotificationType was sent, assume it's a message.
	if( ! notificationType)
	{
		notificationType = @"Message";
		
		// If message contains specific substring, then it's a notification for comment.
		if([message rangeOfString:@" added a comment to a message"].location != NSNotFound)
		{
			notificationType = @"Comment";
		}
	}
	
	// Extract Delivery ID or Chat Message ID
	if([notificationType isEqualToString:@"Comment"])
	{
		deliveryID = [userInfo objectForKey:@"DeliveryID"];
	}
	else if([notificationType isEqualToString:@"Chat"])
	{
		deliveryID = [userInfo objectForKey:@"ChatMsgID"];
	}
	
	// Determine whether message was sent as an object or a string.
	if([alert isKindOfClass:[NSString class]])
	{
		message = alert;
	}
	else if([alert isKindOfClass:[NSDictionary class]])
	{
		message = [alert objectForKey:@"body"];
	}
	
	NSLog(@"NotificationType: %@", notificationType);
	NSLog(@"DeliveryID: %@", deliveryID);
	NSLog(@"Alert: %@", alert);
	NSLog(@"Message: %@", message);
	
	// If message does not exist, then this is a reminder. Ignore reminders.
	if(message != nil)
	{
		[self handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID];
	}
}

- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID
{
	// Present user with the message from notification
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MyTeleMed" message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
	
	[alertView show];
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
}

@end
