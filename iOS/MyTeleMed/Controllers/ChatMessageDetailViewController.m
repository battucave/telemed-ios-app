//
//  ChatMessageDetailViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/5/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessageDetailViewController.h"
#import "ErrorAlertController.h"
#import "MessageRecipientPickerViewController.h"
#import "AutoGrowingTextView.h"
#import "CommentCell.h"
#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"
#import "MyProfileModel.h"
#import "NewChatMessageModel.h"

@interface ChatMessageDetailViewController ()

@property (nonatomic) ChatMessageModel *chatMessageModel;

@property (weak, nonatomic) IBOutlet AutoGrowingTextView *textViewChatParticipants;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddChatParticipant;
@property (weak, nonatomic) IBOutlet UITableView *tableChatMessages;
@property (weak, nonatomic) IBOutlet AutoGrowingTextView *textViewChatMessage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@property (nonatomic) NSString *navigationBarTitle;
@property (nonatomic) NSString *textViewChatMessagePlaceholder;

@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL isGroupChat;
@property (nonatomic) BOOL isParticipantsExpanded;

@property (nonatomic) NSUInteger chatMessageCount;
@property (nonatomic) NSNumber *currentUserID;
@property (nonatomic) NSMutableArray *chatMessages;
@property (nonatomic) NSMutableArray *selectedChatParticipants;

@end

@implementation ChatMessageDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Store navigation bar title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Set current user id
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	self.currentUserID = myProfileModel.ID;
	
	// Initialize selected chat participants
	[self setSelectedChatParticipants:[[NSMutableArray alloc] init]];
	
	// Initialize ChatMessageModel
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
	
	// Initialize text view chat participants
	[self.textViewChatParticipants setDelegate:self];
	[self.textViewChatParticipants setTextContainerInset:UIEdgeInsetsZero];
	
	// Initialize text view chat message input
	UIEdgeInsets textViewChatMessageEdgeInsets = self.textViewChatMessage.textContainerInset;
	
	[self.textViewChatMessage setDelegate:self];
	[self.textViewChatMessage setMaxHeight:206.5f]; // (118.5 = iPhone 5 view height - keyboard height - chat participants view height - 1px border)
	[self.textViewChatMessage setTextContainerInset:UIEdgeInsetsMake(textViewChatMessageEdgeInsets.top, 12.0f, textViewChatMessageEdgeInsets.bottom, 12.0f)];
	self.textViewChatMessagePlaceholder = self.textViewChatMessage.text;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Get chat messages for conversation id if its set (not a new chat)
	if (self.conversationID)
	{
		NSLog(@"Conversation ID: %@", self.conversationID);
		
		[self.chatMessageModel getChatMessagesByID:self.conversationID];
		
		// Existing chat messages are always a group chat
		self.isGroupChat = YES;
		
		// Hide Add chat participant button
		[self.buttonAddChatParticipant setHidden:YES];
	}
	// Update navigation bar title if this is a new chat
	else if (self.isNewChat)
	{
		[self.navigationItem setTitle:@"New Secure Chat"];
	}
	
	// Detect taps on text view chat participants to allow for toggling participants list AND scrolling the textview
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewChatParticipantsTapped:)];
	
	[self.textViewChatParticipants addGestureRecognizer:tapGestureRecognizer];
	
	// Set max height of text view chat participants to half of screen size minus max height of text view chat message minus height of navigation bar
	[self.textViewChatParticipants setMaxHeight:(([UIScreen mainScreen].bounds.size.height - 64.0f - self.textViewChatMessage.bounds.size.height) / 2.5)];
	
	// Add 10px to top and bottom of table chat messages
	[self.tableChatMessages setContentInset:UIEdgeInsetsMake(10, 0, 10, 0)];
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Add application did enter background observer to hide keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Add call disconnected observer to hide keyboard
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:@"UIApplicationDidDisconnectCall" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel queued chat messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Remove application did enter background observer to hide keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Remove call disconnected observer to hide keyboard
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidDisconnectCall" object:nil];
	
	// Dismiss keyboard
	[self.view endEditing:YES];
}

- (IBAction)sendChatMessage:(id)sender
{
	NewChatMessageModel *newChatMessageModel = [[NewChatMessageModel alloc] init];
	
	[newChatMessageModel setDelegate:self];
	[newChatMessageModel sendNewChatMessage:self.textViewChatMessage.text chatParticipantIDs:[self.selectedChatParticipants valueForKey:@"ID"] isGroupChat:self.isGroupChat withPendingID:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]]];
}

// Perform segue to MessageRecipientPickerViewController
- (IBAction)performSegueToMessageRecipientPicker:(id)sender
{
	// New chat message
	if (self.isNewChat)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromChatMessageDetail" sender:sender];
	}
	// If this is an existing chat message, then just show expanded list of participants
	else
	{
		[self toggleChatParticipantNames];
	}
}

// Unwind segue from MessageRecipientPickerViewController (new chat only)
- (IBAction)unwindSetChatParticipants:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected chat participants
	[self setSelectedChatParticipants:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Save group chat setting
	[self setIsGroupChat:messageRecipientPickerViewController.isGroupChat];
	
	// Update text view chat participants with chat participant name(s)
	[self setChatParticipantNames:self.selectedChatParticipants expanded:NO];
	
	// Reset chat messages table, conversation id, and is loaded flag
	[self resetChatMessages];
	
	// If only one chat participant or is a group chat, then check if an existing conversation already exists with the selected chat participants
	if (self.conversations && ([self.selectedChatParticipants count] == 1 || self.isGroupChat))
	{
		// Get array of id's from selected chat participants
		NSArray *selectedChatParticipantIDs = [self getSelectedChatParticipantIDs];
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
		
		// Check each conversation to determine if its chat participants are the same as the selected chat participants
		for(ChatMessageModel *chatMessage in self.conversations)
		{
			NSArray *chatParticipantIDs = [[chatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
			
			if ([chatParticipantIDs isEqualToArray:selectedChatParticipantIDs])
			{
				[self setConversationID:chatMessage.ID];
				
				// Cancel queued chat messages refresh
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				
				// Get chat messages for conversation id
				[self.chatMessageModel getChatMessagesByID:self.conversationID];
				
				// Reset is loaded flag to show loading message
				[self setIsLoaded:NO];
				
				// Update navigation bar title to reflect existing conversation
				[self.navigationItem setTitle:self.navigationBarTitle];
				
				break;
			}
		}
	}
	
	// Update chat messages table
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableChatMessages reloadData];
	});
	
	// Validate form
	[self validateForm:self.textViewChatMessage.text];
}

// Handle only taps on text view chat participants
- (void)textViewChatParticipantsTapped:(UITapGestureRecognizer *)recognizer
{
	// Perform Segue to MessageRecipientPickerViewController to duplicate its conditional functionality
	[self performSegueToMessageRecipientPicker:recognizer.view];
}

// Update text view chat participants with chat participant name(s)
- (void)setChatParticipantNames:(NSArray *)chatParticipants expanded:(BOOL)expanded
{
	// Remove self from chat participants
	if ([chatParticipants count] > 0)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID != %@", self.currentUserID];
		chatParticipants = [chatParticipants filteredArrayUsingPredicate:predicate];
	}
	
	NSString *chatParticipantNames = @"";
	NSInteger chatParticipantsCount = [chatParticipants count];
	
	// Format chat participant names
	if (chatParticipantsCount > 0)
	{
		// Only need to expand participants if more than one
		if (expanded && chatParticipantsCount > 1)
		{
			// Hide keyboard by removing focus from text view chat message
			[self.textViewChatMessage resignFirstResponder];
			
			// Extract formatted names into array
			NSArray *chatParticipantNamesArray = [chatParticipants valueForKey:@"FormattedNameLNF"];
			
			// Flatten array into string with line breaks
			chatParticipantNames = [chatParticipantNamesArray componentsJoinedByString:@"\n"];
			
			/*/ TESTING ONLY
			#ifdef DEBUG
				chatParticipantNames = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n", chatParticipantNames, chatParticipantNames, chatParticipantNames, chatParticipantNames, chatParticipantNames, chatParticipantNames];
			#endif
			//*/
		}
		else
		{
			ChatParticipantModel *chatParticipant1 = [chatParticipants objectAtIndex:0];
			ChatParticipantModel *chatParticipant2 = (chatParticipantsCount > 1 ? [chatParticipants objectAtIndex:1] : nil);
			
			switch (chatParticipantsCount)
			{
				case 1:
					chatParticipantNames = chatParticipant1.FormattedNameLNF;
					break;
				
				case 2:
					chatParticipantNames = [NSString stringWithFormat:@"%@ & %@", chatParticipant1.LastName, chatParticipant2.LastName];
					break;
				
				default:
					chatParticipantNames = [NSString stringWithFormat:@"%@, %@ & %ld more...", chatParticipant1.LastName, chatParticipant2.LastName, (long)chatParticipantsCount - 2];
					break;
			}
		}
	}
	
	// Fix bug on iOS < 10 that UITextView font size changes when setting button text if it is not selectable
	[self.textViewChatParticipants setSelectable:YES];
	
	// Update text view chat participants with chat participant name(s)
	[self.textViewChatParticipants setText:chatParticipantNames];
	
	// Flash scrollbar so user knows participants are scrollable
	if (expanded)
	{
		[self.textViewChatParticipants flashScrollIndicators];
	}
	// Prevent text selection unless text view chat participants is expanded
	else
	{
		[self.textViewChatParticipants setSelectable:NO];
	}
	
	// Toggle participants expanded flag
	self.isParticipantsExpanded = ! self.isParticipantsExpanded;
}

// Toggle expansion of chat participant names
- (void)toggleChatParticipantNames
{
	[self setChatParticipantNames:self.selectedChatParticipants expanded: ! self.isParticipantsExpanded];
}

// Get array of id's from selected chat participants
- (NSArray *)getSelectedChatParticipantIDs
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
	
	return [[[self.selectedChatParticipants valueForKey:@"ID"] arrayByAddingObject:self.currentUserID] sortedArrayUsingDescriptors:@[sortDescriptor]];
}

// Check required fields to determine if form can be submitted - Fired from setMessageRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.buttonSend setEnabled:(! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.textViewChatMessagePlaceholder] && self.selectedChatParticipants != nil && [self.selectedChatParticipants count] > 0)];
}

// Override default remote notification action from CoreViewController
- (void)handleRemoteNotification:(NSMutableDictionary *)notificationInfo ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction
{
	NSLog(@"Received Push Notification ChatMessageDetailViewController");
    
    // Reload chat messages if conversation id is set (not a new chat) and push notification is a chat message for *any* conversation (notification id is a newly generated value that won't exist yet in any current chat messages)
	if (self.conversationID && [notificationType isEqualToString:@"Chat"] && [notificationInfo objectForKey:@"notificationID"])
	{
		NSLog(@"Refresh Chat Messages with Conversation ID: %@", self.conversationID);
		
		__block UIAlertAction *viewActionBlock = viewAction;
		NSNumber *notificationID = [notificationInfo objectForKey:@"notificationID"];
		
		// Cancel queued chat messages refresh
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		// Reload chat messages for conversation id to determine if push notification is specifically for the current conversation
		[self.chatMessageModel getChatMessagesByID:self.conversationID withCallback:^(BOOL success, NSArray *chatMessages, NSError *error)
		{
			if (success)
			{
				// Execute the existing success delegate method
				[self updateChatMessages:chatMessages];
				
				// Determine if notification id exists in the updated chat messages
				NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", notificationID];
				NSArray *results = [chatMessages filteredArrayUsingPredicate:predicate];
				
				// Push notification is specifically for this conversation so remove the action view to prevent the user from opening a duplicate screen of the same chat messages
				if ([results count] > 0)
				{
					// Remove action view
					viewActionBlock = nil;
				}
			}
			else
			{
				// Execute the existing error delegate method
				[self updateChatMessagesError:error];
			}

			// Execute the default notification message action
			[super handleRemoteNotification:notificationInfo ofType:notificationType withViewAction:(UIAlertAction *)viewActionBlock];
		}];
		
		// Delay executing the default notification message action until chat messages have finished loading
		return;
	}
	
	// Execute the default notification message action
	[super handleRemoteNotification:notificationInfo ofType:notificationType withViewAction:(UIAlertAction *)viewAction];
}

// Reset chat messages back to loading state
- (void)resetChatMessages
{
	[self setIsLoaded:YES];
	[self setConversationID:nil];
	[self setChatMessages:[[NSMutableArray alloc] init]];
	
	[self.tableChatMessages reloadData];
}

// Return chat messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSArray *)chatMessages
{
	NSUInteger chatMessageCount = [chatMessages count];
	
	// Extract chat participants from first chat message
	if (chatMessageCount > 0)
	{
		ChatMessageModel *chatMessage = [chatMessages objectAtIndex:0];
		
		if ([chatMessage.ChatParticipants count] > 0)
		{
			// If a new chat, verify that chat participants still match selected chat participants in the event that user changed participants while chat messages were still loading
			if (self.isNewChat)
			{
				// Get array of id's from selected chat participants
				NSArray *selectedChatParticipantIDs = [self getSelectedChatParticipantIDs];
				
				NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
				
				// Check each conversation to determine if its chat participants are the same as the selected chat participants
				NSArray *chatParticipantIDs = [[chatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
				
				// If conversation's chat participants do not match selected chat participants, then don't update the chat messages
				if (! [chatParticipantIDs isEqualToArray:selectedChatParticipantIDs])
				{
					NSLog(@"Chat participants do not match selected chat participants");
					
					return;
				}
			}
			// If not a new chat, set chat participants
			else
			{
				[self setSelectedChatParticipants:[chatMessage.ChatParticipants mutableCopy]];
				
				// Update text view chat participants with chat participant name(s)
				[self setChatParticipantNames:chatMessage.ChatParticipants expanded:NO];
				
				// Reset participants expanded flag
				self.isParticipantsExpanded = NO;
			}
		}
	}
	
	// Keep current value of is loaded to determine whether to scroll to bottom of chat messages
	BOOL hadLoaded = self.isLoaded;
	
	[self setChatMessages:[chatMessages mutableCopy]];
	[self setIsLoaded:YES];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableChatMessages reloadData];
		
		// Scroll to bottom of chat messages after table reloads data only if this is the first load or a new chat message has been added since last check
		if (! hadLoaded || (self.chatMessageCount > 0 && chatMessageCount > self.chatMessageCount))
		{
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.5];
		}
		
		// Update chat message count with new number of chat messages
		self.chatMessageCount = chatMessageCount;
	});
	
	// Refresh chat messages again after 25 second delay
	[self.chatMessageModel performSelector:@selector(getChatMessagesByID:) withObject:self.conversationID afterDelay:25.0];
}

// Return error from ChatMessageModel delegate
- (void)updateChatMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Return pending from NewChatMessageModel delegate
- (void)sendChatMessagePending:(NSString *)message withPendingID:(NSNumber *)pendingID
{
	// Update navigation bar title to reflect existing conversation
	if (self.isNewChat)
	{
		[self.navigationItem setTitle:self.navigationBarTitle];
	}
	
	// Add chat message to chat messages array
	ChatMessageModel *chatMessage = [[ChatMessageModel alloc] init];
	NSDate *currentDate = [[NSDate alloc] init];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	// Set comment details
	[chatMessage setID:pendingID];
	[chatMessage setChatParticipants:self.selectedChatParticipants];
	[chatMessage setSenderID:self.currentUserID];
	[chatMessage setText:[message stringByRemovingPercentEncoding]];
	[chatMessage setUnopened:NO];
	
	// Create local date
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	[chatMessage setTimeSent_LCL:[dateFormatter stringFromDate:currentDate]];
	
	// Create UTC date
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
	[chatMessage setTimeSent_UTC:[dateFormatter stringFromDate:currentDate]];
	
	[self.chatMessages addObject:chatMessage];
	
	// Begin actual update
	[self.tableChatMessages beginUpdates];
	
	// If adding first comment/event
	if ([self.chatMessages count] == 1)
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
		
		// Add first row to table
		if ([self.tableChatMessages numberOfRowsInSection:0] == 0)
		{
			[self.tableChatMessages insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		// Replace loading message with chat message
		else
		{
			[self.tableChatMessages reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		
	}
	// If adding to already existing chat messages
	else
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.chatMessages count] - 1 inSection:0]];
		
		[self.tableChatMessages insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	
	// Commit row updates
	[self.tableChatMessages endUpdates];
	
	// Auto size table chat messages height to show all rows
	// [self autoSizeTableChatMessages];
	
	// Clear and resign focus from text view comment
	[self.textViewChatMessage setText:@""];
	[self.textViewChatMessage resignFirstResponder];
	[self.buttonSend setEnabled:NO];
	
	// Trigger a scroll to bottom to ensure the newly added comment is shown
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

// Return error from NewChatMessageModel delegate
- (void)sendChatMessageError:(NSError *)error withPendingID:(NSNumber *)pendingID
{
	// Find comment with pending id in filtered message events
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", pendingID];
	NSArray *results = [self.chatMessages filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find and delete table cell that contains the chat message
		ChatMessageModel *chatMessage = [results objectAtIndex:0];
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
		
		// Remove chat message from chat messages
		[self.chatMessages removeObject:chatMessage];
		
		// If removing the only chat message
		if ([self.chatMessages count] == 0)
		{
			[self.tableChatMessages reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		// If removing from existing chat messages
		else
		{
			[self.tableChatMessages deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
	}
}

// Scroll to bottom of table chat messages
- (void)scrollToBottom
{
	if ([self.chatMessages count] > 1)
	{
		NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:[self.chatMessages count] - 1 inSection:0];
		
		[self.tableChatMessages scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
}

/*/ Auto size table chat messages height to show all rows
- (void)autoSizeTableChatMessages
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		CGSize newSize = [self.tableChatMessages sizeThatFits:CGSizeMake(self.tableChatMessages.frame.size.width, MAXFLOAT)];
		
		self.constraintTableChatMessagesHeight.constant = newSize.height;
	});
}*/

- (void)dismissKeyboard:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.textViewChatMessage resignFirstResponder];
	});
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
	NSDictionary *keyboardInfo = [notification userInfo];
	UIViewAnimationCurve animationCurve;
	NSTimeInterval animationDuration;
	CGRect keyboardRect;
	
	[[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	keyboardRect = [self.view convertRect:[[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
	
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationCurve:animationCurve];
	[UIView setAnimationDuration:animationDuration];
	
	CGRect newFrame = self.view.frame;
	newFrame.size.height = keyboardRect.origin.y;
	
	self.view.frame = newFrame;
	
	[UIView commitAnimations];
	
	// Scroll to bottom of chat messages after frame resizes
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Collapse text view chat participants
	if (self.isParticipantsExpanded)
	{
		[self setChatParticipantNames:self.selectedChatParticipants expanded:NO];
	}
	
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewChatMessagePlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:16.0]];
	}
	
	[textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if ([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewChatMessagePlaceholder];
		[textView setTextColor:[UIColor colorWithRed:98.0/255.0 green:98.0/255.0 blue:98.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
	}
	
	[textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Scroll scroll view content to bottom
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.0];
	
	[self validateForm:textView.text];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If loading chat messages, but there are no chat messages, show a message
	if (self.conversationID && [self.chatMessages count] == 0)
	{
		return 1;
	}
	
	return [self.chatMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no chat messages available
	if ([self.chatMessages count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// If loading chat messages, but there are no chat messages, show a message
		if (self.conversationID)
		{
			[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
			[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
			[emptyCell.textLabel setText:(self.isLoaded ? @"No chat messages available." : @"Loading...")];
		}
		
		// Auto size table chat messages height to show all rows
		//[self autoSizeTableChatMessages];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageDetailCell";
	static NSString *cellIdentifierSent = @"SentChatMessageDetailCell";
	
	// Set up the cell
	ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
	
	BOOL currentUserIsSender = ([chatMessage.SenderID isEqualToNumber:self.currentUserID]);
	//BOOL currentUserIsSender = !! (indexPath.row % 2); // Only used for testing both cell types
	
	// Set both types of events to use comment cell (purposely reusing comment cell here instead of creating duplicate chat message detail cell)
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:(currentUserIsSender ? cellIdentifierSent : cellIdentifier)];

	// Set message event date and time
	if (chatMessage.TimeSent_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:chatMessage.TimeSent_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if (dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:chatMessage.TimeSent_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy h:mm a"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
	}
	
	// Set message event detail
	[cell.labelDetail setText:chatMessage.Text];
	
	// Set message event sender
	if (! currentUserIsSender)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", chatMessage.SenderID];
		NSArray *results = [chatMessage.ChatParticipants filteredArrayUsingPredicate:predicate];
		
		if ([results count] > 0)
		{
			ChatParticipantModel *chatParticipant = [results objectAtIndex:0];
			
			[cell.labelEnteredBy setText:chatParticipant.FormattedName];
		}
	}
	
	// Auto size table chat messages height to show all rows
	//[self autoSizeTableChatMessages];
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromChatMessageDetail"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set message recipient type
		[messageRecipientPickerViewController setMessageRecipientType:@"Chat"];
		[messageRecipientPickerViewController setTitle:@"Choose Participants"];
		
		// Set selected message recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedChatParticipants mutableCopy]];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
