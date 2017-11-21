//
//  PhoneNumberViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/27/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "PhoneNumberViewController.h"
#import "AppDelegate.h"
#import "HelpViewController.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@interface PhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textPhoneNumber;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end                              

@implementation PhoneNumberViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Shift form up for screens 480 or less in height
	if([UIScreen mainScreen].bounds.size.height <= 480)
	{
		[self.constraintFormTop setConstant:12.0f];
	}
	
	// Auto-focus phone number field
	[self.textPhoneNumber becomeFirstResponder];
	
	// Attach toolbar to top of keyboard
	[self.textPhoneNumber setInputAccessoryView:self.toolbar];
	[self.toolbar removeFromSuperview];
	
	#ifdef DEBUG
		MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
		
		switch([myProfileModel.ID integerValue])
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

- (IBAction)showHelp:(id)sender
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	HelpViewController *helpViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
	
	[helpViewController setShowBackButton:YES];
	[self.navigationController pushViewController:helpViewController animated:YES];
}

- (IBAction)submitPhoneNumber:(id)sender
{
	NSString *phoneNumber = self.textPhoneNumber.text;
	
	[self.textPhoneNumber resignFirstResponder];
	
	if(phoneNumber.length < 9 || phoneNumber.length > 18 || [phoneNumber isEqualToString:@"0000000000"] || [phoneNumber isEqualToString:@"000-000-0000"])
	{
		UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Invalid Phone Number" message:@"Please enter a valid Phone Number." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[errorAlertView show];
	}
	else
	{
		NSString *messagestring = [NSString stringWithFormat:@"Is %@ the correct Phone Number for this device? Your TeleMed profile will be updated.",
								  phoneNumber];
		
		UIAlertView *confirmAlertView = [[UIAlertView alloc] initWithTitle:@"Confirm Phone Number" message:messagestring delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		
		[confirmAlertView setTag:1];
		[confirmAlertView show];
	}
}

- (IBAction)getPhoneNumberHelp:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"What's This For?" message:@"As a security precaution, Apple requires apps that use your Phone Number to ask you for it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// Phone Number Confirmation Handler
	if(alertView.tag == 1 && buttonIndex > 0)
	{
		RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
		
		// Register Phone Number along with new Device Token
		[registeredDeviceModel setShouldRegister:YES];
		
		// Save Phone Number to Device
		[registeredDeviceModel setPhoneNumber:self.textPhoneNumber.text];
		
		// Run registerDevice web service
		[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *error)
		{
			if(success)
			{
				// Go to Main Storyboard
				[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
			}
			else
			{
				NSLog(@"PhoneNumberViewController Error: %@", error);
				
				// If device offline, show offline message
				if(error.code == NSURLErrorNotConnectedToInternet)
				{
					return [registeredDeviceModel showError:error];
				}
				
				UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:error.localizedFailureReason message:[NSString stringWithFormat:@"%@ Please ensure that the phone number already exists in your account.", error.localizedDescription] delegate:self cancelButtonTitle:@"Go Back" otherButtonTitles:@"Try Again", nil];
				errorAlertView.tag = 2;
				
				[errorAlertView show];
			}
		}];
	}
	// If user received error when attempting to register their phone number and press Go Back, then send them back to login
	else if(alertView.tag == 2 && buttonIndex == 0)
	{
		// Go back to Login
		if(self.delegate)
		{
			[self performSegueWithIdentifier:@"unwindFromPhoneNumber" sender:self];
		}
		// User was automatically redirected to PhoneNumberViewController from AppDelegate
		else
		{
			UIViewController *loginSSOViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginSSOViewController"];
			[self.navigationController setViewControllers:@[loginSSOViewController] animated:YES];
		}
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString *textString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	textString = [textString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	if(textString.length)
	{
		self.buttonHelp.hidden = YES;
	}
	else
	{
		self.buttonHelp.hidden = NO;
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	self.buttonHelp.hidden = NO;
		
	return YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
