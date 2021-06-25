//
//  MessagesViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

#import "MessagesViewController.h"
#import "ErrorAlertController.h"
#import "MessageDetailViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"
#import "MessageModel.h"
#import "RegisteredDeviceModel.h"

@interface MessagesViewController ()

@property (weak, nonatomic) MessagesTableViewController *messagesTableViewController;

@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRegisterDevice; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // Must be a strong reference
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) NSString *navigationBarTitle;
@property (weak, nonatomic) UIColor *segmentedControlColor;
@property (nonatomic) NSArray *selectedMessages;

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Note: programmatically setting the right bar button item to Apple's built-in edit button is toggled from within MessagesTableViewController.m based on number of filtered messages
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	// Hide swipe message if it has been disabled (triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:SWIPE_MESSAGE_DISABLED])
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
	
	for (MessageModel *message in self.selectedMessages)
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

	[archiveMessagesAlertController addAction:continueAction];
	[archiveMessagesAlertController addAction:cancelAction];

	// Set preferred action
	[archiveMessagesAlertController setPreferredAction:continueAction];

	// Show alert
	[self presentViewController:archiveMessagesAlertController animated:YES completion:nil];
}

- (IBAction)registerDevice:(id)sender
{
	// Run CoreViewController's authorizeForRemoteNotifications:
	[self authorizeForRemoteNotifications];
}

// Unwind segue from MessageDetailViewController (only after archive action)
- (IBAction)unwindArchiveMessage:(UIStoryboardSegue *)segue
{
	MessageDetailViewController *messageDetailViewController = segue.sourceViewController;
	
	if ([self.messagesTableViewController respondsToSelector:@selector(removeSelectedMessages:)])
	{
		[self.messagesTableViewController removeSelectedMessages:@[messageDetailViewController.message]];
	}
}

// Override setEditing:
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

// Override CoreViewController's didChangeRemoteNotificationAuthorization:
- (void)didChangeRemoteNotificationAuthorization:(BOOL)isEnabled
{
	NSLog(@"Remote notification authorization did change: %@", (isEnabled ? @"Enabled" : @"Disabled"));
	
	[self toggleToolbarButtons:super.isEditing];
}

// Return modify multiple message states error from MessageModel delegate
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessages forState:(NSString *)state
{
	// Reset selected messages
	self.selectedMessages = [NSArray new];
	
	// Reset messages
	if ([self.messagesTableViewController respondsToSelector:@selector(resetMessages:)])
	{
		[self.messagesTableViewController resetMessages:YES];
	
		// Reload messages
		if ([self.messagesTableViewController respondsToSelector:@selector(reloadMessages)])
		{
			[self.messagesTableViewController reloadMessages];
		}
	}
}

// Return modify multiple message states pending from MessageModel delegate
- (void)modifyMultipleMessagesStatePending:(NSString *)state
{
    /*
	 * 9/29/2019 - Pagination was added, but contains a flaw:
	 *   If user archives message(s), then loads the next page of messages, some messages will be skipped. Example scenario:
	 *     1. User loads the first page of messages with 25 items
	 *     2. User archives one or more messages
	 *     3. User scrolls down and loads the next page of messages
	 *     4. The next page will start from the 26th message, thereby skipping over some number of messages equal to the number of messages that were archived
	 *
	 *   The recommended solution is to update the Messages web service endpoint to include a parameter that defines the next item to be fetched. Example scenario:
	 *     1. User loads the first page of messages with 25 items
	 *     2. User archives one or more messages
	 *     3. User scrolls down and loads the next set of messages
	 *     4. App simply requests the next 25 items starting from the next message needed, which is: initial messages count - archived messages count + 1, or just current messages count + 1
	 *
	 *   This recommended solution was not accepted.
	 *
	 *   Instead, reload the current page of messages to backfill any that would be skipped. If user archived more than one page of messages (25), then reset the table since reloading the current page would still skip messages.
	 */
	// Remove selected rows from messages table
	if ([self.messagesTableViewController respondsToSelector:@selector(removeSelectedMessages:)])
	{
		[self.messagesTableViewController removeSelectedMessages:self.selectedMessages];
	}
	
	[self setEditing:NO animated:YES];
}

// Return modify multiple message states success from MessageModel delegate
- (void)modifyMultipleMessagesStateSuccess
{
	// Empty
}

// Delegate method from SWRevealController that fires when a recognized gesture has ended
- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController
{
	[self performSelector:@selector(SWRevealControllerDidMoveToPosition:) withObject:revealController afterDelay:0.25];
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

// Determine if SWRevealController has opened. This method is only fired after a delay from revealControllerPanGestureEnded Delegate method so we can determine if gesture resulted in opening the SWRevealController
- (void)SWRevealControllerDidMoveToPosition:(SWRevealViewController *)revealController
{
	// If position is open
	if (revealController.frontViewPosition == FrontViewPositionRight)
	{
		NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
		
		[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
		[settings synchronize];
	}
}

- (void)toggleToolbarButtons:(BOOL)editing
{
	RegisteredDeviceModel *registeredDevice = RegisteredDeviceModel.sharedInstance;
	
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	
	// If in editing mode, add the archive and right flexible space buttons
	if (editing)
	{
		[self.barButtonArchive setEnabled:NO];
		
		[toolbarItems addObject:self.barButtonArchive];
		[toolbarItems addObject:self.barButtonRightFlexibleSpace];
	}
	// If device is not registered with TeleMed, then add register app button
	else if (! [registeredDevice isRegistered])
	{
		[toolbarItems addObject:self.barButtonRegisterDevice];
	}
	// Add compose message button
	else
	{
		[toolbarItems addObject:self.barButtonCompose];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.toolbarBottom setItems:toolbarItems animated:YES];
	});
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded table view controller inside container
	if ([segue.identifier isEqualToString:@"embedActiveMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set messages type to active
		[self.messagesTableViewController setMessagesType:@"Active"];
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
