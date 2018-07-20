//
//  PasswordViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/10/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "AppDelegate.h"
#import "PasswordViewController.h"
#import "ErrorAlertController.h"
#import "ProfileProtocol.h"
#import "PasswordChangeModel.h"

#ifdef MYTELEMED
	#import "MyProfileModel.h"
#endif

#ifdef MED2MED
	#import "UserProfileModel.h"
#endif

@interface PasswordViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageLogo;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCurrentPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNewPassword;
@property (weak, nonatomic) IBOutlet UIView *viewToolbar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintScrollViewTop;

@end

@implementation PasswordViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Attach toolbar to top of keyboard
	[self.textFieldCurrentPassword setInputAccessoryView:self.viewToolbar];
	[self.textFieldNewPassword setInputAccessoryView:self.viewToolbar];
	[self.textFieldConfirmNewPassword setInputAccessoryView:self.viewToolbar];
	[self.viewToolbar removeFromSuperview];
	
	// iPhone < 6 - Hide logo image so that the entire form is visible
	if ([UIScreen mainScreen].bounds.size.height < 667.0f)
	{
		[self.imageLogo setHidden:YES];
		[self.constraintScrollViewTop setConstant:5.0f];
	}
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// iPhone > 4(S) - Auto-focus current password field (logic has to occur in viewDidAppear: so that keyboard observers can modify the scroll view; iPhone 4(S) cannot fit entire form while keyboard visible so show it without keyboard first)
	if ([UIScreen mainScreen].bounds.size.height > 480.0f)
	{
		[self.textFieldCurrentPassword becomeFirstResponder];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)changePassword:(id)sender
{
	PasswordChangeModel *passwordChangeModel = [[PasswordChangeModel alloc] init];
	
	[passwordChangeModel setDelegate:self];
	
	// Verify that form is valid
	if (! [self validateForm])
	{
		// Show error message without title
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"", NSLocalizedFailureReasonErrorKey, @"All fields are required.", NSLocalizedDescriptionKey, nil]];
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	}
	// Verify that New Password matches Confirm Password
	else if (! [self.textFieldNewPassword.text isEqualToString:self.textFieldConfirmNewPassword.text])
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

- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Convert it to the coordinates of scroll view
	keyboardFrame = [self.scrollView convertRect:keyboardFrame fromView:nil];
	
	// Determine if the keyboard covers the scroll view
    CGRect intersect = CGRectIntersection(keyboardFrame, self.scrollView.bounds);
	
	// If the keyboard covers the scroll view
    if (! CGRectIsNull(intersect))
    {
    	// Get details of keyboard animation
    	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
		
    	// Animate scroll view above keyboard
    	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
    	{
    		[self.scrollView setContentInset:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
    		[self.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
		} completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	// Get details of keyboard animation
	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
	
	// Animate scroll view back down to bottom of screen
	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
	{
		[self.scrollView setContentInset:UIEdgeInsetsZero];
		[self.scrollView setScrollIndicatorInsets:UIEdgeInsetsZero];
	} completion:nil];
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
	// Remove password change requirement
	#ifdef MYTELEMED
		id <ProfileProtocol> profile = [MyProfileModel sharedInstance];
	
		[profile setPasswordChangeRequired:NO];

	#elif defined MED2MED
		id <ProfileProtocol> profile = [UserProfileModel sharedInstance];
	
		[profile setPasswordChangeRequired:NO];
	#endif
	
	// Go to the next screen in the login process
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
}

// Check required fields to determine if form can be submitted
- (BOOL)validateForm
{
	return (! [self.textFieldCurrentPassword.text isEqualToString:@""] && ! [self.textFieldNewPassword.text isEqualToString:@""] && ! [self.textFieldConfirmNewPassword.text isEqualToString:@""]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
