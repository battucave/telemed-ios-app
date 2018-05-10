//
//  RevealTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 11/9/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "RevealTableViewController.h"
#import "SWRevealViewController.h"

@implementation RevealTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sideNavigationButton.target = self.revealViewController;
	_sideNavigationButton.action = @selector(revealToggle:);
	
	// Set revealViewController delegate
	[self.revealViewController setDelegate:self];
	
	// Register a Gesture Recognizer for Navigation Controller
	[self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

// Prevent user interaction on Front View while navigation is open
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
	// If position is open
	if (position == FrontViewPositionRight)
	{
		// Prevent user interaction on everything except the Navigation Bar (so that menu button is still clickable)
		for(id subview in [revealController.frontViewController.view subviews])
		{
			if (! [subview isKindOfClass:[UINavigationBar class]])
			{
				[subview setUserInteractionEnabled:NO];
			}
		}
	}
	else
	{
		// Re-enable user interaction on everything
		for(id subview in [revealController.frontViewController.view subviews])
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

- (void)dealloc
{
	// IMPORTANT: These ViewControllers are not dealloc'd as expected when using side navigation. Workaround has been added to SideNavigationViewController.m to manually remove observers
}

@end
