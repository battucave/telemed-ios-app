//
//  MessageDetailViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageDetailViewController.h"
#import "ErrorAlertController.h"
#import "AutoGrowingTextView.h"
#import "ProfileProtocol.h"
#import <QuartzCore/QuartzCore.h>

#ifdef MYTELEMED
	#import "MessageHistoryViewController.h"
	#import "CommentCell.h" // Med2Med Phase 2
	#import "MessageEventCell.h" // Med2Med Phase 2
	#import "CommentModel.h" // Med2Med Phase 2
	#import "MessageEventModel.h" // Med2Med Phase 2
	#import "MessageRecipientModel.h"
	#import "MyProfileModel.h"
#endif

#ifdef MED2MED
	#import "UserProfileModel.h"
#endif

@interface MessageDetailViewController ()

#ifdef MYTELEMED
	@property (nonatomic) CommentModel *commentModel;
	@property (nonatomic) MessageEventModel *messageEventModel;
	@property (nonatomic) MessageRecipientModel *messageRecipientModel;
#endif

@property (weak, nonatomic) IBOutlet UIButton *buttonPhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;
@property (weak, nonatomic) IBOutlet UILabel *labelAccountName;
@property (weak, nonatomic) IBOutlet UILabel *labelAccountPublicKey;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tableComments;
@property (weak, nonatomic) IBOutlet AutoGrowingTextView *textViewComment;
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;
@property (weak, nonatomic) IBOutlet UIView *viewAccount;
@property (weak, nonatomic) IBOutlet UIView *viewButtons;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTableCommentsHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintViewButtonsHeight;

// TEMPORARY MED2MED PHASE 1 (remove in phase 2)
@property (weak, nonatomic) IBOutlet UILabel *labelCommentsEvents;
@property (weak, nonatomic) IBOutlet UIView *viewAddCommentContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonAddCommentHeight;
// END TEMPORARY MED2MED PHASE 1

@property (nonatomic) NSUInteger messageCount;
@property (nonatomic) NSNumber *currentUserID;
@property (nonatomic) NSString *textViewCommentPlaceholder;

@property (nonatomic) BOOL isLoaded;

@end

@implementation MessageDetailViewController

- (void)viewDidLoad
{
	// Perform shared logic in MessageDetailParentViewController
	[super viewDidLoad];
	
	// Set current user id
	id <ProfileProtocol> profile;
	self.currentUserID = 0;
	
	#ifdef MYTELEMED
	 	profile = [MyProfileModel sharedInstance];
	
	#elif defined MED2MED
			profile = [UserProfileModel sharedInstance];
	#endif
	
	if (profile)
	{
		self.currentUserID = profile.ID;
	}
	
	#ifdef MYTELEMED
		// Initialize basic event model
		[self setMessageEventModel:[[MessageEventModel alloc] init]];
		[self.messageEventModel setDelegate:self];
	
		// Initialize message recipient model
		[self setMessageRecipientModel:[[MessageRecipientModel alloc] init]];
		[self.messageRecipientModel setDelegate:self];
	
		// Initialize text view comment
		UIEdgeInsets textViewCommentEdgeInsets = self.textViewComment.textContainerInset;
	
		[self.textViewComment setDelegate:self];
		[self.textViewComment setTextContainerInset:UIEdgeInsetsMake(textViewCommentEdgeInsets.top, 12.0f, textViewCommentEdgeInsets.bottom, 12.0f)];
		[self.textViewComment setMaxHeight:120.0f];
		self.textViewCommentPlaceholder = self.textViewComment.text;
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSLog(@"Message ID: %@", self.message.MessageID);
	
	if ([self.message respondsToSelector:@selector(MessageDeliveryID)])
	{
		NSLog(@"Message Delivery ID: %@", self.message.MessageDeliveryID);
	}
	
	// Set sent message details
	if (self.message.messageType == 2)
	{
		[self setSentMessageDetails];
		
		// Change title in navigation bar
		[self.navigationItem setTitle:@"Sent Message Detail"];
	}
	
	#ifdef MYTELEMED
		// Set active or archived message details
		else
		{
			[self setMessageDetails];
		}
	#endif
	
	// Set account details (if any)
	[self setAccountDetails];
	
	#ifdef MYTELEMED
		// Load message events
		[self.messageEventModel getMessageEventsForMessageID:self.message.MessageID];
	
		// Load forward message recipients to determine if message is forwardable
		[self.messageRecipientModel getMessageRecipientsForMessageID:self.message.MessageID];
	
		// Add keyboard observers
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	
		// Add application did enter background observer to hide keyboard (otherwise it will be hidden when app returns to foreground)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
		// Add call disconnected observer to hide keyboard
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:@"UIApplicationDidDisconnectCall" object:nil];
	
		// Mark message as read if active and unread
		if ([self.message respondsToSelector:@selector(MessageDeliveryID)] && self.message.MessageDeliveryID && [self.message respondsToSelector:@selector(State)] && self.message.State)
		{
			if (self.message.messageType == 0 && [self.message.State isEqualToString:@"Unread"])
			{
				[self.messageModel modifyMessageState:self.message.MessageDeliveryID state:@"Read"];
				
				/*/ TESTING ONLY (set message back to unread)
				#ifdef DEBUG
					[self.messageModel modifyMessageState:self.message.MessageDeliveryID state:@"Unread"];
				#endif
				// END TESTING ONLY */
			}
			/*/ TESTING ONLY (unarchive archived messages)
			else if (self.message.messageType == 1)
			{
				#ifdef DEBUG
					[self.messageModel modifyMessageState:self.message.MessageDeliveryID state:@"Unarchive"];
				#endif
			}
			// END TESTING ONLY */
		}
	#endif
	
	// Med2Med - modify appearance
	#ifdef MED2MED
		// Hide buttons
		[self.viewButtons setHidden:YES];
		[self.constraintViewButtonsHeight setConstant:0.0f];
	#endif
}

- (void)setAccountDetails
{
	// Set account name and number
	if (self.message.Account)
	{
		[self.labelAccountName setText:self.message.Account.Name];
		[self.labelAccountPublicKey setText:self.message.Account.PublicKey];
	}
	// Hide account information if not available
	else
	{
		[self.viewAccount setHidden:YES];
		
		// Deactivate existing constraints on account view
		[NSLayoutConstraint deactivateConstraints:self.viewAccount.constraints];
		
		// Add new 0 height constraint to account view
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.viewAccount attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0]];
	}
}

- (void)setSentMessageDetails
{
	// Set recipient names, phone number, and message
	[self.buttonPhoneNumber setTitle:@"" forState:UIControlStateNormal];
	[self.labelName setText:[self.message.Recipients stringByReplacingOccurrencesOfString:@";" withString:@"; "]];
	[self.textViewMessage setText:self.message.FormattedMessageText];
	
	// Disable phone number
	[self.buttonPhoneNumber setEnabled:NO];
	
	// Set message date and time
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	NSDate *dateTime = [dateFormatter dateFromString:self.message.FirstSent_LCL];
	
	// If date is nil, it may have been formatted incorrectly
	if (dateTime == nil)
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		dateTime = [dateFormatter dateFromString:self.message.FirstSent_LCL];
	}
	
	[dateFormatter setDateFormat:@"M/dd/yy"];
	NSString *date = [dateFormatter stringFromDate:dateTime];
	
	[dateFormatter setDateFormat:@"h:mm a"];
	NSString *time = [dateFormatter stringFromDate:dateTime];
	
	[self.labelDate setText:date];
	[self.labelTime setText:time];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([self.filteredMessageEvents count] == 0)
	{
		return 1;
	}
	
	return [self.filteredMessageEvents count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 62.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no comments available
	if ([self.filteredMessageEvents count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
}

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop refreshing message events when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self.messageEventModel];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Remove application did enter background observer to hide keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Remove call disconnected observer to hide keyboard
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidDisconnectCall" object:nil];
	
	// Dismiss keyboard
	[self.view endEditing:YES];
}

- (IBAction)sendComment:(id)sender
{
	[self setCommentModel:[[CommentModel alloc] init]];
	[self.commentModel setDelegate:self];
	
	// Send Comment with a pending id so that it can be identified in callbacks
	[self.commentModel addMessageComment:self.message comment:self.textViewComment.text withPendingID:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]]];
}

// Override default remote notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID withTone:(NSString *)tone
{
	NSLog(@"Received Remote Notification MessageDetailViewController");
	
	/*/ TESTING ONLY (test custom handling of push notification comment to a particular message)
	#ifdef DEBUG
		message = @"Shane Goodwin added a comment to a message.";
		type = @"comment";
		deliveryId = 5133538688695397;
	#endif
	//*/
	
	// Reload message events if remote notification is a comment specifically for the current message
	if ([notificationType isEqualToString:@"Comment"] && deliveryID)
	{
		// Received messages
		if ([self.message respondsToSelector:@selector(MessageDeliveryID)] && [deliveryID isEqualToNumber:self.message.MessageDeliveryID])
		{
			NSLog(@"Refresh Comments with Message Delivery ID: %@", deliveryID);
			
			// Cancel queued comments refresh
			[NSObject cancelPreviousPerformRequestsWithTarget:self.messageEventModel];
			
			[self.messageEventModel getMessageEventsForMessageDeliveryID:self.message.MessageDeliveryID];
		}
		// Sent messages
		else if (self.message.MessageID && [deliveryID isEqualToNumber:self.message.MessageID])
		{
			NSLog(@"Refresh Comments with Message ID: %@", deliveryID);
			
			// Cancel queued comments refresh
			[NSObject cancelPreviousPerformRequestsWithTarget:self.messageEventModel];
			
			[self.messageEventModel getMessageEventsForMessageID:self.message.MessageID];
		}
	}
	
	// If remote notification is NOT a comment specifically for the current message, execute the default notification message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID withTone:tone];
}

// Return events from MessageEventModel delegate
- (void)updateMessageEvents:(NSMutableArray *)newMessageEvents
{
	[self setIsLoaded:YES];
	[self setMessageEvents:newMessageEvents];
	
	[self.filteredMessageEvents removeAllObjects];
	
	// Add only comments from basic events
	for(MessageEventModel *messageEvent in newMessageEvents)
	{
		if ([messageEvent.Type isEqualToString:@"Comment"] || [messageEvent.Type isEqualToString:@"User"])
		{
			[self.filteredMessageEvents addObject:messageEvent];
		}
	}
	
	/*/ TESTING ONLY (used for generating screenshots)
	#ifdef DEBUG
		[self.filteredMessageEvents removeAllObjects];
	 
		for(int i = 0; i < 3; i++)
		{
			MessageEventModel *messageEvent = [[MessageEventModel alloc] init];
			NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	 
			[messageEvent setValue:@"Comment" forKey:@"Type"];
	 
			// Test message from Jason
			if (i == 0)
			{
				[messageEvent setValue:@"Jason Hutchison" forKey:@"EnteredBy"];
				[messageEvent setValue:@"2015-04-11T13:24:06.444" forKey:@"Time_LCL"];
				[messageEvent setValue:@"Introducing the new TeleMed comments section" forKey:@"Detail"];
			}
			// Test message from me (ensure entered by id matches own logged in id)
			else if (i == 1)
			{
				[messageEvent setValue:[numberFormatter numberFromString:@"14140220"] forKey:@"EnteredByID"];
				[messageEvent setValue:@"2015-04-11T15:46:06.444" forKey:@"Time_LCL"];
				[messageEvent setValue:@"Tap on the message field at the bottom of the screen to send messages back and forth." forKey:@"Detail"];
			}
			// Test message from Jason
			else if (i == 2)
			{
				[messageEvent setValue:@"Jason Hutchison" forKey:@"EnteredBy"];
				[messageEvent setValue:@"2015-04-12T10:58:39.444" forKey:@"Time_LCL"];
				[messageEvent setValue:@"Events are now found by tapping the History button located above." forKey:@"Detail"];
			}
	 
			[self.filteredMessageEvents addObject:messageEvent];
		}
	#endif
	// END TESTING ONLY */
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableComments reloadData];
		
		// Scroll to bottom of comments after table reloads data only if a new comment has been added since last check
		if (self.messageCount > 0 && [self.filteredMessageEvents count] > self.messageCount)
		{
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
		}
		
		// Update message count with new number of filtered message events
		self.messageCount = [self.filteredMessageEvents count];
	});
	
	// Refresh message events again after 15 second delay
	[self.messageEventModel performSelector:@selector(getMessageEventsForMessageID:) withObject:self.message.MessageID afterDelay:15.0];
}

// Return error from MessageEventModel delegate
- (void)updateMessageEventsError:(NSError *)error
{
	NSLog(@"Error getting Basic Events");
	
	self.isLoaded = YES;
	
	// Show error message only if device offline
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	}
}

// Return message recipients from MessageRecipientModel delegate
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients
{
	// Disable forward button if there are no valid message recipients to forward to
	if ([newMessageRecipients count] > 0)
	{
		[self.buttonForward setEnabled:YES];
	}
}

// Return error from MessageRecipientModel delegate
- (void)updateMessageRecipientsError:(NSError *)error
{
	NSLog(@"There was a problem retrieving recipients for the Message");
	
	// Show error message only if device offline
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	}
}

// Return pending from CommentModel delegate
- (void)saveCommentPending:(NSString *)commentText withPendingID:(NSNumber *)pendingID
{
	// Add comment to basic events array
	MessageEventModel *comment = [[MessageEventModel alloc] init];
	NSDate *currentDate = [[NSDate alloc] init];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	// Set comment details
	[comment setID:pendingID];
	[comment setDetail:(NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)commentText, CFSTR(""), kCFStringEncodingUTF8))];
	[comment setEnteredByID:self.currentUserID];
	[comment setMessageID:self.message.MessageID];
	[comment setType:@"Comment"];
	
	// Create local date
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	[comment setTime_LCL:[dateFormatter stringFromDate:currentDate]];
	
	// Create UTC date
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
	[comment setTime_UTC:[dateFormatter stringFromDate:currentDate]];
	
	[self.filteredMessageEvents addObject:comment];
	
	// Begin actual update
	[self.tableComments beginUpdates];
	
	// If adding first comment/event
	if ([self.filteredMessageEvents count] == 1)
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
		
		[self.tableComments reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If adding to already existing comments/events
	else
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.filteredMessageEvents count] - 1 inSection:0]];
		
		[self.tableComments insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	
	// Commit row updates
	[self.tableComments endUpdates];
	
	// Auto size table comments height to show all rows
	[self autoSizeTableComments];
	
	// Clear and resign focus from text view comment
	[self.textViewComment setText:@""];
	[self.textViewComment resignFirstResponder];
	[self.buttonSend setEnabled:NO];
	
	// Trigger a scroll to bottom to ensure the newly added comment is shown
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

// Return error from CommentModel delegate
- (void)saveCommentError:(NSError *)error withPendingID:(NSNumber *)pendingID
{
	// Find comment with pending id in Filtered message events
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", pendingID];
	NSArray *results = [self.filteredMessageEvents filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find and delete table cell that contains the comment
		MessageEventModel *messageEvent = [results objectAtIndex:0];
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForItem:[self.filteredMessageEvents indexOfObject:messageEvent] inSection:0]];
		
		// Remove comment from filtered message events
		[self.filteredMessageEvents removeObject:messageEvent];
		
		// If removing the only comment/event
		if ([self.filteredMessageEvents count] == 0)
		{
			[self.tableComments reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		// If removing from existing comments/events
		else
		{
			[self.tableComments deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		}
	}
}

/*/ Return success from CommentModel delegate (no longer used)
- (void)saveCommentSuccess:(NSString *)commentText
{
	// Add comment to basic events array
	MessageEventModel *comment = [[MessageEventModel alloc] init];
	NSDate *currentDate = [[NSDate alloc] init];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
 
	// Create local date
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	[comment setTime_LCL:[dateFormatter stringFromDate:currentDate]];
 
	// Create UTC date
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
	[comment setTime_UTC:[dateFormatter stringFromDate:currentDate]];
 
	[comment setDetail:(NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)commentText, CFSTR(""), kCFStringEncodingUTF8))];
	[comment setType:@"Comment"];
	[comment setEnteredByID:self.currentUserID];
 
	[self.filteredMessageEvents addObject:comment];
 
	// Begin actual update
	[self.tableComments beginUpdates];
 
	// If adding first comment
	if ([self.filteredMessageEvents count] == 1)
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
 
		[self.tableComments reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If adding to already existing comments
	else
	{
		NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.filteredMessageEvents count] - 1 inSection:0]];
 
		[self.tableComments insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
 
	// Commit row updates
	[self.tableComments endUpdates];
 
	// Auto size table comments height to show all rows
	[self autoSizeTableComments];
 
	// Clear and resign focus from text view comment
	[self.textViewComment setText:@""];
	[self.textViewComment resignFirstResponder];
	[self.buttonSend setEnabled:NO];
 
	// Trigger a scroll to bottom to ensure the newly added comment is shown
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

// Return error from CommentModel delegate (no longer used)
- (void)saveCommentError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
 
	[errorAlertController show:error];
}*/

- (void)setMessageDetails
{
	// Set recipient name, phone number, and message
	[self.buttonPhoneNumber setTitle:self.message.SenderContact forState:UIControlStateNormal];
	[self.labelName setText:self.message.SenderName];
	[self.textViewMessage setText:self.message.FormattedMessageText];
	
	/*/ TESTING ONLY (used for generating screenshots)
	#ifdef DEBUG
		[self.labelName setText:@"TeleMed"];
		[self.buttonPhoneNumber setTitle:@"800-420-4695" forState:UIControlStateNormal];
		[self.textViewMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
	#endif
	// END TESTING ONLY */
	
	// Set message date and time
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	NSDate *dateTime = [dateFormatter dateFromString:self.message.TimeReceived_LCL];
	
	// If date is nil, it may have been formatted incorrectly
	if (dateTime == nil)
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		dateTime = [dateFormatter dateFromString:self.message.TimeReceived_LCL];
	}
	
	[dateFormatter setDateFormat:@"M/dd/yy"];
	NSString *date = [dateFormatter stringFromDate:dateTime];
	
	[dateFormatter setDateFormat:@"h:mm a"];
	NSString *time = [dateFormatter stringFromDate:dateTime];
	
	[self.labelDate setText:date];
	[self.labelTime setText:time];
}

// Scroll to bottom of scroll view
- (void)scrollToBottom
{
	CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
	
	if (bottomOffset.y > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.scrollView setContentOffset:bottomOffset animated:YES];
		});
	}
}

// Auto size table comments height to show all rows
- (void)autoSizeTableComments
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		CGSize newSize = [self.tableComments sizeThatFits:CGSizeMake(self.tableComments.frame.size.width, MAXFLOAT)];
		
		self.constraintTableCommentsHeight.constant = newSize.height;
	});
}

- (void)dismissKeyboard:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.textViewComment resignFirstResponder];
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
	
	// Scroll to bottom of comments after frame resizes
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewCommentPlaceholder])
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
		[textView setText:self.textViewCommentPlaceholder];
		[textView setTextColor:[UIColor colorWithRed:98.0/255.0 green:98.0/255.0 blue:98.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
	}
	
	[textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Scroll scroll view content to bottom
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.0];
	
	[self.buttonSend setEnabled:( ! [textView.text isEqualToString:@""] && ! [textView.text isEqualToString:self.textViewCommentPlaceholder])];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no comments available
	if ([self.filteredMessageEvents count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No comments have been added yet." : @"Loading...")];
		
		// Auto size table comments height to show all rows
		[self autoSizeTableComments];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"CommentCell";
	static NSString *cellIdentifierSent = @"SentCommentCell";
	static NSString *cellIdentifierEvent = @"MessageEventCell";
	
	// Set up the cell
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	BOOL isComment = [messageEvent.Type isEqualToString:@"Comment"];
	BOOL currentUserIsSender = ([messageEvent.EnteredByID isEqualToNumber:self.currentUserID]);
	//BOOL currentUserIsSender = ! (indexPath.row % 2); // Only used for testing both cell types
	
	// Set both types of events to use CommentCell (events of type "User" should technically use MessageEventCell, but it doesn't matter for now since they both share the same label identifiers)
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:(isComment ? (currentUserIsSender ? cellIdentifierSent : cellIdentifier) : cellIdentifierEvent)];
	
	// Set message event date and time
	if (messageEvent.Time_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if (dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy h:mm a"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
	}
	
	// Set message event detail
	[cell.labelDetail setText:messageEvent.Detail];
	
	// Set message event sender (only applies to comments)
	if (isComment && ! currentUserIsSender)
	{
		[cell.labelEnteredBy setText:messageEvent.EnteredBy];
	}
	
	// Auto size table comments height to show all rows
	[self autoSizeTableComments];
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	if ([segue.identifier isEqualToString:@"showMessageHistory"])
	{
		MessageHistoryViewController *messageHistoryViewController = [segue destinationViewController];
		
		[messageHistoryViewController setMessage:self.message];
		[messageHistoryViewController setMessageEvents:self.messageEvents];
		[messageHistoryViewController setCanForward:self.buttonForward.enabled];
	}
}
#endif


#pragma mark - Med2Med

#ifdef MED2MED
// TEMPORARY (remove in phase 2)
- (void)viewDidLayoutSubviews
{
	// Hide comments label
	[self.labelCommentsEvents setHidden:YES];

	// Hide comments table
	[self.tableComments setHidden:YES];
	[self.constraintTableCommentsHeight setConstant:0.0f];

	// Hide add comments container
	//[self.viewAddCommentContainer setHidden:YES];
	[self.constraintButtonAddCommentHeight setConstant:0.0f];
	[self.textViewComment.heightConstraint setConstant:0.0f];
}
// END TEMPORARY

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
}
#endif

@end
