//
//  LoginSSOMyTeleMedViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/17/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "LoginSSOMyTeleMedViewController.h"
#import "AppDelegate.h"
#import "PhoneNumberViewController.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@implementation LoginSSOMyTeleMedViewController

// Obtain user data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize MyTeleMed Login");
	
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
	[myProfileModel getWithCallback:^(BOOL success, MyProfileModel *profile, NSError *error)
	{
		if (success)
		{
			RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
			
			NSLog(@"User ID: %@", myProfileModel.ID);
			NSLog(@"Preferred Account ID: %@", myProfileModel.MyPreferredAccount.ID);
			NSLog(@"Device ID: %@", registeredDeviceModel.ID);
			NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
			
			// Check if user has previously registered this device with TeleMed
			if ([registeredDeviceModel isRegistered])
			{
				// Phone Number was previously registered with TeleMed, but we should update the device token in case it changed
				[registeredDeviceModel setShouldRegister:YES];
				
				[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
				{
					// If there is an error other than the device offline error, show an error and require user to enter their phone number again
					if (registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
					{
						// Show the error even if success returned true so that TeleMed can track issue down
						[self showWebViewError:[NSString stringWithFormat:@"There was a problem registering your device on our network:<br>%@", registeredDeviceError.localizedDescription]];
					}
					
					// Go to the next screen in the login process
					[(AppDelegate *)[[UIApplication sharedApplication] delegate] goToNextScreen];
				}];
			}
			// Device id is not yet registered with TeleMed, so show PhoneNumberViewController
			else
			{
				// Go to the next screen in the login process
				[(AppDelegate *)[[UIApplication sharedApplication] delegate] goToNextScreen];
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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
