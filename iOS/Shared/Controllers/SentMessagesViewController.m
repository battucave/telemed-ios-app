//
//  SentMessagesViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 3/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "SentMessagesViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"

@interface SentMessagesViewController ()

@property (weak, nonatomic) MessagesTableViewController *messagesTableViewController;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // (Must be strong reference)
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // (Must be strong reference)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTopSpace;

@property (nonatomic) NSArray *selectedMessages;
@property (nonatomic) NSString *navigationBarTitle;

@end

@implementation SentMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store Navigation Bar Title
	[self setNavigationBarTitle:self.navigationItem.title];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If Swipe Message has been disabled (Triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:@"swipeMessageDisabled"])
	{
		// Change top layout constraint to 0 (Keep Swipe Message there as it will simply be hidden under the Container View)
		self.constraintTopSpace.constant = 0;
	}
	
	// Modify text of future Back Button to this View Controller
	[self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Sent" style:UIBarButtonItemStylePlain target:nil action:nil]];
	
	[super viewWillAppear:animated];
}

// Delegate method from SWRevealController that fires when a Recognized Gesture has ended
- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController
{
	[self performSelector:@selector(SWRevealControllerDidMoveToPosition:) withObject:revealController afterDelay:0.25];
}

// Determine if SWRevealController has opened. This method is only fired after a delay from revealControllerPanGestureEnded Delegate method so we can determine if Gesture resulted in opening the SWRevealController
- (void)SWRevealControllerDidMoveToPosition:(SWRevealViewController *)revealController
{
	// If position is open
	if (revealController.frontViewPosition == FrontViewPositionRight)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setBool:YES forKey:@"swipeMessageDisabled"];
		[settings synchronize];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded Table View Controller inside Container
	if ([segue.identifier isEqualToString:@"embedSentMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set Messages Type to Sent
		[self.messagesTableViewController initMessagesWithType:2];
		[self.messagesTableViewController setDelegate:self];
		
		// In XCode 8+, all view frame sizes are initially 1000x1000. Have to call "layoutIfNeeded" first to get actual value.
		[self.toolbarBottom layoutIfNeeded];
		
		// Increase bottom inset of Messages Table so that its bottom scroll position rests above bottom Toolbar
		UIEdgeInsets tableInset = self.messagesTableViewController.tableView.contentInset;
		CGSize toolbarSize = self.toolbarBottom.frame.size;
		
		tableInset.bottom = toolbarSize.height;
		[self.messagesTableViewController.tableView setContentInset:tableInset];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
