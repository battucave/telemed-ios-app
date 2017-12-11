//
//  ContactViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"

#ifdef MYTELEMED
	#import "CallModel.h"
#endif

@implementation ContactViewController

- (IBAction)callTeleMed:(id)sender
{
	// MedToMed - Use phone dialer to make call
	#ifdef MEDTOMED
		// Tel works same as telprompt in iOS 10.3+
		// TODO: Replace phone number
		NSURL *urlCallTeleMed = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt:%@", @"+18001111111"]];
	
		// Verify that device can make phone calls
		if ([[UIApplication sharedApplication] canOpenURL:urlCallTeleMed])
		{
			[[UIApplication sharedApplication] openURL:urlCallTeleMed];
		}
		else
		{
			UIAlertController *callUnavailableAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"Telephone service is unavailable." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
			
			[callUnavailableAlertController addAction:actionOK];
			
			// PreferredAction only supported in 9.0+
			if ([callUnavailableAlertController respondsToSelector:@selector(setPreferredAction:)])
			{
				[callUnavailableAlertController setPreferredAction:actionOK];
			}
			
			// Show Alert
			[self presentViewController:callUnavailableAlertController animated:YES completion:nil];
		}
	
	// MyTeleMed - Use calls api to request a callback
	#elif defined MYTELEMED
		UIAlertController *callTeleMedAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:@"" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *actionClose = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *actionCall = [UIAlertAction actionWithTitle:@"Call" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			CallModel *callModel = [[CallModel alloc] init];
			
			[callModel setDelegate:self];
			[callModel callTeleMed];
		}];
	
		[callTeleMedAlertController addAction:actionClose];
		[callTeleMedAlertController addAction:actionCall];
	
		// PreferredAction only supported in 9.0+
		if ([callTeleMedAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[callTeleMedAlertController setPreferredAction:actionCall];
		}
	
		// Show Alert
		[self presentViewController:callTeleMedAlertController animated:YES completion:nil];
	#endif
}

// Return success from CallTeleMedModel delegate (no longer used)
/*- (void)callTeleMedSuccess
{
	NSLog(@"Call TeleMed request sent successfully");
}

// Return error from CallTeleMedModel delegate (no longer used)
- (void)callTeleMedError:(NSError *)error
{
	// If device offline, show offline message
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
	// Create reference to generic model to show offline error
		CallModel *callModel = [[CallModel alloc] init];

		return [callModel showErrorOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Call TeleMed Error" message:@"There was a problem requesting a Return Call. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}*/

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
