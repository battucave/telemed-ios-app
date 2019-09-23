//
//  ChatMessagesViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 6/28/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessagesViewController.h"
#import "ChatMessagesTableViewController.h"
#import "ChatMessageDetailViewController.h"
#import "SWRevealViewController.h"
#import "ChatMessageModel.h"

@interface ChatMessagesViewController ()

@property (weak, nonatomic) ChatMessagesTableViewController *chatMessagesTableViewController;

@property (nonatomic) ChatMessageModel *chatMessageModel;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonDelete; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // Must be a strong reference
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) NSArray *selectedChatMessages;
@property (nonatomic) NSString *navigationBarTitle;

@end

@implementation ChatMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Note: programmatically set right bar button item to Apple's built-in edit button is toggled from within ChatMessagesTableViewController.m based on number of chat messages
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Hide swipe message if it has been disabled (triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:SWIPE_MESSAGE_DISABLED])
	{
		[self.viewSwipeMessage setHidden:YES];
	}
	
	[self toggleToolbarButtons:NO];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel queued chat messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

// User clicked delete bar button in toolbar
- (IBAction)deleteMessages:(id)sender
{
	NSInteger selectedChatMessageCount = [self.selectedChatMessages count];
	NSInteger unreadChatMessageCount = 0;
	NSString *notificationMessage = [NSString stringWithFormat:@"Selecting Continue will delete %@.", (selectedChatMessageCount == 1 ? @"this secure chat message" : @"these secure chat messages")];
	
	// Ensure at least one selected chat message (should never happen as delete button should be disabled when no chat messages selected)
	if (selectedChatMessageCount < 1)
	{
		return;
	}
	
	for (ChatMessageModel *chatMessage in self.selectedChatMessages)
	{
		if (chatMessage.Unopened)
		{
			unreadChatMessageCount++;
		}
	}
	
	// Update notification message if all of these messages are unread
	if (unreadChatMessageCount == selectedChatMessageCount)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %@ not been read yet. Selecting Continue will delete %@ from our system.", (unreadChatMessageCount == 1 ? @"This secure chat message has" : @"These secure chat messages have"), (unreadChatMessageCount == 1 ? @"it" : @"them")];
	}
	// Update notification message if some of these messages are unread
	else if (unreadChatMessageCount > 0)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %ld of these secure chat messages %@ not been read yet. Selecting Continue will delete %@ from our system.", (long)unreadChatMessageCount, (unreadChatMessageCount == 1 ? @"has" : @"have"), (unreadChatMessageCount == 1 ? @"it" : @"them")];
	}
	
	UIAlertController *deleteChatMessagesAlertController = [UIAlertController alertControllerWithTitle:@"Delete Chat Messages" message:notificationMessage preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Added this because a minority of users were complaining that chat sometimes causes crash
		if (self.chatMessageModel == nil)
		{
			[self setChatMessageModel:[[ChatMessageModel alloc] init]];
			[self.chatMessageModel setDelegate:self];
		}
		
		[self.chatMessageModel deleteMultipleChatMessages:self.selectedChatMessages];
	}];

	[deleteChatMessagesAlertController addAction:continueAction];
	[deleteChatMessagesAlertController addAction:cancelAction];

	// Set preferred action
	[deleteChatMessagesAlertController setPreferredAction:continueAction];

	// Show alert
	[self presentViewController:deleteChatMessagesAlertController animated:YES completion:nil];
}

// Override selectedChatMessages setter
- (void)setSelectedChatMessages:(NSArray *)selectedChatMessages
{
	_selectedChatMessages = [NSArray arrayWithArray:selectedChatMessages];
	NSInteger selectedChatMessageCount = [selectedChatMessages count];
	
	// Toggle delete bar button on/off based on number of selected chat messages
	[self.barButtonDelete setEnabled:(selectedChatMessageCount > 0)];
	
	// Update navigation bar title based on number of chat messages selected
	[self.navigationItem setTitle:(selectedChatMessageCount > 0 ? [NSString stringWithFormat:@"%ld Selected", (long)selectedChatMessageCount] : self.navigationBarTitle)];
}

// Override setEditing:
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	// Update Edit button title to cancel (default is done)
	if (editing)
	{
		[self.editButtonItem setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
	}
	// Reset navigation bar title
	else
	{
		[self.navigationItem setTitle:self.navigationBarTitle];
	}
	
	// Notify ChatMessagesTableViewController of change in editing mode
	if ([self.chatMessagesTableViewController respondsToSelector:@selector(setEditing:animated:)])
	{
		[self.chatMessagesTableViewController setEditing:editing animated:animated];
	}
	
	// Toggle toolbar buttons
	[self toggleToolbarButtons:editing];
}

// Return delete multiple chat message pending from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesPending
{
	// Hide selected rows from chat messages table
	[self.chatMessagesTableViewController hideSelectedChatMessages:self.selectedChatMessages];
	
	[self setEditing:NO animated:YES];
}

// Return delete multiple chat message success from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesSuccess
{
	// Remove selected rows from chat messages table
	[self.chatMessagesTableViewController removeSelectedChatMessages:self.selectedChatMessages];
}

// Return delete multiple chat message error from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesError:(NSArray *)failedChatMessages
{
	// Determine which chat messages were successfully delete4d
	NSMutableArray *successfulChatMessages = [self.selectedChatMessages mutableCopy];
	
	[successfulChatMessages removeObjectsInArray:failedChatMessages];
	
	// Remove selected all rows from chat messages table that were successfully archived
	if ([self.selectedChatMessages count] > 0)
	{
		[self.chatMessagesTableViewController removeSelectedChatMessages:successfulChatMessages];
	}
	
	// Reload chat messages table to re-show chat messages that were not deleted
	[self.chatMessagesTableViewController unhideSelectedChatMessages:failedChatMessages];
	
	// Update selected chat messages to only the failed chat messages
	self.selectedChatMessages = failedChatMessages;
}

// Delegate method from SWRevealController that fires when a recognized gesture has ended
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
		
		[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
		[settings synchronize];
	}
}

- (void)toggleToolbarButtons:(BOOL)editing
{
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	
	// If in editing mode, add the delete and right flexible space buttons
	if (editing)
	{
		[self.barButtonDelete setEnabled:NO];
		
		[toolbarItems addObject:self.barButtonDelete];
		[toolbarItems addObject:self.barButtonRightFlexibleSpace];
	}
	// If not in editing mode, add the compose button
	else
	{
		[toolbarItems addObject:self.barButtonCompose];
	}
	
	[self.toolbarBottom setItems:toolbarItems animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded table view controller inside container
	if ([segue.identifier isEqualToString:@"embedChatMessagesTable"])
	{
		[self setChatMessagesTableViewController:segue.destinationViewController];
		
		// Set chat messages
		[self.chatMessagesTableViewController setDelegate:self];
		
		// In XCode 8+, all view frame sizes are initially 1000x1000. Have to call "layoutIfNeeded" first to get actual value.
		[self.toolbarBottom layoutIfNeeded];
		
		// Increase bottom inset of chat messages table so that its bottom scroll position rests above bottom toolbar
		UIEdgeInsets tableInset = self.chatMessagesTableViewController.tableView.contentInset;
		CGSize toolbarSize = self.toolbarBottom.frame.size;
		
		tableInset.bottom = toolbarSize.height;
		[self.chatMessagesTableViewController.tableView setContentInset:tableInset];
	}
	// Set conversations for chat message detail to use for determining whether a message with selected chat participants already exists
	else if ([segue.identifier isEqualToString:@"showChatMessageNew"])
	{
		ChatMessageDetailViewController *chatMessageDetailViewController = segue.destinationViewController;
		
		[chatMessageDetailViewController setIsNewChat:YES];
		[chatMessageDetailViewController setConversations:self.chatMessagesTableViewController.chatMessages];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
