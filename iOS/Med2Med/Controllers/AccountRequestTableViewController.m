//
//  AccountRequestTableViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 12/19/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "AccountRequestTableViewController.h"

@interface AccountRequestTableViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet UITextField *textFieldAccountCode;

@end

@implementation AccountRequestTableViewController

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus account code field
	[self.textFieldAccountCode becomeFirstResponder];
}

- (IBAction)getAccountCodeHelp:(id)sender
{
	UIAlertController *accountCodeHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"To request access to a new medical group, you must enter the code provided to you by TeleMed." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[accountCodeHelpAlertController addAction:actionOK];

	// PreferredAction only supported in 9.0+
	if ([accountCodeHelpAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[accountCodeHelpAlertController setPreferredAction:actionOK];
	}

	// Show Alert
	[self presentViewController:accountCodeHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitAccountCode:(id)sender
{
	// TEMPORARY (remove when Account Request web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Request Medical Group Incomplete" message:@"Web services are incomplete for requesting a medical group." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Go back to AccountPickerViewController or MessageNewUnauthorizedTableViewController
		[self performSegueWithIdentifier:@"unwindFromAccountRequest" sender:self];
	}];

	[successAlertController addAction:actionOK];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:actionOK];
	}

	// Show alert
	[self presentViewController:successAlertController animated:YES completion:nil];
	// END TEMPORARY
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
	
	// Validate form
	[self.navigationItem.rightBarButtonItem setEnabled: ! [self.textFieldAccountCode.text isEqualToString:@""]];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self.buttonHelp setHidden:NO];
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// Submit account code
	[self submitAccountCode:textField];
	
	// Hide keyboard
	[textField resignFirstResponder];
	
	return YES;
}

// Avoid upper case header
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
	{
		UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
		
		[headerView.textLabel setText:[super tableView:tableView titleForHeaderInSection:section]];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
