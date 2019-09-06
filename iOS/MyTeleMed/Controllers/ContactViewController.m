//
//  ContactViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"
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
			CallModel *callModel = [[CallModel alloc] init];
			
			[callModel setDelegate:self];
			[callModel callTeleMed];
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

// Return pending from CallTeleMedModel delegate
- (void)callSenderPending
{
	UIAlertController *returnCallAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"Please hold while we return your call." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	
	[returnCallAlertController addAction:okAction];
	
	// Set preferred action
	[returnCallAlertController setPreferredAction:okAction];

	// Show alert
	[self presentViewController:returnCallAlertController animated:YES completion:nil];
}

// Return success from CallTeleMedModel delegate (no longer used)
/*- (void)callTeleMedSuccess
{
	NSLog(@"Call TeleMed request sent successfully");
}

// Return error from CallTeleMedModel delegate (no longer used)
- (void)callTeleMedError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}*/

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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
