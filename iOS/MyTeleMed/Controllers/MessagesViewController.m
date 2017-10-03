//
//  MessagesViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessagesViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"
#import "MessageModel.h"

/*
 * Temporary (Version 3.51) - Notification Tones had to be fixed in Version 3.51 to add the file extension to any tones that had been saved in Version 3.50.
 * This file and import can be removed in a future version (the file is not used anywhere else).
 */
#import "UIViewController+NotificationTonesFix.h"
/*
 * End Temporary (Version 3.51)
 */

@interface MessagesViewController ()

@property (weak, nonatomic) MessagesTableViewController *messagesTableViewController;

@property (nonatomic) MessageModel *messageModel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // (Must be strong reference)
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // (Must be strong reference)
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // (Must be strong reference)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTopSpace;

@property (nonatomic) NSArray *selectedMessages;
@property (nonatomic) NSString *navigationBarTitle;
@property (weak, nonatomic) UIColor *segmentedControlColor;

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store Navigation Bar Title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Note: programmatically set Right Bar Button Item to Apple's built-in Edit button is toggled from within MessagesTableViewController.m based on number of Filtered Messages
	
	/*
	 * Temporary (Version 3.51) - Notification Tones had to be fixed in Version 3.51 to add the file extension to any tones that had been saved in Version 3.50.
	 * This logic can be removed in a future version.
	 */
	[self verifyNotificationTones];
	/*
	 * End Temporary (Version 3.51)
	 */
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If Swipe Message has been disabled (Triggering a swipe to open the menu or refresh the table will disable it)
	if([settings boolForKey:@"swipeMessageDisabled"])
	{
		// Change top layout constraint to 11 (Keep Swipe Message there as it will simply be hidden under the Container View and we can still use the top border of it)
		self.constraintTopSpace.constant = 10.0 + (1.0 / [UIScreen mainScreen].scale);
	}
	
	[self toggleToolbarButtons:NO];
	
	[super viewWillAppear:animated];
}

// User clicked Archive Bar Button in Toolbar
- (IBAction)archiveMessages:(id)sender
{
	NSInteger selectedMessageCount = [self.selectedMessages count];
	NSInteger unreadMessageCount = 0;
	NSString *notificationMessage = [NSString stringWithFormat:@"Selecting Continue will archive %@. Archived messages can be accessed from the Main Menu.", (selectedMessageCount == 1 ? @"this message" : @"these messages")];
	
	// Ensure at least one selected Message (should never happen as Archive button should be disabled when no Messages selected)
	if(selectedMessageCount < 1)
	{
		return;
	}
	
	for(MessageModel *message in self.selectedMessages)
	{
		if([message.State isEqualToString:@"Unread"])
		{
			unreadMessageCount++;
		}
	}
	
	// Update notification message if all of these messages are Unread
	if(unreadMessageCount == selectedMessageCount)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %@ not been read yet. Selecting Continue will archive and close out %@ from our system.", (unreadMessageCount == 1 ? @"This message has" : @"These messages have"), (unreadMessageCount == 1 ? @"it" : @"them")];
	}
	// Update notification message if some of these messages are Unread
	else if(unreadMessageCount > 0)
	{
		notificationMessage = [NSString stringWithFormat:@"Warning: %ld of these messages %@ not been read yet. Selecting Continue will archive and close out %@ from our system.", (long)unreadMessageCount, (unreadMessageCount == 1 ? @"has" : @"have"), (unreadMessageCount == 1 ? @"it" : @"them")];
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Archive Messages" message:notificationMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
	
    [alertView show];
}

// User clicked one of the UISegmented Control options: (All, Stat, Priority, Normal)
- (IBAction)setPriorityFilter:(id)sender
{
	if([self.messagesTableViewController respondsToSelector:@selector(filterActiveMessages:)])
	{
		[self.messagesTableViewController filterActiveMessages:(int)[self.segmentedControl selectedSegmentIndex]];
	}
}

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

// Override default Remote Notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID
{
	// Execute the default Notification Message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID];
	
	// Reload Messages list to get the new Message only if the notification was for a Message
	if([notificationType isEqualToString:@"Message"])
	{
		NSLog(@"Received Remote Notification MessagesViewController");
		
		[self.messagesTableViewController reloadMessages];
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
	// If not in editing mode, add the Compose button
	else
	{
		[toolbarItems addObject:self.barButtonCompose];
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

/*/ Return Multiple Message States success from MessageModel delegate (no longer used)
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state
{
	// Remove selected rows from MessagesTableViewController
	[self.messagesTableViewController removeSelectedMessages:self.selectedMessages];
	
	[self setEditing:NO animated:YES];
}

// Return Multiple Message States error from MessageModel delegate (no longer used)
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessageIDs forState:(NSString *)state
{
	// Default to all Messages failed to send
	NSString *errorMessage = @"There was a problem archiving your Messages. Please try again.";
	
	// Only some Messages failed to send
	if([failedMessageIDs count] > 0 && [failedMessageIDs count] != [self.selectedMessages count])
	{
		errorMessage = @"There was a problem archiving some of your Messages. Please try again.";
		
		// Remove rows of successfully archived Messages in MessagesTableViewController
		NSMutableArray *messagesForRemoval = [[NSMutableArray alloc] initWithArray:[self.selectedMessages copy]];
		
		// If Message failed to archive, exclude it from Messages to be removed
		for(NSString *failedMessageID in failedMessageIDs)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", failedMessageID];
			NSArray *results = [messagesForRemoval filteredArrayUsingPredicate:predicate];
			
			if([results count] > 0)
			{
				MessageModel *message = [results objectAtIndex:0];
				
				[messagesForRemoval removeObject:message];
			}
		}
		
		[self.messagesTableViewController removeSelectedMessages:messagesForRemoval];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Archive Message Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}*/


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
	if([segue.identifier isEqualToString:@"embedActiveMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set Messages Type to Active
		[self.messagesTableViewController initMessagesWithType:0];
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
