//
//  LoginSSOMedToMedViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/20/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "LoginSSOMedToMedViewController.h"
#import "NewAccountViewController.h"
#import "AppDelegate.h"
#import "ELCUIApplication.h"
#import "ProfileProtocol.h"
#import "UserProfileModel.h"

@implementation LoginSSOMedToMedViewController

// Unwind Segue from NewAccountViewController
- (IBAction)unwindFromNewAccount:(UIStoryboardSegue *)segue
{
	NSLog(@"unwindFromNewAccount");
}

// Obtain User Data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize MedToTeleMed Login");
	
	UserProfileModel *userProfileModel = [UserProfileModel sharedInstance];
	
	[userProfileModel getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
	{
		if(success)
		{
			// Update Timeout Period to the value sent from sserver
			[(ELCUIApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[profile.TimeoutPeriodMins intValue]];
			
			// Fetch Accounts and check the authorization status for each
				// If at least one account has "Authorized" status, then
					// Go to Main Storyboard
					[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
			
				// Else
					// Go to MedToMed's Settings screen and include messaging about what user needs to do to be able to send messages
		}
		else
		{
			NSLog(@"LoginSSOMedToMedViewController Error: %@", error);
			
			// Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
			[self showWebViewError:[NSString stringWithFormat:@"There was a problem completing the login process:<br>%@", error.localizedDescription]];
		}
	}];
	
	[super finalizeLogin];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showNewAccount"])
	{
		NewAccountViewController *newAccountViewController = segue.destinationViewController;
		
		// Set delegate
		[newAccountViewController setDelegate:self];
	}
}

@end
