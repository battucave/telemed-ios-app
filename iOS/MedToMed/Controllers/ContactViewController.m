//
//  ContactViewController.m
//  MedToMed
//
//  Created by SolutionBuilt on 3/04/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import "ContactViewController.h"
#import "AccountPickerViewController.h"

@implementation ContactViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Account picker
	if ([segue.identifier isEqualToString:@"showAccountPickerFromContact"])
	{
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		// Update account picker screen title
		[accountPickerViewController setTitle:@"Call Medical Group"];
		
		// Enable account calling and account selection on account picker screen
		[accountPickerViewController setShouldCallAccount:YES];
		[accountPickerViewController setShouldSelectAccount:YES];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
