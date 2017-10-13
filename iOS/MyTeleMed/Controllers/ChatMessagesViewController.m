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
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonDelete; // (Must be strong reference)
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // (Must be strong reference)
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // (Must be strong reference)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTopSpace;

@property (nonatomic) NSArray *selectedChatMessages;
@property (nonatomic) NSString *navigationBarTitle;

@end

@implementation ChatMessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store Navigation Bar Title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Note: programmatically set Right Bar Button Item to Apple's built-in Edit button is toggled from within ChatMessagesTableViewController.m based on number of Chat Messages
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

// User clicked Delete Bar Button in Toolbar
- (IBAction)deleteMessages:(id)sender
{
	NSInteger selectedChatMessageCount = [self.selectedChatMessages count];
	NSInteger unreadChatMessageCount = 0;
	NSString *notificationMessage = [NSString stringWithFormat:@"Selecting Continue will delete %@.", (selectedChatMessageCount == 1 ? @"this secure chat message" : @"these secure chat messages")];
	
	// Ensure at least one selected Chat Message (should never happen as Delete button should be disabled when no Messages selected)
	if(selectedChatMessageCount < 1)
	{
		return;
	}
	
	for(ChatMessageModel *chatMessage in self.selectedChatMessages)
	{
		if(chatMessage.Unopened)
		{
			unreadChatMessageCount++;
		}
	}
	
	// Update notification message if all of these Messages are Unread
	if(unreadChatMessageCount == selectedChatMessageCount)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %@ not been read yet. Selecting Continue will delete %@ from our system.", (unreadChatMessageCount == 1 ? @"This secure chat message has" : @"These secure chat messages have"), (unreadChatMessageCount == 1 ? @"it" : @"them")];
	}
	// Update notification message if some of these messages are Unread
	else if(unreadChatMessageCount > 0)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %ld of these secure chat messages %@ not been read yet. Selecting Continue will delete %@ from our system.", (long)unreadChatMessageCount, (unreadChatMessageCount == 1 ? @"has" : @"have"), (unreadChatMessageCount == 1 ? @"it" : @"them")];
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Chat Messages" message:notificationMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
	
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex > 0)
	{
		// Added this because a minority of users were complaining that Chat sometimes causes crash
		if(self.chatMessageModel == nil)
		{
			[self setChatMessageModel:[[ChatMessageModel alloc] init]];
			[self.chatMessageModel setDelegate:self];
		}
		
		[self.chatMessageModel deleteMultipleChatMessages:self.selectedChatMessages];
	}
}

// Override default Remote Notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID withTone:(NSString *)tone
{
	// Execute the default Notification Message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID withTone:tone];
	
	// Reload Chat Messages list to get the new Chat Message only if the notification was for a Chat Message
	if([notificationType isEqualToString:@"Chat Message"])
	{
		NSLog(@"Received Remote Notification ChatMessagesViewController");
		
		[self.chatMessagesTableViewController reloadChatMessages];
	}
}

// Override selectedChatMessages setter
- (void)setSelectedChatMessages:(NSArray *)selectedChatMessages
{
	_selectedChatMessages = [NSArray arrayWithArray:selectedChatMessages];
	NSInteger selectedChatMessageCount = [selectedChatMessages count];
	
	// Toggle Delete bar button on/off based on number of selected Chat Messages
	[self.barButtonDelete setEnabled:(selectedChatMessageCount > 0)];
	
	// Update navigation bar title based on number of Chat Messages selected
	[self.navigationItem setTitle:(selectedChatMessageCount > 0 ? [NSString stringWithFormat:@"%ld Selected", (long)selectedChatMessageCount] : self.navigationBarTitle)];
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
	
	// Notify ChatMessagesTableViewController of change in editing mode
	if([self.chatMessagesTableViewController respondsToSelector:@selector(setEditing:animated:)])
	{
		[self.chatMessagesTableViewController setEditing:editing animated:animated];
	}
	
	// Toggle Toolbar buttons
	[self toggleToolbarButtons:editing];
}

- (void)toggleToolbarButtons:(BOOL)editing
{
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	
	// If in editing mode, add the Delete and right flexible space buttons
	if(editing)
	{
		[self.barButtonDelete setEnabled:NO];
		
		[toolbarItems addObject:self.barButtonDelete];
		[toolbarItems addObject:self.barButtonRightFlexibleSpace];
	}
	// If not in editing mode, add the Compose button
	else
	{
		[toolbarItems addObject:self.barButtonCompose];
	}
	
	[self.toolbarBottom setItems:toolbarItems animated:YES];
}

// Return Delete Multiple Chat Message pending from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesPending
{
	// Hide selected rows from Chat Messages Table
	[self.chatMessagesTableViewController hideSelectedChatMessages:self.selectedChatMessages];
	
	[self setEditing:NO animated:YES];
}

// Return Delete Multiple Chat Message success from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesSuccess
{
	// Remove selected rows from Chat Messages Table
	[self.chatMessagesTableViewController removeSelectedChatMessages:self.selectedChatMessages];
}

// Return Delete Multiple Chat Message error from ChatMessageModel delegate
- (void)deleteMultipleChatMessagesError:(NSArray *)failedChatMessages
{
	// Determine which Chat Messages were successfully Archived
	NSMutableArray *successfulChatMessages = [NSMutableArray arrayWithArray:[self.selectedChatMessages copy]];
	
	[successfulChatMessages removeObjectsInArray:failedChatMessages];
	
	// Remove selected all rows from Chat Messages Table that were successfully Archived
	if([self.selectedChatMessages count] > 0)
	{
		[self.chatMessagesTableViewController removeSelectedChatMessages:successfulChatMessages];
	}
	
	// Reload Chat Messages Table to re-show Chat Messages that were not Archived
	[self.chatMessagesTableViewController unHideSelectedChatMessages:failedChatMessages];
	
	// Update Selected Messages to only the Failed Chat Messages
	self.selectedChatMessages = failedChatMessages;
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
	if([segue.identifier isEqualToString:@"embedChatMessagesTable"])
	{
		[self setChatMessagesTableViewController:segue.destinationViewController];
		
		// Set Chat Messages
		[self.chatMessagesTableViewController setDelegate:self];
		
		// In XCode 8+, all view frame sizes are initially 1000x1000. Have to call "layoutIfNeeded" first to get actual value.
		[self.toolbarBottom layoutIfNeeded];
		
		// Increase bottom inset of Messages Table so that its bottom scroll position rests above bottom Toolbar
		UIEdgeInsets tableInset = self.chatMessagesTableViewController.tableView.contentInset;
		CGSize toolbarSize = self.toolbarBottom.frame.size;
		
		tableInset.bottom = toolbarSize.height;
		[self.chatMessagesTableViewController.tableView setContentInset:tableInset];
	}
	// Set Conversations for Chat Message Detail to use for determining whether a message with selected Chat Participants already exists
	else if([segue.identifier isEqualToString:@"showNewChatMessageDetail"])
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
