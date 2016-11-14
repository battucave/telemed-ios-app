//
//  MessageDetailViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageDetailViewController.h"
#import "MessageHistoryViewController.h"
#import "AutoGrowingTextView.h"
#import "CommentCell.h"
#import "MessageEventCell.h"
#import "CommentModel.h"
#import "MessageEventModel.h"
#import "MessageRecipientModel.h"
#import "MyProfileModel.h"
#import <QuartzCore/QuartzCore.h>

@interface MessageDetailViewController ()

@property (nonatomic) CommentModel *commentModel;
@property (nonatomic) MessageEventModel *messageEventModel;
@property (nonatomic) MessageRecipientModel *messageRecipientModel;

@property (weak, nonatomic) IBOutlet UIView *viewPriority;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIButton *buttonPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tableComments;
@property (weak, nonatomic) IBOutlet AutoGrowingTextView *textViewComment;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTextViewMessageHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTableCommentsHeight;

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
	
	// Set Current User ID
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	self.currentUserID = myProfileModel.ID;
	
	// Initialize Basic Event Model
	[self setMessageEventModel:[[MessageEventModel alloc] init]];
	[self.messageEventModel setDelegate:self];
	
	// Initialize Message Recipient Model
	[self setMessageRecipientModel:[[MessageRecipientModel alloc] init]];
	[self.messageRecipientModel setDelegate:self];
	
	// Initialize Text View Comment Input
	UIEdgeInsets textViewCommentEdgeInsets = self.textViewComment.textContainerInset;
	
	[self.textViewComment setDelegate:self];
	[self.textViewComment setTextContainerInset:UIEdgeInsetsMake(textViewCommentEdgeInsets.top, 12.0f, textViewCommentEdgeInsets.bottom, 12.0f)];
	[self.textViewComment setMaxHeight:120.0f];
	self.textViewCommentPlaceholder = self.textViewComment.text;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	//NSLog(@"Message ID: %@", self.message.ID);
	
	// Mark message as read if active message
	if(self.message.messageType == 0)
	{
		[self.messageModel modifyMessageState:self.message.ID state:@"read"];
		
		/*/ TESTING ONLY (set message back to unread)
		#if defined(DEBUG)
		[self.messageModel modifyMessageState:self.message.ID state:@"unread"];
		#endif
		// END TESTING ONLY*/
	}
	/*/ TESTING ONLY (unarchive archived messages)
	else
	{
		#if defined(DEBUG)
		[self.messageModel modifyMessageState:self.message.ID state:@"unarchive"];
		#endif
	}
	// END TESTING ONLY*/
	
	// Set Message Details
	[self setMessageDetails];
	
	// Load Message Events
	[self.messageEventModel getMessageEvents:self.message.ID];
	
	// Load Forward Message Recipients to determine if message is forwardable
	[self.messageRecipientModel getForwardMessageRecipients:self.message.ID];
	
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
	
	// Stop refreshing message events when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self.messageEventModel];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	
	// Remove Application Did Enter Background Observer to Hide Keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Remove Call Disconnected Observer to Hide Keyboard
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidDisconnectCall" object:nil];
	
	// Dismiss Keyboard
	[self.view endEditing:YES];
}

- (IBAction)sendComment:(id)sender
{
	//NSString *commentText = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.textViewComment.text, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
	
	[self setCommentModel:[[CommentModel alloc] init]];
	[self.commentModel setDelegate:self];
	
	[self.commentModel addMessageComment:self.message.ID comment:self.textViewComment.text];
}

// Override default Remote Notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID
{
	NSLog(@"Received Remote Notification MessageDetailViewController");
	
	// TESTING ONLY (test custom handling of push notification comment to a particular message
	/*#if defined(DEBUG)
	message = @"Shane Goodwin added a comment to a message.";
	type = @"comment";
	deliveryId = 5133538688695397;
	#endif*/
	
	// Reload Message Events if remote notification is a comment specifically for the current message
	if([notificationType isEqualToString:@"Comment"] && deliveryID && [deliveryID isEqualToNumber:self.message.ID])
	{
		NSLog(@"Refresh Comments with Message ID: %@", deliveryID);
		
		[self.messageEventModel getMessageEvents:self.message.ID];
		
		//return;
	}
	
	// If remote notification is NOT a comment specifically for the current message, execute the default notification message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID];
}

// Return Events from MessageEventModel delegate
- (void)updateMessageEvents:(NSMutableArray *)newMessageEvents
{
	self.isLoaded = YES;
	self.messageEvents = newMessageEvents;
	
	[self.filteredMessageEvents removeAllObjects];
	
	// Add only comments from Basic Events
	for(MessageEventModel *messageEvent in newMessageEvents)
	{
		if([messageEvent.Type isEqualToString:@"Comment"] || [messageEvent.Type isEqualToString:@"User"])
		{
			[self.filteredMessageEvents addObject:messageEvent];
		}
	}
	
	// Refresh message events again after delay
	[self.messageEventModel performSelector:@selector(getMessageEvents:) withObject:self.message.ID afterDelay:15.0];
	
	/*/ TESTING ONLY (used for generating Screenshots)
	#if defined(DEBUG)
	[self.filteredMessageEvents removeAllObjects];
	
	for(int i = 0; i < 3; i++)
	{
		MessageEventModel *messageEvent = [[MessageEventModel alloc] init];
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		
		[messageEvent setValue:@"Comment" forKey:@"Type"];
		
		// Test Message from Jason
		if(i == 0)
		{
			[messageEvent setValue:@"Jason Hutchison" forKey:@"EnteredBy"];
			[messageEvent setValue:@"2015-04-11T13:24:06.444" forKey:@"Time_LCL"];
			[messageEvent setValue:@"Introducing the new TeleMed comments section" forKey:@"Detail"];
		}
		// Test Message from Me (ensure EnteredyByID matches own logged in ID)
		else if(i == 1)
		{
			[messageEvent setValue:[numberFormatter numberFromString:@"14140220"] forKey:@"EnteredByID"];
			[messageEvent setValue:@"2015-04-11T15:46:06.444" forKey:@"Time_LCL"];
			[messageEvent setValue:@"Tap on the message field at the bottom of the screen to send messages back and forth." forKey:@"Detail"];
		}
		// Test Message from Jason
		else if(i == 2)
		{
			[messageEvent setValue:@"Jason Hutchison" forKey:@"EnteredBy"];
			[messageEvent setValue:@"2015-04-12T10:58:39.444" forKey:@"Time_LCL"];
			[messageEvent setValue:@"Events are now found by tapping the History button located above." forKey:@"Detail"];
		}
		
		[self.filteredMessageEvents addObject:messageEvent];
	}
	#endif
	// END TESTING ONLY*/
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableComments reloadData];
		
		// Scroll to bottom of comments after table reloads data only if a new comment has been added since last check
		if(self.messageCount > 0 && [self.filteredMessageEvents count] > self.messageCount)
		{
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
		}
		
		// Update message count with new number of Filtered Message Events
		self.messageCount = [self.filteredMessageEvents count];
	});
}

// Return error from MessageEventModel delegate
- (void)updateMessageEventsError:(NSError *)error
{
	NSLog(@"Error getting Basic Events");
	
	self.isLoaded = YES;
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.messageEventModel showOfflineError];
	}
}

// Return Message Recipients from MessageRecipientModel delegate
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients
{
	// Disable Forward Button if there are no valid Message Recipients to forward to
	if([newMessageRecipients count] > 0)
	{
		[self.buttonForward setEnabled:YES];
	}
}

// Return error from MessageRecipientModel delegate
- (void)updateMessageRecipientsError:(NSError *)error
{
	NSLog(@"There was a problem retrieving recipients for the Message");
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.messageRecipientModel showOfflineError];
	}
}

// Return success from CommentModel delegate
- (void)saveCommentSuccess:(NSString *)commentText
{
	// Add comment to Basic Events array
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
	if([self.filteredMessageEvents count] == 1)
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
	
	// Auto size Table Comments height to show all rows
	[self autoSizeTableComments];
	
	// Clear and resign focus from Text View Comment
	[self.textViewComment setText:@""];
	[self.textViewComment resignFirstResponder];
	[self.buttonSend setEnabled:NO];
	
	// Trigger a scroll to bottom to ensure the newly added comment is shown
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.25];
}

// Return error from CommentModel delegate
- (void)saveCommentError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.commentModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Add Comment Error" message:@"There was a problem adding your Comment. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

- (void)setMessageDetails
{
	// Set Message Date and Time
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	NSDate *dateTime = [dateFormatter dateFromString:self.message.TimeReceived_LCL];
	
	// If date is nil, it may have been formatted incorrectly
	if(dateTime == nil)
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
	
	// Set Message Name, Phone Number, and Message
	[self.labelName setText:self.message.SenderName];
	[self.buttonPhoneNumber setTitle:self.message.SenderContact forState:UIControlStateNormal];
	[self.textViewMessage setText:self.message.FormattedMessageText];
	
	// Set Message Priority color
	if([self.message.Priority isEqualToString:@"Priority"])
	{
		[self.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
	}
	else if([self.message.Priority isEqualToString:@"Stat"])
	{
		[self.viewPriority setBackgroundColor:[UIColor colorWithRed:182.0/255.0 green:42.0/255.0 blue:19.0/255.0 alpha:1]];
	}
	
	/*/ TESTING ONLY (used for generating Screenshots)
	#if defined(DEBUG)
	[self.labelName setText:@"TeleMed"];
	[self.buttonPhoneNumber setTitle:@"800-420-4695" forState:UIControlStateNormal];
	[self.textViewMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
	#endif
	// END TESTING ONLY*/
	
	// Disable Archive Button for already Archived messages
	if(self.message.messageType > 0)
	{
		[self.buttonArchive setEnabled:NO];
	}
	
	// In XCode 8+, all view frame sizes are initially 1000x1000. Have to call "layoutIfNeeded" first to get actual value.
	[self.textViewMessage layoutIfNeeded];
	
	// Auto size Text View Message height to its contents
	CGSize newSize = [self.textViewMessage sizeThatFits:CGSizeMake(self.textViewMessage.frame.size.width, MAXFLOAT)];
	
	self.constraintTextViewMessageHeight.constant = newSize.height;
}

// Scroll to bottom of Scroll View
- (void)scrollToBottom
{
	CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
	
	if(bottomOffset.y > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.scrollView setContentOffset:bottomOffset animated:YES];
		});
	}
}

// Auto size Table Comments height to show all rows
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
	if([textView.text isEqualToString:self.textViewCommentPlaceholder])
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
	if([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewCommentPlaceholder];
		[textView setTextColor:[UIColor colorWithRed:98.0/255.0 green:98.0/255.0 blue:98.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:17.0]];
	}
	
	[textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Scroll Scroll View content to bottom
	[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.0];
	
	[self.buttonSend setEnabled:( ! [textView.text isEqualToString:@""] && ! [textView.text isEqualToString:self.textViewCommentPlaceholder])];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.filteredMessageEvents count] == 0)
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
	// Return default height if no Comments available
	if([self.filteredMessageEvents count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
	
	/*/ Manually determine height for < iOS8 OR for calculating total table height before all rows have loaded
	static NSString *cellIdentifier = @"CommentCell";
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	// Calculate Auto Height of Table Cell
	[cell.labelDetail setText:messageEvent.Detail];
	[cell.labelDetail setPreferredMaxLayoutWidth:cell.labelDetail.frame.size.width];
	
	// Determine the new height
	CGFloat cellHeight = ceil([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
	
	return cellHeight;*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no Comments available
	if([self.filteredMessageEvents count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No comments have been added yet." : @"Loading...")];
		
		// Auto size Table Comments height to show all rows
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
	
	// Set both types of events to use CommentCell (Events of type "User" should technically use MessageEventCell, but it doesn't matter for now since they both share the same Label identifiers)
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:(isComment ? (currentUserIsSender ? cellIdentifierSent : cellIdentifier) : cellIdentifierEvent)];
	
	// Set Message Event Date and Time
	if(messageEvent.Time_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if(dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy h:mm a"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
	}
	
	// Set Message Event Detail
	[cell.labelDetail setText:messageEvent.Detail];
	
	// Set Message Event Sender (only applies to Comments)
	if(isComment && ! currentUserIsSender)
	{
		[cell.labelEnteredBy setText:messageEvent.EnteredBy];
	}
	
	// Auto size Table Comments height to show all rows
	[self autoSizeTableComments];
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	if([[segue identifier] isEqualToString:@"showMessageHistory"])
	{
		MessageHistoryViewController *messageHistoryViewController = [segue destinationViewController];
		
		[messageHistoryViewController setMessage:self.message];
		[messageHistoryViewController setMessageEvents:self.messageEvents];
		[messageHistoryViewController setCanForward:self.buttonForward.enabled];
		
		if(self.message.messageType > 0)
		{
			[messageHistoryViewController setIsArchived:YES];
		}
	}
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
