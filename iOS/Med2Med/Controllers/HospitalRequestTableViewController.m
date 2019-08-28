//
//  HospitalRequestTableViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 12/19/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalRequestTableViewController.h"

@interface HospitalRequestTableViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet UITextField *textFieldHospitalCode;

@end

@implementation HospitalRequestTableViewController

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus hospital code field
	[self.textFieldHospitalCode becomeFirstResponder];
}

- (IBAction)getHospitalCodeHelp:(id)sender
{
	UIAlertController *accountCodeHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"To request access to a new hospital, you must enter the code provided to you by your hospital admin." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[accountCodeHelpAlertController addAction:okAction];

	// Set preferred action
	[accountCodeHelpAlertController setPreferredAction:okAction];

	// Show Alert
	[self presentViewController:accountCodeHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitHospitalCode:(id)sender
{
	// TEMPORARY (remove when Hospital Request web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Request Hospital Incomplete" message:@"Web services are incomplete for requesting a hospital." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Go back to HospitalPickerViewController or MessageNewUnauthorizedTableViewController
		[self performSegueWithIdentifier:@"unwindFromHospitalRequest" sender:self];
	}];

	[successAlertController addAction:okAction];

	// Set preferred action
	[successAlertController setPreferredAction:okAction];

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
	[self.navigationItem.rightBarButtonItem setEnabled: ! [self.textFieldHospitalCode.text isEqualToString:@""]];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self.buttonHelp setHidden:NO];
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// Submit hospital code
	[self submitHospitalCode:textField];
	
	// Hide keyboard
	[textField resignFirstResponder];
	
	return YES;
}

// Avoid upper case header
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	if ([view isKindOfClass:UITableViewHeaderFooterView.class])
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
