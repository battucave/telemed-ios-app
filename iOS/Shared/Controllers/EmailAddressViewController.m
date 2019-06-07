//
//  EmailAddressViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/16/19.
//  Copyright © 2019 SolutionBuilt. All rights reserved.
//

#import "EmailAddressViewController.h"
#import "AppDelegate.h"
#import "ErrorAlertController.h"
#import "SSOProviderModel.h"

@interface EmailAddressViewController ()

// @property (weak, nonatomic) IBOutlet UIImageView *imageLogo;
@property (weak, nonatomic) IBOutlet UITextField *textFieldEmailAddress;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmEmailAddress;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@end

@implementation EmailAddressViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Attach toolbar to top of keyboard
	[self.textFieldEmailAddress setInputAccessoryView:self.viewToolbar];
	[self.textFieldConfirmEmailAddress setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus email address field
	[self.textFieldEmailAddress becomeFirstResponder];
}

- (IBAction)getEmailAddressHelp:(id)sender
{
	UIAlertController *emailAddressHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"We use your email address to support our single sign-on (SSO) services. Your email address will not be shared." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[emailAddressHelpAlertController addAction:okAction];

	// Set preferred action
	[emailAddressHelpAlertController setPreferredAction:okAction];

	// Show alert
	[self presentViewController:emailAddressHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitEmailAddress:(id)sender
{
	// Verify that form is valid
	if (! [self validateForm])
	{
		// Show error message without title
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"", NSLocalizedFailureReasonErrorKey, @"All fields are required.", NSLocalizedDescriptionKey, nil]];
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	}
	// Verify that new password matches confirm password
	else if (! [self.textFieldEmailAddress.text isEqualToString:self.textFieldConfirmEmailAddress.text])
	{
		// Show error message without title
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"", NSLocalizedFailureReasonErrorKey, @"Email Address and Confirm Email Address fields do not match.", NSLocalizedDescriptionKey, nil]];
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
		
		[self.textFieldConfirmEmailAddress becomeFirstResponder];
	}
	else
	{
		SSOProviderModel *ssoProviderModel = [[SSOProviderModel alloc] init];
		
		// Validate email address by running SSOProviderModel's validateByEmailAddress:
		[ssoProviderModel validateEmailAddress:self.textFieldEmailAddress.text withCallback:^(BOOL success, NSError *error)
		{
			// SSO provider is valid so save it and go to the next screen in the login process
			if (success)
			{
				[ssoProviderModel setEmailAddress:self.textFieldEmailAddress.text];
				
				[(AppDelegate *)[[UIApplication sharedApplication] delegate] goToNextScreen];
			}
			// Email address is invalid so show error
			else
			{
				// Re-show keyboard
				[self.textFieldEmailAddress becomeFirstResponder];
				
				ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
				
				[errorAlertController show:error];
			}
		}];
	}
}

// Check required fields to determine if form can be submitted
- (BOOL)validateForm
{
	return (! [self.textFieldEmailAddress.text isEqualToString:@""] && ! [self.textFieldConfirmEmailAddress.text isEqualToString:@""]);
}

@end
