//
//  SettingsPasswordTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsPasswordTableViewController.h"
//#import "UserModel.h"

@interface SettingsPasswordTableViewController ()

//@property (nonatomic) UserModel *userModel;

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

- (IBAction)textFieldDidChange:(id)sender
{
	// Validate form
	[self validateForm];
}

- (IBAction)savePassword:(id)sender
{
	NSString *errorMessage;
	
	if( ! [self.textFieldNewPassword.text isEqualToString:self.textFieldConfirmNewPassword.text])
	{
		errorMessage = @"New Password and Confirm New Password do not match.";
		
		[self.textFieldConfirmNewPassword setText:@""];
		[self.textFieldConfirmNewPassword becomeFirstResponder];
	}
	
	if(errorMessage != nil)
	{
		UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Password Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[errorAlertView show];
	}
	else
	{
		/*[self setUserModel:[[UserModel alloc] init]];
		
		[self.userModel setDelegate:self];
		[self.userModel updateSecurity:self.textFieldNewPassword.text withOldPassword:self.textFieldCurrentPassword.text];*/
	}
}

// Return success from UserModel delegate
- (void)updateSecuritySuccess
{
	// Clear fields
	[self.textFieldCurrentPassword setText:@""];
	[self.textFieldNewPassword setText:@""];
	[self.textFieldConfirmNewPassword setText:@""];
	
	UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"Password Reset" message:@"Password updated successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];
	
	// Go back to Settings
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from UserModel delegate
- (void)updateSecurityError:(NSError *)error
{
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Password Error" message:@"There was a problem resetting your Password. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Return error with custom message from UserModel delegate
- (void)updateSecurityInvalidError:(NSError *)error
{
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Password Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
	
	switch(error.code)
	{
		// Current Password Incorrect
		case 10:
		{
			[self.textFieldCurrentPassword setText:@""];
			[self.textFieldCurrentPassword becomeFirstResponder];
			
			break;
		}
		
		// New Password Length Error
		case 11:
		{
			[self.textFieldNewPassword setText:@""];
			[self.textFieldConfirmNewPassword setText:@""];
			[self.textFieldNewPassword becomeFirstResponder];
			
			break;
		}
	}
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
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
