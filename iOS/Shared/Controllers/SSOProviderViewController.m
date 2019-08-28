//
//  SSOProviderViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/20/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "SSOProviderViewController.h"
#import "ErrorAlertController.h"
#import "HelpViewController.h"
#import "SSOProviderModel.h"

@interface SSOProviderViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldSSOProvider;
@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) SSOProviderModel *ssoProviderModel;

@end

@implementation SSOProviderViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Auto-populate sso provider field
	self.ssoProviderModel = [[SSOProviderModel alloc] init];
	
	[self.textFieldSSOProvider setText:self.ssoProviderModel.Name];
	
	// Attach toolbar to top of keyboard
	[self.textFieldSSOProvider setInputAccessoryView:self.toolbar];
	[self.toolbar removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Auto-focus sso provider field
	[self.textFieldSSOProvider becomeFirstResponder];
}

- (IBAction)submitSSOProvider:(id)sender
{
	NSString *name = [self.textFieldSSOProvider.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	// Validate SSO provider using api
	[self.ssoProviderModel validateName:name withCallback:^(BOOL success, NSError *error)
	{
		// SSO provider is valid so save it and return to login
		if (success)
		{
			[self.ssoProviderModel setName:name];
			
			[self performSegueWithIdentifier:@"unwindFromSSOProvider" sender:sender];
		}
		// SSO provider is invalid so show error
		else
		{
			// Re-show keyboard
			[self.textFieldSSOProvider becomeFirstResponder];
			
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
	}];
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
	// Submit sso provider
	[self submitSSOProvider:textField];
	
	// Hide keyboard
	[textField resignFirstResponder];
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showHelpFromSSOProvider"])
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
