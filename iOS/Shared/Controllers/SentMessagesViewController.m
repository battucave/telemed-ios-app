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
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // Must be a strong reference
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) NSArray *selectedMessages;
@property (nonatomic) NSString *navigationBarTitle;

@end

@implementation SentMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Modify text of future back button to this view controller
	[self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Sent" style:UIBarButtonItemStylePlain target:nil action:nil]];
	
	// Hide swipe message if it has been disabled (triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:SWIPE_MESSAGE_DISABLED])
	{
		[self.viewSwipeMessage setHidden:YES];
	}
	
	[super viewWillAppear:animated];
}

// Delegate method from SWRevealController that fires when a recognized gesture has ended
- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController
{
	[self performSelector:@selector(SWRevealControllerDidMoveToPosition:) withObject:revealController afterDelay:0.25];
}

// Determine if SWRevealController has opened. This method is only fired after a delay from revealControllerPanGestureEnded delegate method so we can determine if gesture resulted in opening the SWRevealController
- (void)SWRevealControllerDidMoveToPosition:(SWRevealViewController *)revealController
{
	// If position is open
	if (revealController.frontViewPosition == FrontViewPositionRight)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
		[settings synchronize];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded table view controller inside container
	if ([segue.identifier isEqualToString:@"embedSentMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set messages type to sent
		[self.messagesTableViewController initMessagesWithType:@"Sent"];
		[self.messagesTableViewController setDelegate:self];
		
		// In XCode 8+, all view frame sizes are initially 1000x1000. Have to call "layoutIfNeeded" first to get actual value.
		[self.toolbarBottom layoutIfNeeded];
		
		// Increase bottom inset of messages table so that its bottom scroll position rests above bottom toolbar
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
