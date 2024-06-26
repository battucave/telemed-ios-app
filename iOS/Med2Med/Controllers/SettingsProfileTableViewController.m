//
//  SettingsProfileTableViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 12/7/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "SettingsProfileTableViewController.h"
#import "UserProfileModel.h"

@interface SettingsProfileTableViewController ()

@property (nonatomic) IBOutletCollection(UITextField) NSArray *textFields; // Must be a strong reference

@end

@implementation SettingsProfileTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[self.textFields objectAtIndex:0] becomeFirstResponder];
	
	UserProfileModel *profile = UserProfileModel.sharedInstance;
	
	// Initialize text field values
	[self setTextFieldValues: profile];
	
	// Refresh user profile and update text field values
	[profile getWithCallback:^(BOOL success, UserProfileModel *profile, NSError *error)
	{
		// Update text field values with new data
		if (success)
		{
			[self setTextFieldValues: profile];
		}
	}];
}

// MED2MED PHASE 2 LOGIC
- (IBAction)saveProfile:(id)sender
{
	NSLog(@"Save Profile");
	
	// UserProfileModel *profile = UserProfileModel.sharedInstance;
	
	// [profile saveUserProfile:data];
}

- (IBAction)textFieldDidEditingChange:(UITextField *)sender
{
	// Validate form
	[self validateForm];
}

// MED2MED PHASE 2 LOGIC (figure out how to prevent updating value for field if user has already begun typing in it)
- (void)setTextFieldValues:(UserProfileModel *) profile
{
	for (UITextField *textField in self.textFields)
	{
		NSString *identifier = textField.accessibilityIdentifier;
		
		if ([profile respondsToSelector:NSSelectorFromString(identifier)])
		{
			[textField setText:[profile valueForKey:identifier]];
		}
	}
}

// Check required fields to determine if form can be submitted
- (void)validateForm
{
	BOOL isSaveEnabled = YES;
	
	for (UITextField *textField in self.textFields)
	{
		// Loop through text fields - if any except job title are empty, then don't enable save button
		if (! [textField.accessibilityIdentifier isEqualToString:@"JobTitle"] && [textField.text isEqualToString:@""])
		{
			isSaveEnabled = NO;
		}
	}
	
	[self.navigationItem.rightBarButtonItem setEnabled:isSaveEnabled];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSUInteger currentIndex = [self.textFields indexOfObject:textField];
	NSUInteger nextIndex = currentIndex + 1;
	
	if (nextIndex < [self.textFields count])
	{
		[[self.textFields objectAtIndex:nextIndex] becomeFirstResponder];
	}
	else
	{
		[[self.textFields objectAtIndex:currentIndex] resignFirstResponder];
	}
	
	return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0 : 46.0;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
