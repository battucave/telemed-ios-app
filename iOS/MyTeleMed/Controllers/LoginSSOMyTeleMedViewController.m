//
//  LoginSSOMyTeleMedViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/17/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "LoginSSOMyTeleMedViewController.h"
#import "PhoneNumberViewController.h"
#import "AppDelegate.h"
#import "ELCUIApplication.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@implementation LoginSSOMyTeleMedViewController

// Unwind Segue from PhoneNumberViewController
- (IBAction)unwindFromPhoneNumber:(UIStoryboardSegue *)segue
{
	NSLog(@"unwindFromPhoneNumber");
}

// Obtain User Data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize MyTeleMed Login");
	
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
	[myProfileModel getWithCallback:^(BOOL success, MyProfileModel *profile, NSError *error)
	{
		if(success)
		{
			RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
			
			// Update Timeout Period to the value sent from Server
			[(ELCUIApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[profile.TimeoutPeriodMins intValue]];
			
			NSLog(@"User ID: %@", myProfileModel.ID);
			NSLog(@"Preferred Account ID: %@", myProfileModel.MyPreferredAccount.ID);
			NSLog(@"Device ID: %@", registeredDeviceModel.ID);
			NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
			
			// Check if device is already registered with TeleMed service
			if(registeredDeviceModel.PhoneNumber.length > 0 && ! [registeredDeviceModel.PhoneNumber isEqualToString:@"000-000-0000"])
			{
				// Phone Number is already registered with Web Service, so we just need to update Device Token (Device Token can change randomly so this keeps it up to date)
				[registeredDeviceModel setShouldRegister:YES];
				
				[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
				{
					// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
					if(registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
					{
						[self showWebViewError:[NSString stringWithFormat:@"There was a problem registering your device on our network:<br>%@", registeredDeviceError.localizedDescription]];
					}
					
					if(success)
					{
						// Go to Main Storyboard
						[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
					}
					// Error updating Device Token so show Phone Number screen so user can register correct phone number
					else
					{
						[self performSegueWithIdentifier:@"showPhoneNumber" sender:self];
					}
				}];
			}
			// Device ID is not yet registered with TeleMed, so show Phone Number screen to register
			else
			{
				[self performSegueWithIdentifier:@"showPhoneNumber" sender:self];
			}
		}
		else
		{
			NSLog(@"LoginSSOMyTeleMedViewController Error: %@", error);
			
			// Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
			[self showWebViewError:[NSString stringWithFormat:@"There was a problem completing the login process:<br>%@", error.localizedDescription]];
		}
	}];
	
	[super finalizeLogin];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showPhoneNumber"])
	{
		PhoneNumberViewController *phoneNumberViewController = segue.destinationViewController;
		
		// Set delegate
		[phoneNumberViewController setDelegate:self];
	}
}

@end
