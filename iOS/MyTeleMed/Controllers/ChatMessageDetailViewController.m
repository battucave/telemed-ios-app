//
//  ChatMessageDetailViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/5/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessageDetailViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AutoGrowingTextView.h"
#import "CommentCell.h"

// TEMPORARY
#import "MessageEventModel.h"

@interface ChatMessageDetailViewController ()

// TEMPORARY
@property (nonatomic) MessageEventModel *messageEventModel;

@property (weak, nonatomic) IBOutlet UITableView *tableComments;
@property (weak, nonatomic) IBOutlet AutoGrowingTextView *textViewComment;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTextViewMessageHeight;

@property (nonatomic) NSUInteger messageCount;
@property (nonatomic) CGFloat tableCommentsContentHeight;
@property (nonatomic) NSString *textViewCommentPlaceholder;

@property (nonatomic) BOOL isLoaded;

// TEMPORARY
@property (nonatomic) NSArray *messageEvents;
@property (nonatomic) NSMutableArray *filteredMessageEvents;

@end

@implementation ChatMessageDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// TEMPORARY - Initialize Basic Event Model
	[self setMessageEventModel:[[MessageEventModel alloc] init]];
	[self.messageEventModel setDelegate:self];
	
	// TEMPORARY - Initialize Filtered Basic Events
	[self setFilteredMessageEvents:[NSMutableArray array]];
	
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
	
	// Only get Chat Messages if there is an existing Conversation ID (New Chat Message does not have Conversation ID)
	if(self.conversationID)
	{
		// TEMPORARY
		[self.messageEventModel getMessageEvents:self.conversationID];
	}
	
	// Add Keyboard Observers (iOS 7)
	if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
	// Add Keyboard Observers (iOS 8+)
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillHideNotification object:nil];
	}
	
	// Add Application Did Enter Background Observer to Hide Keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Add Call Disconnected Observer to Hide Keyboard
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissKeyboard:) name:@"UIApplicationDidDisconnectCall" object:nil];
	
	// Add 10px to bottom of Table Comments
	[self.tableComments setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop refreshing message events when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self.messageEventModel];
	
	// Remove Keyboard Observers (iOS 7)
	if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	}
	// Remove Keyboard Observers (iOS 8+)
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	}
	
	// Remove Application Did Enter Background Observer to Hide Keyboard (otherwise it will be hidden when app returns to foreground)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Remove Call Disconnected Observer to Hide Keyboard
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidDisconnectCall" object:nil];
}

// Perform Segue to MessageRecipientPickerTableViewController
- (IBAction)performSegueToMessageRecipientPicker:(id)sender
{
	[self performSegueWithIdentifier:@"showMessageRecipientPickerFromChatMessageDetail" sender:sender];
}

// Unwind Segue from MessageRecipientPickerViewController
- (IBAction)setMessageRecipients:(UIStoryboardSegue *)segue
{
	// Obtain reference to Source View Controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	/*// Save selected Message Recipients
	[self setSelectedMessageRecipients:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Update MessageComposeTableViewController with selected Message Recipient Names
	if([self.messageComposeTableViewController respondsToSelector:@selector(updateSelectedMessageRecipients:)])
	{
		[self.messageComposeTableViewController updateSelectedMessageRecipients:self.selectedMessageRecipients];
	}
	
	// Validate form
	[self validateForm:self.messageComposeTableViewController.textViewMessage.text];*/
}

/*/ Override default Remote Notification action from CoreViewController
- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID
{
	NSLog(@"Received Remote Notification ChatMessageDetailViewController");
	
	// Reload Message Events if remote notification is a comment specifically for the current message
	if([notificationType isEqualToString:@"Comment"] && deliveryID && [deliveryID isEqualToNumber:self.message.ID])
	{
		NSLog(@"Refresh Comments with Message ID: %@", deliveryID);
		
		[self.messageEventModel getMessageEvents:self.message.ID];
		
		//return;
	}
	
	// If remote notification is NOT a comment specifically for the current message, execute the default notification message action
	[super handleRemoteNotificationMessage:message ofType:notificationType withDeliveryID:deliveryID];
}*/

// Return Events from MessageEventModel delegate
- (void)updateMessageEvents:(NSMutableArray *)newMessageEvents
{
	self.isLoaded = YES;
	self.messageEvents = newMessageEvents;
	
	[self.filteredMessageEvents removeAllObjects];
	
	// Add only comments from Basic Events
	for(MessageEventModel *messageEvent in newMessageEvents)
	{
		if([messageEvent.Type isEqualToString:@"Comment"])
		{
			[self.filteredMessageEvents addObject:messageEvent];
		}
	}
	
	// Refresh message events again after delay
	//[self.messageEventModel performSelector:@selector(getMessageEvents:) withObject:self.message.ID afterDelay:15.0];
	
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

// Scroll to bottom of Table Comments
- (void)scrollToBottom
{
	// Calulate total height of Table Comments (needed when there are more rows than what will remain in memory)
	if( ! self.tableCommentsContentHeight)
	{
		for(int i = 0; i < [self.filteredMessageEvents count]; i++)
		{
			self.tableCommentsContentHeight += [self tableView:self.tableComments heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		}
	}
	
	// This value is not accurate when more than @ 15 rows:
	// CGPoint bottomOffset = CGPointMake(0, self.tableComments.contentSize.height - self.tableComments.bounds.size.height + self.tableComments.contentInset.bottom);
	
	// So use this instead:
	CGPoint bottomOffset = CGPointMake(0, self.tableCommentsContentHeight - self.tableComments.bounds.size.height + self.tableComments.contentInset.bottom);
	
	if(bottomOffset.y > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableComments setContentOffset:bottomOffset animated:YES];
		});
	}
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
	// If there is an existing Conversation ID, but no Chat Messages, show a message
	if(self.conversationID && [self.filteredMessageEvents count] == 0)
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
	// iOS8+ Auto Height (can't use this because [self scrollToBottom] method needs actual height value to calculate total height of Table Comments
	/*else if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
	{
		return UITableViewAutomaticDimension;
	}*/
	
	// Manually determine height for < iOS8
	static NSString *cellIdentifier = @"ChatMessageDetailCell";
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	// Calculate Auto Height of Table Cell
	[cell.labelDetail setText:messageEvent.Detail];
	[cell.labelDetail setPreferredMaxLayoutWidth:cell.labelDetail.frame.size.width];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	// Determine the new height
	CGFloat cellHeight = ceil([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
	
	return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no Comments available
	if([self.filteredMessageEvents count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// // If there is an existing Conversation ID, but no Chat Messages, show a message
		if(self.conversationID)
		{
			[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
			[emptyCell.textLabel setText:(self.isLoaded ? @"No comments have been added yet." : @"Loading...")];
		}
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageDetailCell";
	static NSString *cellIdentifierSent = @"SentChatMessageDetailCell";
	
	// Set up the cell
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	BOOL isComment = [messageEvent.Type isEqualToString:@"Comment"];
	//BOOL currentUserIsSender = ([messageEvent.EnteredByID isEqualToNumber:self.currentUserID]);
	BOOL currentUserIsSender = ! (indexPath.row % 2); // Only used for testing both cell types
	
	// Set both types of events to use CommentCell
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:(currentUserIsSender ? cellIdentifierSent : cellIdentifier)];

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
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showMessageRecipientPickerFromChatMessageDetail"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Message Recipient Type
		[messageRecipientPickerViewController setMessageRecipientType:@"Chat"];
		
		// Set selected Message Recipients if previously set
		//[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
