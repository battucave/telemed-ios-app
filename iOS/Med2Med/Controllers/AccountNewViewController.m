//
//  AccountNewViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/20/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "AccountNewViewController.h"
#import "HelpViewController.h"

@interface AccountNewViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textFieldAccountCode;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@end

/*************************************************************************
* THIS SCREEN SHOULD BE A NEW ACCOUNT FORM (PROFILE INFO AND PASSWORD)   *
* CURRENT IMPLEMENTATION SUPERSEDED BY ACCOUNTREQUESTTABLEVIEWCONTROLLER *
* SEE REVISED NEW USER PROCESS IN DOCUMENTATION                          *
*************************************************************************/

@implementation AccountNewViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Shift form up for screens 480 or less in height
	if ([UIScreen mainScreen].bounds.size.height <= 480)
	{
		[self.constraintFormTop setConstant:12.0f];
	}
	
	// Auto-focus account code field
	[self.textFieldAccountCode becomeFirstResponder];
	
	// Attach toolbar to top of keyboard
	[self.textFieldAccountCode setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
}

- (IBAction)getAccountCodeHelp:(id)sender
{
	UIAlertController *accountCodeHelpAlertController = [UIAlertController alertControllerWithTitle:@"What's This For?" message:@"To create your new account, you must enter the code sent to you by TeleMed." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];

	[accountCodeHelpAlertController addAction:okAction];

	// PreferredAction only supported in 9.0+
	if ([accountCodeHelpAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[accountCodeHelpAlertController setPreferredAction:okAction];
	}

	// Show Alert
	[self presentViewController:accountCodeHelpAlertController animated:YES completion:nil];
}

- (IBAction)submitAccountCode:(id)sender
{
	// TEMPORARY (remove when Hospital Request web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Medical Group Authorization Incomplete" message:@"Web services are incomplete for requesting medical group authorization." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Account Code saved successfully so return to Login
		[self.navigationController popViewControllerAnimated:YES];
	}];

	[successAlertController addAction:okAction];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:okAction];
	}

	// Show Alert
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showHelpFromAccountNew"])
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
