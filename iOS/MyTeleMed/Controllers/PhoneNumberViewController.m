//
//  PhoneNumberViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/27/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "AppDelegate.h"
#import "PhoneNumberViewController.h"
#import "ErrorAlertController.h"
#import "HelpViewController.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@interface PhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textPhoneNumber;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@end                              

@implementation PhoneNumberViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Shift form up for screens 480 or less in height
	if ([UIScreen mainScreen].bounds.size.height <= 480)
	{
		[self.constraintFormTop setConstant:12.0f];
	}
	
	// Auto-focus phone number field
	[self.textPhoneNumber becomeFirstResponder];
	
	// Attach toolbar to top of keyboard
	[self.textPhoneNumber setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
	
	#ifdef DEBUG
		MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
		
		switch ([myProfileModel.ID integerValue])
		{
			// Jason Hutchison
			case 5320:
				self.textPhoneNumber.text = @"2762759018";
				break;
			
			// Brian Turner
			case 31130:
				self.textPhoneNumber.text = @"4049856441";
				break;
			
			// Matt Rogers
			case 829772:
				self.textPhoneNumber.text = @"6784696061";
				break;
				
			// Shane Goodwin
			case 14140220:
				self.textPhoneNumber.text = @"4049901383";
				break;
		}
	#endif
}

- (IBAction)getPhoneNumberHelp:(id)sender
{
	UIAlertController *phoneNumberHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"As a security precaution, Apple requires apps that use your Phone Number to ask you for it." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[phoneNumberHelpAlertController addAction:actionOK];

	// PreferredAction only supported in 9.0+
	if ([phoneNumberHelpAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[phoneNumberHelpAlertController setPreferredAction:actionOK];
	}

	// Show Alert
	[self presentViewController:phoneNumberHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitPhoneNumber:(id)sender
{
	NSString *phoneNumber = self.textPhoneNumber.text;
	
	[self.textPhoneNumber resignFirstResponder];
	
	if (phoneNumber.length < 9 || phoneNumber.length > 18 || [phoneNumber isEqualToString:@"0000000000"] || [phoneNumber isEqualToString:@"000-000-0000"])
	{
		UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Invalid Phone Number" message:@"Please enter a valid Phone Number." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	
		[errorAlertController addAction:actionOK];
	
		// PreferredAction only supported in 9.0+
		if ([errorAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[errorAlertController setPreferredAction:actionOK];
		}
	
		// Show Alert
		[self presentViewController:errorAlertController animated:YES completion:nil];
	}
	else
	{
		NSString *messagestring = [NSString stringWithFormat:@"Is %@ the correct Phone Number for this device? Your TeleMed profile will be updated.", phoneNumber];
		
		UIAlertController *confirmPhoneNumberAlertController = [UIAlertController alertControllerWithTitle:@"Confirm Phone Number" message:messagestring preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
			
			// Register Phone Number along with new Device Token
			[registeredDeviceModel setShouldRegister:YES];
			
			// Save Phone Number to Device
			[registeredDeviceModel setPhoneNumber:self.textPhoneNumber.text];
			
			// Run register device web service
			[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *error)
			{
				if (success)
				{
					// Go to Main Storyboard
					[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
				}
				else
				{
					NSLog(@"PhoneNumberViewController Error: %@", error);
					
					// If device offline, show offline message
					if (error.code == NSURLErrorNotConnectedToInternet)
					{
						ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
						
						[errorAlertController show:error];
						
						return;
					}
					
					UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:error.localizedFailureReason message:[NSString stringWithFormat:@"%@ Please ensure that the phone number already exists in your account.", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *actionGoBack = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
					{
						// Go back to Login
						if (self.delegate)
						{
							[self performSegueWithIdentifier:@"unwindFromPhoneNumber" sender:self];
						}
						// User was automatically redirected to PhoneNumberViewController from AppDelegate
						else
						{
							UIViewController *loginSSOViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginSSOViewController"];
							[self.navigationController setViewControllers:@[loginSSOViewController] animated:YES];
						}
					}];
					UIAlertAction *actionRetry = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:nil];
				
					[errorAlertController addAction:actionGoBack];
					[errorAlertController addAction:actionRetry];
				
					// Show Alert
					[self presentViewController:errorAlertController animated:YES completion:nil];
				}
			}];
		}];

		[confirmPhoneNumberAlertController addAction:actionNo];
		[confirmPhoneNumberAlertController addAction:actionYes];

		// PreferredAction only supported in 9.0+
		if ([confirmPhoneNumberAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[confirmPhoneNumberAlertController setPreferredAction:actionYes];
		}

		// Show Alert
		[self presentViewController:confirmPhoneNumberAlertController animated:YES completion:nil];
	}
}

- (IBAction)textFieldDidEditingChange:(UITextField *)sender
{
	if ([sender.text isEqualToString:@""])
	{
		[self.buttonHelp setHidden:NO];
	}
	else
	{
		[self.buttonHelp setHidden:YES];
	}
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self.buttonHelp setHidden:NO];
		
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// Submit phone number
	[self submitPhoneNumber:textField];
	
	// Hide keyboard
	[textField resignFirstResponder];
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showHelpFromPhoneNumber"])
	{
		HelpViewController *helpViewController = segue.destinationViewController;
		
		[helpViewController setShowBackButton:YES];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
