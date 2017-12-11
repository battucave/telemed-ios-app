//
//  SSOProviderViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/20/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "SSOProviderViewController.h"
#import "HelpViewController.h"
#import "ErrorAlertController.h"
#import "SSOProviderModel.h"

@interface SSOProviderViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textSSOProvider;
@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@property (nonatomic) SSOProviderModel *ssoProviderModel;

@end

@implementation SSOProviderViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Auto-populate and auto-focus sso provider field
	self.ssoProviderModel = [[SSOProviderModel alloc] init];
	
	[self.textSSOProvider setText:self.ssoProviderModel.Name];
	[self.textSSOProvider becomeFirstResponder];
	
	// Attach toolbar to top of keyboard
	[self.textSSOProvider setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
}

- (IBAction)submitSSOProvider:(id)sender
{
	NSString *name = [self.textSSOProvider.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	// Validate SSO Provider using API
	[self.ssoProviderModel validate:name withCallback:^(BOOL success, NSError *error)
	{
		// SSO Provider is valid so save it and return to Login
		if (success)
		{
			[self.ssoProviderModel setName:name];
			
			[self performSegueWithIdentifier:@"unwindFromSSOProvider" sender:sender];
		}
		// SSO Provider is invalid so show error
		else
		{
			// If device offline, show offline message
			/*if (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
			{
				// Create reference to generic model to show offline error
				Model *model = [[Model alloc] init];
				
				return [model showError:error];
			}
			
			UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:error.localizedFailureReason message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			
			[errorAlertView show];*/
			
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
				
			[errorAlertController show:error];
		}
	}];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString *textString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	textString = [textString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (textString.length)
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
