//
//  LoginSSOMed2MedViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/20/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginSSOMed2MedViewController.h"
#import "AccountNewViewController.h"
#import "AccountModel.h"
#import "UserProfileModel.h"

@interface LoginSSOMed2MedViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonCreateAccount;

@end

@implementation LoginSSOMed2MedViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// TEMPORARY (remove code and enable button in storyboard in phase 2)
	[self.buttonCreateAccount setTitle:@""];
}

// Unwind Segue from AccountNewViewController
- (IBAction)unwindFromAccountRequest:(UIStoryboardSegue *)segue
{
	NSLog(@"unwindFromAccountRequest");
}

// Obtain User Data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize MedToTeleMed Login");
	
	AccountModel *accountModel = [[AccountModel alloc] init];
	UserProfileModel *profile = [UserProfileModel sharedInstance];
	
	[profile getWithCallback:^(BOOL success, UserProfileModel *profile, NSError *error)
	{
		if (success)
		{
			// Fetch Accounts and check the authorization status for each
			[accountModel getAccountsWithCallback:^(BOOL success, NSMutableArray *accounts, NSError *error)
			{
				if (success)
				{
					// Check if user is authorized for at least one account
					for (AccountModel *account in accounts)
					{
						if ([account isAuthorized])
						{
							[profile setIsAuthorized:YES];
						}
						
						NSLog(@"Account Name: %@; Status: %@", account.Name, account.MyAuthorizationStatus);
					}
					
					// Go to Main Storyboard
					[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
				}
				else
				{
					NSLog(@"LoginSSOMed2MedViewController Error: %@", error);
					
					// Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
					[self showWebViewError:[NSString stringWithFormat:@"There was a problem completing the login process:<br>%@", error.localizedDescription]];
				}
			}];
		}
		else
		{
			NSLog(@"LoginSSOMed2MedViewController Error: %@", error);
			
			// Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
			[self showWebViewError:[NSString stringWithFormat:@"There was a problem completing the login process:<br>%@", error.localizedDescription]];
		}
	}];
	
	[super finalizeLogin];
}

/* - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showAccountNew"])
	{
		AccountNewViewController *accountNewViewController = segue.destinationViewController;
		
		// Set delegate
		[accountNewViewController setDelegate:self];
	}
}*/

@end
