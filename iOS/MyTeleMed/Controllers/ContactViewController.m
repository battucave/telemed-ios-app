//
//  ContactViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"
#import "CallModel.h"

@implementation ContactViewController

- (IBAction)callTeleMed:(id)sender
{
	UIAlertController *callTeleMedAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *callAction = [UIAlertAction actionWithTitle:@"Call" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		CallModel *callModel = [[CallModel alloc] init];
		
		[callModel setDelegate:self];
		[callModel callTeleMed];
	}];

	[callTeleMedAlertController addAction:closeAction];
	[callTeleMedAlertController addAction:callAction];

	// PreferredAction only supported in 9.0+
	if ([callTeleMedAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[callTeleMedAlertController setPreferredAction:callAction];
	}

	// Show alert dialog
	[self presentViewController:callTeleMedAlertController animated:YES completion:nil];
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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
