//
//  ContactViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"
#import "PhoneCallViewController.h"
#import "CallModel.h"
#import "RegisteredDeviceModel.h"

@implementation ContactViewController

- (IBAction)callTeleMed:(id)sender
{
	RegisteredDeviceModel *registeredDevice = [RegisteredDeviceModel sharedInstance];
	
	// Require device registration with TeleMed in order to return call
	if ([registeredDevice isRegistered])
	{
		UIAlertController *callTeleMedAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *callAction = [UIAlertAction actionWithTitle:@"Call" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			// Go to PhoneCallViewController
			[self performSegueWithIdentifier:@"showPhoneCall" sender:self];
		}];

		[callTeleMedAlertController addAction:callAction];
		[callTeleMedAlertController addAction:cancelAction];

		// Set preferred action
		[callTeleMedAlertController setPreferredAction:callAction];

		// Show alert dialog
		[self presentViewController:callTeleMedAlertController animated:YES completion:nil];
	}
	// If device is not already registered with TeleMed, then prompt user to register it
	else
	{
		UIAlertController *registerDeviceAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"Please register your device to enable the Call TeleMed feature." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *registerAction = [UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
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

// Override CoreViewController's didChangeRemoteNotificationAuthorization:
- (void)didChangeRemoteNotificationAuthorization:(BOOL)isEnabled
{
	NSLog(@"Remote notification authorization did change: %@", (isEnabled ? @"Enabled" : @"Disabled"));
	
	RegisteredDeviceModel *registeredDevice = [RegisteredDeviceModel sharedInstance];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// If device is registered successfully, then attempt to call TeleMed
		if ([registeredDevice isRegistered])
		{
			[self callTeleMed:nil];
		}
	});
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Go to PhoneCallViewController
	if ([segue.identifier isEqualToString:@"showPhoneCall"])
	{
		// Request a call from TeleMed
		CallModel *callModel = [[CallModel alloc] init];
		
		[callModel setDelegate:segue.destinationViewController];

		[callModel callTeleMed];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
