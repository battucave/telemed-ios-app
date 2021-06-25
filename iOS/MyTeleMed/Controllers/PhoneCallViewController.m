//
//  PhoneCallViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/9/19.
//  Copyright © 2019 SolutionBuilt. All rights reserved.
//

#import "PhoneCallViewController.h"
#import "ErrorAlertController.h"
#import "CallModel.h"

@interface PhoneCallViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageTeleMedIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelNameIntro;
@property (weak, nonatomic) IBOutlet UILabel *labelPhoneNumberIntro;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintViewSpacerHeight;

@end

@implementation PhoneCallViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// If returning call to sender, then set sender name (unless the sender is TeleMed)
	if (self.message && ! [self.message.SenderName isEqualToString:@"TeleMed"])
	{
		[self.labelName setText:self.message.SenderName];
	}
	// If calling TeleMed, then change the wording
	else
	{
		[self.labelNameIntro setText:@"Please hold"];
		[self.labelName setHidden:YES];
	}
	
	// The System font cannot be assigned for attributed text, so assign it programmatically
	[self.labelPhoneNumberIntro setFont:[UIFont systemFontOfSize:self.labelPhoneNumberIntro.font.pointSize weight:UIFontWeightSemibold]];
	
	// Adjust spacer height for screens less than or equal to 568
	if ([UIScreen mainScreen].bounds.size.height <= 568)
	{
		[self.constraintViewSpacerHeight setConstant:10.0f];
	}

	// Add call connected observer to dismiss screen after return call from TeleMed was successfully received
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didConnectCall:) name:NOTIFICATION_APPLICATION_DID_CONNECT_CALL object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Animate the TeleMed icon to rotate around the y-axis
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];

	rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
	rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	rotationAnimation.duration = 2;
	rotationAnimation.repeatCount = HUGE_VALF;

	[self.imageTeleMedIcon.layer addAnimation:rotationAnimation forKey:rotationAnimation.keyPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove notification observers
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (IBAction)goBack:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Dismiss this screen and go back to the previous one
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	});
}

// Return error from CallTeleMedModel delegate (received if user does not retry the request)
- (void)callError:(NSError *)error
{
	NSLog(@"Call TeleMed request failed: %@", error);
	
	// Call failed so dismiss this screen
	[self goBack:nil];
}

// Return pending from CallTeleMedModel delegate
- (void)callPending
{
	NSLog(@"Call Sender request pending.");
}

// Return success from CallTeleMedModel delegate
- (void)callSuccess
{
	// Empty
}

// User answered a phone call so assume that the return call from TeleMed was successfully received
- (void)didConnectCall:(NSNotification *)notification
{
	NSLog(@"Call received");
	
	// Call succeeded so dismiss this screen
	[self goBack:nil];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove notification observers
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
