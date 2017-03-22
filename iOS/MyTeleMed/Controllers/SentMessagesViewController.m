//
//  SentMessagesViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "SentMessagesViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"
#import "MessageModel.h"

@interface SentMessagesViewController ()

@property (weak, nonatomic) MessagesTableViewController *messagesTableViewController;

@property (nonatomic) MessageModel *messageModel;

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
	
	// Note: programmatically set Right Bar Button Item to Apple's built-in Edit button is toggled from within MessagesTableViewController.m based on number of Filtered Messages
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If Swipe Message has been disabled (Triggering a swipe to open the menu or refresh the table will disable it)
	if([settings boolForKey:@"swipeMessageDisabled"])
	{
		// Change top layout constraint to 0 (Keep Swipe Message there as it will simply be hidden under the Container View)
		self.constraintTopSpace.constant = 0;
	}
	
	[self toggleToolbarButtons:NO];
	
	[super viewWillAppear:animated];
}

// User clicked Archive Bar Button in Toolbar (not currently used)
- (IBAction)archiveMessages:(id)sender
{
	NSInteger selectedMessageCount = [self.selectedMessages count];
	NSString *notificationMessage = [NSString stringWithFormat:@"Selecting Continue will archive %@. Archived messages can be accessed from the Main Menu.", (selectedMessageCount == 1 ? @"this message" : @"these messages")];
	
	// Ensure at least one selected Message (should never happen as Archive button should be disabled when no Messages selected)
	if(selectedMessageCount < 1)
	{
		return;
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Archive Messages" message:notificationMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
	
    [alertView show];
}

// (not currently used)
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex > 0)
	{
		// Added this because a minority of users were complaining that Archiving sometimes causes crash
		if(self.messageModel == nil)
		{
			[self setMessageModel:[[MessageModel alloc] init]];
			[self.messageModel setDelegate:self];
		}
		
		[self.messageModel modifyMultipleMessagesState:self.selectedMessages state:@"archive"];
	}
}

// Override selectedMessages setter
- (void)setSelectedMessages:(NSArray *)theSelectedMessages
{
	_selectedMessages = [NSArray arrayWithArray:theSelectedMessages];
	NSInteger selectedMessageCount = [theSelectedMessages count];
	
	// Toggle Archive bar button on/off based on number of selected Messages
	[self.barButtonArchive setEnabled:(selectedMessageCount > 0)];
	
	// Update navigation bar title based on number of Messages selected
	[self.navigationItem setTitle:(selectedMessageCount > 0 ? [NSString stringWithFormat:@"%ld Selected", (long)selectedMessageCount] : self.navigationBarTitle)];
}

// Override setEditing method
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	// Update Edit button title to Cancel (default is Done)
	if(editing)
	{
		[self.editButtonItem setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
	}
	// Reset navigation Bar Title
	else
	{
		[self.navigationItem setTitle:self.navigationBarTitle];
	}
	
	// Notify MessagesTableViewController of change in editing mode
	if([self.messagesTableViewController respondsToSelector:@selector(setEditing:animated:)])
	{
		[self.messagesTableViewController setEditing:editing animated:animated];
	}
	
	// Toggle Toolbar buttons
	[self toggleToolbarButtons:editing];
}

- (void)toggleToolbarButtons:(BOOL)editing
{
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	
	// If in editing mode, add the Archive and right flexible space buttons
	if(editing)
	{
		[self.barButtonArchive setEnabled:NO];
		
		[toolbarItems addObject:self.barButtonArchive];
		[toolbarItems addObject:self.barButtonRightFlexibleSpace];
	}
	
	[self.toolbarBottom setItems:toolbarItems animated:YES];
}

// Return Modify Multiple Message States pending from MessageModel delegate
- (void)modifyMultipleMessagesStatePending:(NSString *)state
{
	// Hide selected rows from Messages Table
	[self.messagesTableViewController hideSelectedMessages:self.selectedMessages];
	
	[self setEditing:NO animated:YES];
}

// Return Modify Multiple Message States success from MessageModel delegate
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state
{
	// Remove selected rows from Messages Table
	[self.messagesTableViewController removeSelectedMessages:self.selectedMessages];
}

// Return Modify Multiple Message States error from MessageModel delegate
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessages forState:(NSString *)state
{
	// Determine which Messages were successfully Archived
	NSMutableArray *successfulMessages = [NSMutableArray arrayWithArray:[self.selectedMessages copy]];
	
	[successfulMessages removeObjectsInArray:failedMessages];
	
	// Remove selected all rows from Messages Table that were successfully Archived
	if([self.selectedMessages count] > 0)
	{
		[self.messagesTableViewController removeSelectedMessages:successfulMessages];
	}
	
	// Reload Messages Table to re-show Messages that were not Archived
	[self.messagesTableViewController unHideSelectedMessages:failedMessages];
	
	// Update Selected Messages to only the Failed Messages
	self.selectedMessages = failedMessages;
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
	if(revealController.frontViewPosition == FrontViewPositionRight)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setBool:YES forKey:@"swipeMessageDisabled"];
		[settings synchronize];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded Table View Controller inside Container
	if([segue.identifier isEqualToString:@"embedSentMessagesTable"])
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
