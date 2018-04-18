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
	
	// Store Navigation Bar Title
	[self setNavigationBarTitle:self.navigationItem.title];
	
	// Set Current User ID
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	self.currentUserID = myProfileModel.ID;
	
	// Initialize Selected Chat Participants
	[self setSelectedChatParticipants:[[NSMutableArray alloc] init]];
	
	// Initialize Chat Message Model
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
	
	// Initialize Text View Chat Participants
	[self.textViewChatParticipants setDelegate:self];
	[self.textViewChatParticipants setTextContainerInset:UIEdgeInsetsZero];
	
	// Initialize Text View Chat Message Input
	UIEdgeInsets textViewChatMessageEdgeInsets = self.textViewChatMessage.textContainerInset;
	
	[self.textViewChatMessage setDelegate:self];
	[self.textViewChatMessage setMaxHeight:118.5f]; // (118.5 = iPhone 4s View height - Keyboard height - Chat Participants View height - 1px border)
	[self.textViewChatMessage setTextContainerInset:UIEdgeInsetsMake(textViewChatMessageEdgeInsets.top, 12.0f, textViewChatMessageEdgeInsets.bottom, 12.0f)];
	self.textViewChatMessagePlaceholder = self.textViewChatMessage.text;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Get Chat Messages for Conversation ID if its set (not a new Chat)
	if (self.conversationID)
	{
		NSLog(@"Conversation ID: %@", self.conversationID);
		
		[self.chatMessageModel getChatMessagesByID:self.conversationID];
		
		// Existing Chat Messages are always a Group Chat
		self.isGroupChat = YES;
		
		// Hide Add Chat Participant button
		[self.buttonAddChatParticipant setHidden:YES];
	}
	// Update navigation bar title if this is a new Chat
	else if (self.isNewChat)
	{
		[self.navigationItem setTitle:@"New Secure Chat"];
	}
	
	// Detect taps on Text View Chat Participants to allow for toggling Participants list AND scrolling the textview
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewChatParticipantsTapped:)];
	
	[self.textViewChatParticipants addGestureRecognizer:tapGestureRecognizer];
	
	// Set max height of Text View Chat Participants to half of screen size minus max height of Text View Chat Message minus height of navigation bar
	[self.textViewChatParticipants setMaxHeight:(([UIScreen mainScreen].bounds.size.height - 64.0f - self.textViewChatMessage.bounds.size.height) / 2.5)];
	
	// Add 10px to top and bottom of Table Comments
	[self.tableChatMessages setContentInset:UIEdgeInsetsMake(10, 0, 10, 0)];
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Add Application Did Enter Background Observer to Hide Keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Add Call Disconnected Observer to Hide Keyboard
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:@"UIApplicationDidDisconnectCall" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel queued Chat Messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self.chatMessageModel];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Remove Application Did Enter Background Observer to Hide Keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Remove Call Disconnected Observer to Hide Keyboard
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidDisconnectCall" object:nil];
	
	// Dismiss Keyboard
	[self.view endEditing:YES];
}

- (IBAction)sendChatMessage:(id)sender
{
	NewChatMessageModel *newChatMessageModel = [[NewChatMessageModel alloc] init];
	
	[newChatMessageModel setDelegate:self];
	[newChatMessageModel sendNewChatMessage:self.textViewChatMessage.text chatParticipantIDs:[self.selectedChatParticipants valueForKey:@"ID"] isGroupChat:self.isGroupChat withPendingID:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]]];
}

// Perform Segue to MessageRecipientPickerTableViewController
- (IBAction)performSegueToMessageRecipientPicker:(id)sender
{
	// New Chat Message screen
	if (self.isNewChat)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromChatMessageDetail" sender:sender];
	}
	// If Chat Detail screen then just show expanded list of Participants
	else
	{
		[self toggleChatParticipantNames];
	}
}

// Unwind Segue from MessageRecipientPickerViewController (New Chat only)
- (IBAction)setChatParticipants:(UIStoryboardSegue *)segue
{
	// Obtain reference to Source View Controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected Chat Participants
	[self setSelectedChatParticipants:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Save Group Chat setting
	[self setIsGroupChat:messageRecipientPickerViewController.isGroupChat];
	
	NSLog(@"Is Group Chat: %@", (self.isGroupChat ? @"Yes" : @"No"));
	
	// Update Text View Chat Participants with Chat Participant Name(s)
	[self setChatParticipantNames:self.selectedChatParticipants expanded:NO];
	
	// Reset Chat Messages Table, Conversation ID, and Is Loaded flag
	[self resetChatMessages];
	
	// If only one Chat Participant or is a Group Chat, then check if an existing Conversation already exists with the selected Chat Participants
	if (self.conversations && ([self.selectedChatParticipants count] == 1 || self.isGroupChat))
	{
		// Get array of ID's from Selected Chat Participants
		NSArray *selectedChatParticipantIDs = [self getSelectedChatParticipantIDs];
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
		
		// Check each Conversation to determine if its Chat Participants are the same as the selected Chat Participants
		for(ChatMessageModel *chatMessage in self.conversations)
		{
			NSArray *chatParticipantIDs = [[chatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
			
			if ([chatParticipantIDs isEqualToArray:selectedChatParticipantIDs])
			{
				[self setConversationID:chatMessage.ID];
				
				// Cancel queued Chat Messages refresh
				[NSObject cancelPreviousPerformRequestsWithTarget:self.chatMessageModel];
				
				// Get Chat Messages for Conversation ID
				[self.chatMessageModel getChatMessagesByID:self.conversationID];
				
				// Reset Is Loaded flag to show loading message
				[self setIsLoaded:NO];
				
				// Update navigation bar title to reflect existing Conversation
				[self.navigationItem setTitle:self.navigationBarTitle];
				
				break;
			}
		}
	}
	
	// Update Chat Messages table
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableChatMessages reloadData];
	});
	
	// Validate form
	[self validateForm:self.textViewChatMessage.text];
}

// Handle only taps on Text View Chat Participants
- (void)textViewChatParticipantsTapped:(UITapGestureRecognizer *)recognizer
{
	// Perform Segue to Message Recipient Picker to duplicate its conditional functionality
	[self performSegueToMessageRecipientPicker:recognizer.view];
}

// Update Text View Chat Participants with Chat Participant Name(s)
- (void)setChatParticipantNames:(NSArray *)chatParticipants expanded:(BOOL)expanded
{
	// Remove self from Chat Participants
	if ([chatParticipants count] > 0)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID != %@", self.currentUserID];
		chatParticipants = [chatParticipants filteredArrayUsingPredicate:predicate];
	}
	
	NSString *chatParticipantNames = @"";
	NSInteger chatParticipantsCount = [chatParticipants count];
	
	// Format Chat Participant Names
	if (chatParticipantsCount > 0)
	{
		// Only need to expand Participants if more than one
		if (expanded && chatParticipantsCount > 1)
		{
			// Hide keyboard by removing focus from Text View Chat Message
			[self.textViewChatMessage resignFirstResponder];
			
			// Extract Formatted Names into array
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
	
	// Update Text View Chat Participants with Chat Participant Name(s)
	[self.textViewChatParticipants setText:chatParticipantNames];
	
	// Flash scrollbar so user knows Participants are scrollable
	if (expanded)
	{
		[self.textViewChatParticipants flashScrollIndicators];
	}
	// Prevent text selection unless Text View Chat Participants is expanded
	else
	{
		[self.textViewChatParticipants setSelectable:NO];
	}
	
	// Toggle Participants Expanded flag
	self.isParticipantsExpanded = ! self.isParticipantsExpanded;
}

// Toggle expansion of Chat Participant Names
- (void)toggleChatParticipantNames
{
	[self setChatParticipantNames:self.selectedChatParticipants expanded: ! self.isParticipantsExpanded];
}

// Get array of ID's from Selected Chat Participants
- (NSArray *)getSelectedChatParticipantIDs
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
	
	return [[[self.selectedChatParticipants valueForKey:@"ID"] arrayByAddingObject:self.currentUserID] sortedArrayUsingDescriptors:@[sortDescriptor]];
}

// Check required fields to determine if Form can be submitted - Fired from setMessageRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.buttonSend setEnabled:( ! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.textViewChatMessagePlaceholder] && self.selectedChatParticipants != nil && [self.selectedChatParticipants count] > 0)];
}

// Override default Remote Notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID withTone:(NSString *)tone
{
	NSLog(@"Received Remote Notification ChatMessageDetailViewController");
    
    // Reload Chat Messages if remote notification is a Chat Message (there is no way to verify that the message is specifically for the current conversation because the deliveryID will be a newly generated value that won't match conversationID)
	if ([notificationType isEqualToString:@"Chat"]/* && deliveryID && self.conversationID && [deliveryID isEqualToNumber:self.conversationID]*/)
	{
		NSLog(@"Refresh Chat Messages with Conversation ID: %@", self.conversationID);
		
		// Cancel queued Chat Messages refresh
		[NSObject cancelPreviousPerformRequestsWithTarget:self.chatMessageModel];
		
		[self.chatMessageModel getChatMessagesByID:self.conversationID];
	}
	
	// If remote notification is NOT a Chat Message specifically for the current Conversation, execute the default notification message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID withTone:tone];
}

// Reset Chat Messages back to Loading state
- (void)resetChatMessages
{
	[self setIsLoaded:YES];
	[self setConversationID:nil];
	[self setChatMessages:[[NSMutableArray alloc] init]];
	
	[self.tableChatMessages reloadData];
}

// Return Chat Messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSMutableArray *)chatMessages
{
	NSUInteger chatMessageCount = [chatMessages count];
	
	// Extract Chat Participants from first Chat Message
	if (chatMessageCount > 0)
	{
		ChatMessageModel *chatMessage = [chatMessages objectAtIndex:0];
		
		if ([chatMessage.ChatParticipants count] > 0)
		{
			// If a new Chat, verify that Chat Participants still match Selected Chat Participants in the event that user changed Participants while Chat Messages were still loading
			if (self.isNewChat)
			{
				// Get array of ID's from Selected Chat Participants
				NSArray *selectedChatParticipantIDs = [self getSelectedChatParticipantIDs];
				
				NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
				
				// Check each Conversation to determine if its Chat Participants are the same as the selected Chat Participants
				NSArray *chatParticipantIDs = [[chatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
				
				// If Conversation's Chat Participants do not match Selected Chat Participants, then don't update the Chat Messages
				if ( ! [chatParticipantIDs isEqualToArray:selectedChatParticipantIDs])
				{
					NSLog(@"Chat Participants do not match Selected Chat Participants");
					
					return;
				}
			}
			// If not a new Chat, set Chat Participants
			else
			{
				[self setSelectedChatParticipants:[chatMessage.ChatParticipants mutableCopy]];
				
				// Update Text View Chat Participants with Chat Participant Name(s)
				[self setChatParticipantNames:chatMessage.ChatParticipants expanded:NO];
				
				// Reset Participants Expanded flag
				self.isParticipantsExpanded = NO;
			}
		}
	}
	
	[self setIsLoaded:YES];
	[self setChatMessages:chatMessages];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableChatMessages reloadData];
		
		// Scroll to bottom of Chat Messages after table reloads data only if a new Chat Message has been added since last check
		if (self.chatMessageCount > 0 && chatMessageCount > self.chatMessageCount)
		{
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
		}
		
		// Update Chat Message count with new number of Chat Messages
		self.chatMessageCount = chatMessageCount;
	});
	
	// Refresh Chat Messages again after 15 second delay
	[self.chatMessageModel performSelector:@selector(getChatMessagesByID:) withObject:self.conversationID afterDelay:15.0];
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
	// Update navigation bar title to reflect existing Conversation
	if (self.isNewChat)
	{
		[self.navigationItem setTitle:self.navigationBarTitle];
	}
	
	// Add Chat Message to Chat Messages Array
	ChatMessageModel *chatMessage = [[ChatMessageModel alloc] init];
	NSDate *currentDate = [[NSDate alloc] init];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	// Set Comment details
	[chatMessage setID:pendingID];
	[chatMessage setChatParticipants:self.selectedChatParticipants];
	[chatMessage setSenderID:self.currentUserID];
	[chatMessage setText:(NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)message, CFSTR(""), kCFStringEncodingUTF8))];
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
	
	// If adding first Comment/Event
	if ([self.chatMessages count] == 1)
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
		
		// Add first row to table
		if ([self.tableChatMessages numberOfRowsInSection:0] == 0)
		{
			[self.tableChatMessages insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		// Replace loading message with Chat Message
		else
		{
			[self.tableChatMessages reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		
	}
	// If adding to already existing Chat Messages
	else
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.chatMessages count] - 1 inSection:0]];
		
		[self.tableChatMessages insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	
	// Commit row updates
	[self.tableChatMessages endUpdates];
	
	// Auto size Table Comments height to show all rows
	//[self autoSizeTableChatMessages];
	
	// Clear and resign focus from Text View Comment
	[self.textViewChatMessage setText:@""];
	[self.textViewChatMessage resignFirstResponder];
	[self.buttonSend setEnabled:NO];
	
	// Trigger a scroll to bottom to ensure the newly added Comment is shown
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

// Return error from NewChatMessageModel delegate
- (void)sendChatMessageError:(NSError *)error withPendingID:(NSNumber *)pendingID
{
	// Find Comment with Pending ID in Filtered Message Events
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", pendingID];
	NSArray *results = [self.chatMessages filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find and delete table cell that contains the Chat Message
		ChatMessageModel *chatMessage = [results objectAtIndex:0];
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
		
		// Remove Chat Message from Chat Messages
		[self.chatMessages removeObject:chatMessage];
		
		// If removing the only Chat Message
		if ([self.chatMessages count] == 0)
		{
			[self.tableChatMessages reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		// If removing from existing Chat Messages
		else
		{
			[self.tableChatMessages deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
	}
}

// Scroll to bottom of Table Comments
- (void)scrollToBottom
{
	if ([self.chatMessages count] > 1)
	{
		NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:[self.chatMessages count] - 1 inSection:0];
		
		[self.tableChatMessages scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
}

/*/ Auto size Table Chat Messages height to show all rows
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
	
	// Scroll to bottom of Chat Messages after frame resizes
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Collapse Text View Chat Participants
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
	// Scroll Scroll View content to bottom
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.0];
	
	[self validateForm:textView.text];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If loading Chat Messages, but there are no Chat Messages, show a message
	if (self.conversationID && [self.chatMessages count] == 0)
	{
		return 1;
	}
	
	return [self.chatMessages count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 74.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no Chat Messages available
	if ([self.chatMessages count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no Chat Messages available
	if ([self.chatMessages count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// If loading Chat Messages, but there are no Chat Messages, show a message
		if (self.conversationID)
		{
			[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
			[emptyCell.textLabel setText:(self.isLoaded ? @"No comments have been added yet." : @"Loading...")];
		}
		
		// Auto size Table Chat Messages height to show all rows
		//[self autoSizeTableChatMessages];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageDetailCell";
	static NSString *cellIdentifierSent = @"SentChatMessageDetailCell";
	
	// Set up the cell
	ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
	
	BOOL currentUserIsSender = ([chatMessage.SenderID isEqualToNumber:self.currentUserID]);
	//BOOL currentUserIsSender = !! (indexPath.row % 2); // Only used for testing both cell types
	
	// Set both types of events to use CommentCell (purposely reusing CommentCell here instead of creating duplicate ChatMessageDetailCell)
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:(currentUserIsSender ? cellIdentifierSent : cellIdentifier)];

	// Set Message Event Date and Time
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
	
	// Set Message Event Detail
	[cell.labelDetail setText:chatMessage.Text];
	
	// Set Message Event Sender
	if ( ! currentUserIsSender)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", chatMessage.SenderID];
		NSArray *results = [chatMessage.ChatParticipants filteredArrayUsingPredicate:predicate];
		
		if ([results count] > 0)
		{
			ChatParticipantModel *chatParticipant = [results objectAtIndex:0];
			
			[cell.labelEnteredBy setText:chatParticipant.FormattedName];
		}
	}
	
	// Auto size Table Chat Messages height to show all rows
	//[self autoSizeTableChatMessages];
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromChatMessageDetail"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Message Recipient Type
		[messageRecipientPickerViewController setMessageRecipientType:@"Chat"];
		
		// Set selected Message Recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedChatParticipants mutableCopy]];
	}
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
