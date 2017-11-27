//
//  AccountNewViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/20/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "AccountNewViewController.h"
#import "HelpViewController.h"

@interface AccountNewViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textAccountCode;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@end

@implementation AccountNewViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSLog(@"Create New Account");
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
	
	// Auto-focus account code field
	[self.textAccountCode becomeFirstResponder];
	
	// Attach toolbar to top of keyboard
	[self.textAccountCode setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
}

- (IBAction)submitAccountCode:(id)sender
{
	NSLog(@"Submit Account Code");
	
	// Submit Account Code web service
		// Account Code saved successfully so return to Login
		[self performSegueWithIdentifier:@"unwindFromAccountNew" sender:sender];
	// End Submit Account Code web service
}

- (IBAction)getAccountCodeHelp:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"What's This For?" message:@"To create your new account, you must enter the code sent to you by TeleMed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alert show];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showHelp"])
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
