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

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonArchive; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonCompose; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRegisterDevice; // Must be a strong reference
@property (nonatomic) IBOutlet UIBarButtonItem *barButtonRightFlexibleSpace; // Must be a strong reference
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) NSString *navigationBarTitle;
@property (nonatomic) RegisteredDeviceModel *registeredDevice;
@property (weak, nonatomic) UIColor *segmentedControlColor;
@property (nonatomic) NSArray *selectedMessages;

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	[self setRegisteredDevice:[RegisteredDeviceModel sharedInstance]];
	
	// Add application will enter foreground observer to register for remote notifications when user returns from Settings app
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// If device is not registered with TeleMed (rarely the case), then add observers to detect if/when the user successfully registers using the register app button
	if (! [self.registeredDevice isRegistered])
	{
		// Add remote notification registration observers to detect if user has registered for remote notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotifications:) name:@"UIApplicationDidRegisterForRemoteNotifications" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToRegisterForRemoteNotifications:) name:@"UIApplicationDidFailToRegisterForRemoteNotifications" object:nil];
	}
	
	// Note: programmatically setting the right bar button item to Apple's built-in edit button is toggled from within MessagesTableViewController.m based on number of filtered messages
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
	// If device is already registered with TeleMed, then prompt user to enable push notifications
	if ([self.registeredDevice isRegistered])
	{
		[self showNotificationAuthorization];
	}
	// If device is not registered with TeleMed, then prompt user to confirm their phone number
	else
	{
		[self showPhoneNumberAlert];
	}
}

// Unwind segue from MessageDetailViewController (only after archive action)
- (IBAction)unwindArchiveMessage:(UIStoryboardSegue *)segue
{
	MessageDetailViewController *messageDetailViewController = segue.sourceViewController;
	
	// Remove selected rows from messages table
	[self.messagesTableViewController removeSelectedMessages:@[messageDetailViewController.message]];
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

- (void)didFailToRegisterForRemoteNotifications:(NSNotification *)notification
{
	NSLog(@"Did Fail To Register for Remote Notifications Extras: %@", notification.userInfo);
	
	NSString *errorMessage = @"There was a problem registering your device.";
	
	if ([notification.userInfo objectForKey:@"error"])
	{
		NSError *originalError = ((NSError *)[notification.userInfo objectForKey:@"error"]);
		
		errorMessage = [originalError.localizedDescription stringByAppendingString:@" Please ensure that the phone number already exists in your account."];
	}
	
	NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Device Registration Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	});
}

- (void)didRegisterForRemoteNotifications:(NSNotification *)notification
{
	NSLog(@"Did Register for Remote Notifications Extras: %@", notification.userInfo);
	
	UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
	
	[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			// If user has already enabled push notifications, then toggle toolbar buttons
			if (settings.authorizationStatus == UNAuthorizationStatusAuthorized)
			{
				[self toggleToolbarButtons:super.isEditing];
			}
			// If user has not enabled push notifications, then prompt user to enable them
			else
			{
				[self showNotificationAuthorization];
			}
		});
	}];
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

- (void)showNotificationAuthorization
{
	UIAlertController *allowNotificationsAlertController = [UIAlertController alertControllerWithTitle:@"Register Device" message:@"Your device is not registered for notifications. To enable them:\n\n1) Press the Settings button\n2) Tap Notifications\n3) Set 'Allow Notifications' to On" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Open settings app for user to enable notifications
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
	}];

	[allowNotificationsAlertController addAction:settingsAction];
	[allowNotificationsAlertController addAction:cancelAction];

	// PreferredAction only supported in 9.0+
	if ([allowNotificationsAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[allowNotificationsAlertController setPreferredAction:settingsAction];
	}

	// Show alert
	[self presentViewController:allowNotificationsAlertController animated:YES completion:nil];
}

- (void)showPhoneNumberAlert
{
	UIAlertController *registerDeviceAlertController = [UIAlertController alertControllerWithTitle:@"Register Device" message:@"Please enter the phone number for this device. Your TeleMed profile will be updated." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		NSString *phoneNumber = [[registerDeviceAlertController textFields][0] text];
		
		// Validate phone number
		if (phoneNumber.length < 9 || phoneNumber.length > 18 || [phoneNumber isEqualToString:@"0000000000"] || [phoneNumber isEqualToString:@"000-000-0000"])
		{
			UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter a valid Phone Number." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				// Re-show phone number dialog
				[self showPhoneNumberAlert];
			}];
		
			[errorAlertController addAction:okAction];
		
			// Set preferred action
			[errorAlertController setPreferredAction:okAction];
		
			// Show alert
			[self presentViewController:errorAlertController animated:YES completion:nil];
		}
		// Register device for remote notifications
		else
		{
			[self.registeredDevice setPhoneNumber:phoneNumber];
			
			// (Re-)Register device for push notifications
			[[UIApplication sharedApplication] registerForRemoteNotifications];
		}
	}];

	[registerDeviceAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		[textField setTextContentType:UITextContentTypeTelephoneNumber];
		[textField setKeyboardType:UIKeyboardTypePhonePad];
		[textField setPlaceholder:@"Phone Number"];
		[textField setText:self.registeredDevice.PhoneNumber];
	}];
	[registerDeviceAlertController addAction:continueAction];
	[registerDeviceAlertController addAction:cancelAction];

	// PreferredAction only supported in 9.0+
	if ([registerDeviceAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[registerDeviceAlertController setPreferredAction:continueAction];
	}

	// Show alert
	[self presentViewController:registerDeviceAlertController animated:YES completion:nil];
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

- (void)toggleToolbarButtons:(BOOL)editing
{
	// Initialize toolbar items with only the left flexible space button
	NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:[self.toolbarBottom.items objectAtIndex:0], nil];
	UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];

	[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
	{
		// If in editing mode, add the archive and right flexible space buttons
		if (editing)
		{
			[self.barButtonArchive setEnabled:NO];
			
			[toolbarItems addObject:self.barButtonArchive];
			[toolbarItems addObject:self.barButtonRightFlexibleSpace];
		}
		// If device is not registered with TeleMed or push notifications are not enabled, then add register app button
		else if (! [self.registeredDevice isRegistered] || settings.authorizationStatus != UNAuthorizationStatusAuthorized)
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
	}];
}

// Event for when app returns to foreground (specifically when app returns from Settings app)
- (void)viewDidBecomeActive:(NSNotification *)notification
{
	// If device is already registered with TeleMed, then toggle toolbar buttons in case the user enabled notifications
	if ([self.registeredDevice isRegistered])
	{
		[self toggleToolbarButtons:super.isEditing];
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

-(void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
