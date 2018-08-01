//
//  SettingsPasswordTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright © 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsPasswordTableViewController.h"
#import "ErrorAlertController.h"
#import "PasswordChangeModel.h"

@interface SettingsPasswordTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldCurrentPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNewPassword;

@end

@implementation SettingsPasswordTableViewController

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus current password field
	[self.textFieldCurrentPassword becomeFirstResponder];
}

- (IBAction)changePassword:(id)sender
{
	PasswordChangeModel *passwordChangeModel = [[PasswordChangeModel alloc] init];
	
	[passwordChangeModel setDelegate:self];
	
	// Verify that new password matches confirm password
	if (! [self.textFieldNewPassword.text isEqualToString:self.textFieldConfirmNewPassword.text])
	{
		// Show error message without title
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"", NSLocalizedFailureReasonErrorKey, @"New Password and Confirm New Password fields do not match.", NSLocalizedDescriptionKey, nil]];
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
		
		[self.textFieldConfirmNewPassword setText:@""];
		[self.textFieldConfirmNewPassword becomeFirstResponder];
	}
	else
	{
		[passwordChangeModel changePassword:self.textFieldNewPassword.text withOldPassword:self.textFieldCurrentPassword.text];
	}
}

- (IBAction)textFieldDidEditingChange:(UITextField *)sender
{
	// Validate form
	[self validateForm];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.textFieldCurrentPassword)
	{
		[self.textFieldNewPassword becomeFirstResponder];
	}
	else if (textField == self.textFieldNewPassword)
	{
		[self.textFieldConfirmNewPassword becomeFirstResponder];
	}
	else if (textField == self.textFieldConfirmNewPassword)
	{
		// Submit change password
		[self changePassword:textField];
		
		[self.textFieldConfirmNewPassword resignFirstResponder];
	}
	
	return YES;
}

// Return pending from PasswordChangeModel delegate (not used because can't assume success for this scenario - old password may be incorrect, new password may not meet requirements, etc)
/*- (void)changePasswordPending
{
	// Go back to Settings (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}*/

// Return success from PasswordChangeModel delegate
- (void)changePasswordSuccess
{
	// Go back to Settings
	[self.navigationController popViewControllerAnimated:YES];
}

// Check required fields to determine if form can be submitted
- (void)validateForm
{
	[self.navigationItem.rightBarButtonItem setEnabled:(! [self.textFieldCurrentPassword.text isEqualToString:@""] && ! [self.textFieldNewPassword.text isEqualToString:@""] && ! [self.textFieldConfirmNewPassword.text isEqualToString:@""])];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0f : 46.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
