//
//  SettingsPasswordTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright © 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsPasswordTableViewController.h"
#import "PasswordChangeModel.h"

@interface SettingsPasswordTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldCurrentPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmNewPassword;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSave;

@end

@implementation SettingsPasswordTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.textFieldCurrentPassword becomeFirstResponder];
}

- (IBAction)changePassword:(id)sender
{
	PasswordChangeModel *passwordChangeModel = [[PasswordChangeModel alloc] init];
	
	[passwordChangeModel setDelegate:self];
	
	// Verify that New Password matches Confirm Password
	if( ! [self.textFieldNewPassword.text isEqualToString:self.textFieldConfirmNewPassword.text])
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Change Password Error", NSLocalizedFailureReasonErrorKey, @"New Password and Confirm New Password do not match.", NSLocalizedDescriptionKey, nil]];
		
		[passwordChangeModel showError:error];
		
		[self.textFieldConfirmNewPassword setText:@""];
		[self.textFieldConfirmNewPassword becomeFirstResponder];
		
		return;
	}
	
	[passwordChangeModel changePassword:self.textFieldNewPassword.text withOldPassword:self.textFieldCurrentPassword.text];
}

- (IBAction)textFieldDidChange:(id)sender
{
	// Validate form
	[self validateForm];
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
	/*UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Change Password" message:@"Password changed successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];*/
	
	// Go back to Settings
	[self.navigationController popViewControllerAnimated:YES];
}

// Check required fields to determine if Form can be submitted
- (void)validateForm
{
	[self.buttonSave setEnabled:( ! [self.textFieldCurrentPassword.text isEqualToString:@""] && ! [self.textFieldNewPassword.text isEqualToString:@""] && ! [self.textFieldConfirmNewPassword.text isEqualToString:@""])];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0 : 46.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	// Remove selection highlight
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end