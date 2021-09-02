//
//  RevealViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "RevealViewController.h"
#import "SWRevealViewController.h"

@implementation RevealViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sideNavigationButton.target = self.revealViewController;
	_sideNavigationButton.action = @selector(revealToggle:);
	
	// HelpViewController may not have RevealViewController when navigated to from LoginViewController or PhoneNumberViewController
	if (self.revealViewController)
	{
		// Set RevealViewController delegate
		[self.revealViewController setDelegate:self];
		
		// Register a gesture recognizer for navigation controller
		[self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
	}
}

// Prevent user interaction on front view while navigation is open
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
	// If position is open
	if (position == FrontViewPositionRight)
	{
		// Prevent user interaction on everything except the navigation bar (so that menu button is still clickable)
		for (id subview in [revealController.frontViewController.view subviews])
		{
			if (! [subview isKindOfClass:UINavigationBar.class])
			{
				[subview setUserInteractionEnabled:NO];
			}
		}
	}
	else
	{
		// Re-enable user interaction on everything
		for (id subview in [revealController.frontViewController.view subviews])
		{
			[subview setUserInteractionEnabled:YES];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
