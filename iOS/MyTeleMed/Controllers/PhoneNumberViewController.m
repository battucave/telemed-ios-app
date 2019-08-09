//
//  PhoneNumberViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/27/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "PhoneNumberViewController.h"
#import "AppDelegate.h"
#import "ErrorAlertController.h"
#import "HelpViewController.h"
#import "AuthenticationModel.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@interface PhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textPhoneNumber;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

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
	
	// Attach toolbar to top of keyboard
	[self.textPhoneNumber setInputAccessoryView:self.toolbar];
	[self.toolbar removeFromSuperview];
	
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

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus phone number field
	[self.textPhoneNumber becomeFirstResponder];
}

- (IBAction)getPhoneNumberHelp:(id)sender
{
	UIAlertController *phoneNumberHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"We use your phone number as an added security precaution. The phone number you enter must already be a callback number in your account." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[phoneNumberHelpAlertController addAction:okAction];

	// Set preferred action
	[phoneNumberHelpAlertController setPreferredAction:okAction];

	// Show alert
	[self presentViewController:phoneNumberHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitPhoneNumber:(id)sender
{
	NSString *phoneNumber = self.textPhoneNumber.text;
	
	[self.textPhoneNumber resignFirstResponder];
	
	if (phoneNumber.length < 9 || phoneNumber.length > 18 || [phoneNumber isEqualToString:@"0000000000"] || [phoneNumber isEqualToString:@"000-000-0000"])
	{
		UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter a valid Phone Number." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	
		[errorAlertController addAction:okAction];
	
		// Set preferred action
		[errorAlertController setPreferredAction:okAction];
	
		// Show alert
		[self presentViewController:errorAlertController animated:YES completion:nil];
	}
	else
	{
		NSString *messagestring = [NSString stringWithFormat:@"Is %@ the correct Phone Number for this device? Your TeleMed profile will be updated.", phoneNumber];
		
		UIAlertController *confirmPhoneNumberAlertController = [UIAlertController alertControllerWithTitle:@"Confirm Phone Number" message:messagestring preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
			
			// Register phone number along with new device token
			[registeredDeviceModel setShouldRegister:YES];
			
			// Save phone number to device
			[registeredDeviceModel setPhoneNumber:self.textPhoneNumber.text];
			
			// Run register device web service
			[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *error)
			{
				AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
				
				if (success)
				{
					// Go to the next screen in the login process
					[appDelegate goToNextScreen];
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
					UIAlertAction *goBackAction = [UIAlertAction actionWithTitle:@"Go Back" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
					{
						AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	
						// Clear stored authenticated data
						[authenticationModel doLogout];
						
						// Go back to login screen (user navigated here from login screen)
						if ([self.navigationController.viewControllers count] > 1)
						{
							[self.navigationController popToRootViewControllerAnimated:YES];
						}
						// Go back to login screen (user bypassed login, but was sent here due to invalid phone number)
						else
						{
							[appDelegate goToLoginScreen];
						}
					}];
					UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:nil];
				
					[errorAlertController addAction:retryAction];
					[errorAlertController addAction:goBackAction];
				
					// Show alert
					[self presentViewController:errorAlertController animated:YES completion:nil];
				}
			}];
		}];

		[confirmPhoneNumberAlertController addAction:noAction];
		[confirmPhoneNumberAlertController addAction:yesAction];

		// Set preferred action
		[confirmPhoneNumberAlertController setPreferredAction:yesAction];

		// Show alert
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
