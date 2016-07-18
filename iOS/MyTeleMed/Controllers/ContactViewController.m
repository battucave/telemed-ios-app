//
//  ContactViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"
#import "CallModel.h"
#import "MyProfileModel.h"

@interface ContactViewController ()

@property (nonatomic) CallModel *callModel;

@end

@implementation ContactViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (IBAction)callTeleMed:(id)sender
{
	UIAlertView *confirmAlertView = [[UIAlertView alloc] initWithTitle:@"Call TeleMed" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Call", nil];
	
	[confirmAlertView setTag:1];
	[confirmAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == 1 && buttonIndex > 0)
	{
		[self setCallModel:[[CallModel alloc] init]];
		[self.callModel setDelegate:self];
		
		[self.callModel callTeleMed];
	}
}

// Return success from CallTeleMedModel delegate
- (void)callTeleMedSuccess
{
	NSLog(@"Call TeleMed request sent successfully");
}

// Return error from CallTeleMedModel delegate
- (void)callTeleMedError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.callModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Call TeleMed Error" message:@"There was a problem requesting a Return Call. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end