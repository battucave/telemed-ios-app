//
//  NewAccountViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/20/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "NewAccountViewController.h"
#import "HelpViewController.h"

@interface NewAccountViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintFormTop;
@property (weak, nonatomic) IBOutlet UITextField *textAccountCode;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation NewAccountViewController

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
	[self.textAccountCode setInputAccessoryView:self.toolbar];
	[self.toolbar removeFromSuperview];
}

- (IBAction)showHelp:(id)sender
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	HelpViewController *helpViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
	
	[helpViewController setShowBackButton:YES];
	[self.navigationController pushViewController:helpViewController animated:YES];
}

- (IBAction)submitAccountCode:(id)sender
{
	NSLog(@"Submit Account Code");
	
	// Submit Account Code web service
		// Go to Main Storyboard
		// [(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
