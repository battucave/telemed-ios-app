//
//  PhoneCallViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/9/19.
//  Copyright © 2019 SolutionBuilt. All rights reserved.
//

#import "PhoneCallViewController.h"
#import "ErrorAlertController.h"
#import "CallModel.h"

@interface PhoneCallViewController ()

@end

@implementation PhoneCallViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// Add call connected observer to dismiss screen after return call from TeleMed was successfully received
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConnectCall:) name:@"UIApplicationDidConnectCall" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Return pending from CallTeleMedModel delegate
- (void)callPending
{
	NSLog(@"Call Sender request pending.");
}

/*/ Return success from CallTeleMedModel delegate (no longer used)
- (void)callSuccess
{
	NSLog(@"Call TeleMed request sent successfully");
} */

// Return error from CallTeleMedModel delegate (received if user does not retry the request)
- (void)callError:(NSError *)error
{
	NSLog(@"Call TeleMed request failed: %@", error);
	
	// Call failed so dismiss this screen
	[self goBack:nil];
}

// User answered a phone call so assume that the return call from TeleMed was successfully received
- (void)didConnectCall:(NSNotification *)notification
{
	NSLog(@"Call received");
	
	// Call succeeded so dismiss this screen
	[self goBack:nil];
}

- (IBAction)goBack:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Dismiss this screen and go back to the previous one
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	});
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
