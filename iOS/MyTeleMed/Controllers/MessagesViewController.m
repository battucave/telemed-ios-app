//
//  MessagesViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessagesViewController.h"
#import "MessageDetailViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"
#import "MessageModel.h"

@interface MessagesViewController ()

@property (weak, nonatomic) MessagesTableViewController *messagesTableViewController;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // Must be a strong reference
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) NSArray *selectedMessages;
@property (nonatomic) NSString *navigationBarTitle;
@property (weak, nonatomic) UIColor *segmentedControlColor;

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Note: programmatically set right bar button item to Apple's built-in edit button is toggled from within MessagesTableViewController.m based on number of filtered messages
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Hide swipe message if it has been disabled (triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:@"swipeMessageDisabled"])
	{
		[self.viewSwipeMessage setHidden:YES];
	}
	
	[self toggleToolbarButtons:NO];
	
	[super viewWillAppear:animated];
}

// User clicked archive bar button in toolbar
- (IBAction)archiveMessages:(id)sender
{
	NSInteger selectedMessageCount = [self.selectedMessages count];
	NSInteger unreadMessageCount = 0;
	NSString *notificationMessage = [NSString stringWithFormat:@"Selecting Continue will archive %@. Archived messages can be accessed from the Main Menu.", (selectedMessageCount == 1 ? @"this message" : @"these messages")];
	
	// Ensure at least one selected message (should never happen as archive button should be disabled when no messages selected)
	if (selectedMessageCount < 1)
	{
		return;
	}
	
	for(MessageModel *message in self.selectedMessages)
	{
		if ([message.State isEqualToString:@"Unread"])
		{
			unreadMessageCount++;
		}
	}
	
	// Update notification message if all of these messages are unread
	if (unreadMessageCount == selectedMessageCount)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %@ not been read yet. Selecting Continue will archive and close out %@ from our system.", (unreadMessageCount == 1 ? @"This message has" : @"These messages have"), (unreadMessageCount == 1 ? @"it" : @"them")];
	}
	// Update notification message if some of these messages are unread
	else if (unreadMessageCount > 0)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %ld of these messages %@ not been read yet. Selecting Continue will archive and close out %@ from our system.", (long)unreadMessageCount, (unreadMessageCount == 1 ? @"has" : @"have"), (unreadMessageCount == 1 ? @"it" : @"them")];
	}
	
	UIAlertController *archiveMessagesAlertController = [UIAlertController alertControllerWithTitle:@"Archive Messages" message:notificationMessage preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		MessageModel *messageModel = [[MessageModel alloc] init];
		[messageModel setDelegate:self];
		
		[messageModel modifyMultipleMessagesState:self.selectedMessages state:@"Archive"];
	}];

	[archiveMessagesAlertController addAction:cancelAction];
	[archiveMessagesAlertController addAction:continueAction];

	// PreferredAction only supported in 9.0+
	if ([archiveMessagesAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[archiveMessagesAlertController setPreferredAction:continueAction];
	}

	// Show alert
	[self presentViewController:archiveMessagesAlertController animated:YES completion:nil];
}

// Unwind segue from MessageDetailViewController (only after archive action)
- (IBAction)unwindArchiveMessage:(UIStoryboardSegue *)segue
{
	MessageDetailViewController *messageDetailViewController = segue.sourceViewController;
	
	// Remove selected rows from messages table
	[self.messagesTableViewController removeSelectedMessages:@[messageDetailViewController.message]];
}

// Override selectedMessages setter
- (void)setSelectedMessages:(NSArray *)theSelectedMessages
{
	_selectedMessages = [NSArray arrayWithArray:theSelectedMessages];
	NSInteger selectedMessageCount = [theSelectedMessages count];
	
	// Toggle archive bar button on/off based on number of selected messages
	[self.barButtonArchive setEnabled:(selectedMessageCount > 0)];
	
	// Update navigation bar title based on number of messages selected
	[self.navigationItem setTitle:(selectedMessageCount > 0 ? [NSString stringWithFormat:@"%ld Selected", (long)selectedMessageCount] : self.navigationBarTitle)];
}

// Override setEditing method
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	// Update edit button title to cancel (default is Done)
	if (editing)
	{
		[self.editButtonItem setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
	}
	// Reset navigation bar title
	else
	{
		[self.navigationItem setTitle:self.navigationBarTitle];
	}
	
	// Notify MessagesTableViewController of change in editing mode
	if ([self.messagesTableViewController respondsToSelector:@selector(setEditing:animated:)])
	{
		[self.messagesTableViewController setEditing:editing animated:animated];
	}
	
	// Toggle toolbar buttons
	[self toggleToolbarButtons:editing];
}

- (void)toggleToolbarButtons:(BOOL)editing
{
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	
	// If in editing mode, add the archive and right flexible space buttons
	if (editing)
	{
		[self.barButtonArchive setEnabled:NO];
		
		[toolbarItems addObject:self.barButtonArchive];
		[toolbarItems addObject:self.barButtonRightFlexibleSpace];
	}
	// If not in editing mode, add the compose button
	else
	{
		[toolbarItems addObject:self.barButtonCompose];
	}
	
	[self.toolbarBottom setItems:toolbarItems animated:YES];
}

// Return modify multiple message states pending from MessageModel delegate
- (void)modifyMultipleMessagesStatePending:(NSString *)state
{
	// Hide selected rows from messages table
	[self.messagesTableViewController hideSelectedMessages:self.selectedMessages];
	
	[self setEditing:NO animated:YES];
}

// Return modify multiple message states success from MessageModel delegate
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state
{
	// Remove selected rows from messages table
	[self.messagesTableViewController removeSelectedMessages:self.selectedMessages];
}

// Return modify multiple message states error from MessageModel delegate
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessages forState:(NSString *)state
{
	// Determine which messages were successfully archived
	NSMutableArray *successfulMessages = [self.selectedMessages mutableCopy];
	
	[successfulMessages removeObjectsInArray:failedMessages];
	
	// Remove selected all rows from messages table that were successfully archived
	if ([self.selectedMessages count] > 0)
	{
		[self.messagesTableViewController removeSelectedMessages:successfulMessages];
	}
	
	// Reload messages table to re-show messages that were not archived
	[self.messagesTableViewController unHideSelectedMessages:failedMessages];
	
	// Update selected messages to only the failed messages
	self.selectedMessages = failedMessages;
}

// Delegate method from SWRevealController that fires when a recognized gesture has ended
- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController
{
	[self performSelector:@selector(SWRevealControllerDidMoveToPosition:) withObject:revealController afterDelay:0.25];
}

// Determine if SWRevealController has opened. This method is only fired after a delay from revealControllerPanGestureEnded Delegate method so we can determine if gesture resulted in opening the SWRevealController
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
	// Embedded table view controller inside container
	if ([segue.identifier isEqualToString:@"embedActiveMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set messages type to active
		[self.messagesTableViewController initMessagesWithType:@"Active"];
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
