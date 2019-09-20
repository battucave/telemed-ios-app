//
//  MessagesTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessagesTableViewController.h"
#import "ErrorAlertController.h"
#import "MessageDetailViewController.h"
#import "MessageCell.h"
#import "MessageProtocol.h"
#import "SentMessageModel.h"

#ifdef MYTELEMED
	#import "MessageModel.h"
#endif

@interface MessagesTableViewController ()

#ifdef MYTELEMED
	@property (nonatomic) MessageModel *messageModel;
#endif

@property (nonatomic) SentMessageModel *sentMessageModel;

@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableArray *hiddenMessages;
@property (nonatomic) NSMutableArray *selectedMessages;

@property (nonatomic) NSString *messagesType; // Active, Archived, Sent

// Archived message properties
@property (nonatomic) NSNumber *archiveAccountID;
@property (nonatomic) NSDate *archiveStartDate;
@property (nonatomic) NSDate *archiveEndDate;

// Pagination properties
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) BOOL isFetchingNextPage;
@property (nonatomic) BOOL isFirstPageLoaded;
@property (nonatomic) BOOL isLastPageLoaded;
@property (nonatomic) UIActivityIndicatorView *loadingActivityIndicator;

@end

@implementation MessagesTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Fix bug in iOS 7+ where text overlaps indicator on first run
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});
	
	// Initialize SentMessageModel
	[self setSentMessageModel:[[SentMessageModel alloc] init]];
	[self.sentMessageModel setDelegate:self];
	
	// Initialize current page
	[self setCurrentPage:1];
	
	#ifdef MYTELEMED
		// Initialize MessageModel
		[self setMessageModel:[[MessageModel alloc] init]];
		[self.messageModel setDelegate:self];
	
		// Initialize loading activity indicator to be used when loading additional messages
		[self setLoadingActivityIndicator:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];

		[self.loadingActivityIndicator setColor:[UIColor darkGrayColor]];
		[self.loadingActivityIndicator setFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 60.0)];
		[self.loadingActivityIndicator startAnimating];
	#endif
	
	// Initialize hidden messages
	[self setHiddenMessages:[NSMutableArray new]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	[self reloadMessages];
	
	// Disable refresh control for sent and archived messages
	if (! [self.messagesType isEqualToString:@"Active"])
	{
		[self setRefreshControl:nil];
	}
}

// Action to perform when refresh control triggered
- (IBAction)refreshControlRequest:(id)sender
{
	// Cancel queued messages refresh
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self reloadMessages];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
	
	[settings synchronize];
}

// Reload messages
- (void)reloadMessages
{
	[self loadMessages:1];
	
	// Note: Don't trigger the isFetchingNextPage flag here (its only used for fetching "next" messages)
}

// Return sent messages from SentMessageModel delegate
- (void)updateSentMessages:(NSArray *)sentMessages
{
	[self setIsFirstPageLoaded:YES];
	[self setMessages:[sentMessages mutableCopy]];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Return error from SentMessageModel delegate
- (void)updateSentMessagesError:(NSError *)error
{
	[self setIsFirstPageLoaded:YES];
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return MAX([self.messages count], 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are messages and hidden messages and row is not the only row in the table
	if ([self.messagesType isEqualToString:@"Active"] && [self.messages count] > 0 && [self.hiddenMessages count] > 0 && (indexPath.row > 0 || [self.messages count] != [self.hiddenMessages count]))
	{
		id <MessageProtocol> message = [self.messages objectAtIndex:indexPath.row];
		
		// Hide hidden messages by setting the cell's height to 0
		if ([self.hiddenMessages containsObject:message])
		{
			return 0.0f;
		}
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.messages count] == 0 || (indexPath.row == 0 && [self.messages count] == [self.hiddenMessages count]))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		[emptyCell.textLabel setText:(self.isFirstPageLoaded ? @"No messages available." : @"Loading...")];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"MessageCell";
	MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	id message = [self.messages objectAtIndex:indexPath.row];
	
	// Sent messages
	if ([self.messagesType isEqualToString:@"Sent"])
	{
		return [self cellForSentMessage:cell withMessage:message atIndexPath:indexPath];
	}
	// Active and archived messages
	else
	{
		return [self cellForReceivedMessage:cell withMessage:message atIndexPath:indexPath];
	}
}

- (UITableViewCell *)cellForReceivedMessage:(MessageCell *)cell withMessage:(id <MessageProtocol>)message atIndexPath:(NSIndexPath *)indexPath
{
	// Set name, phone number, and message
	[cell.labelName setText:message.SenderName];
	[cell.labelPhoneNumber setText:message.SenderContact];
	[cell.labelMessage setText:message.FormattedMessageText];
	
	// Set date and time
	if (message.TimeReceived_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:message.TimeReceived_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if (dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:message.TimeReceived_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[dateFormatter setDateFormat:@"h:mm a"];
		NSString *time = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
		[cell.labelTime setText:time];
	}
	
	// If message has been read, change status image to unread icon
	if ([message.State isEqualToString:@"Unread"])
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Unread"]];
	}
	else
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Read"]];
	}
	
	/*/ TESTING ONLY (used for generating screenshots)
	#ifdef DEBUG
		[cell.labelName setText:@"TeleMed"];
		[cell.labelPhoneNumber setText:@"800-420-4695"];
		[cell.labelMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
		
		if (indexPath.row < 3)
		{
			[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Unread"]];
		}
		else
		{
			[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Read"]];
		}
	#endif
	// END TESTING ONLY */
	
	// Set message priority color
	if ([message.Priority isEqualToString:@"Priority"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
	}
	else if ([message.Priority isEqualToString:@"Stat"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:182.0/255.0 green:42.0/255.0 blue:19.0/255.0 alpha:1]];
	}
	else
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:19.0/255.0 green:182.0/255.0 blue:38.0/255.0 alpha:1]];
	}
	
	return cell;
}

- (UITableViewCell *)cellForSentMessage:(MessageCell *)cell withMessage:(SentMessageModel *)sentMessage atIndexPath:(NSIndexPath *)indexPath
{
	NSString *messageRecipientNames = @"";
	
	// Format message recipient names
	NSArray *messageRecipients = [sentMessage.Recipients componentsSeparatedByString:@";"];
	
	if ([messageRecipients count] > 0)
	{
		messageRecipientNames = [messageRecipients objectAtIndex:0];
		
		if ([messageRecipients count] > 1)
		{
			messageRecipientNames = [messageRecipientNames stringByAppendingFormat:@" & %lu more...", (unsigned long)[messageRecipients count] - 1];
		}
	}
	
	// Set name, phone number, and message
	[cell.labelName setText:messageRecipientNames];
	[cell.labelPhoneNumber setText:@""];
	[cell.labelMessage setText:sentMessage.FormattedMessageText];
	
	// Set date and time
	if (sentMessage.FirstSent_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:sentMessage.FirstSent_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if (dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:sentMessage.FirstSent_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[dateFormatter setDateFormat:@"h:mm a"];
		NSString *time = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
		[cell.labelTime setText:time];
	}
	
	// Hide status image
	[cell.imageStatus setHidden:YES];
	[cell.constraintNameLeadingSpace setConstant:7.0f];
	
	/*/ TESTING ONLY (used for generating screenshots)
	#ifdef DEBUG
		[cell.labelName setText:@"TeleMed"];
		[cell.labelMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
	#endif
	// END TESTING ONLY */
	
	// Set message priority color
	if ([sentMessage.Priority isEqualToString:@"Priority"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
	}
	else if ([sentMessage.Priority isEqualToString:@"Stat"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:182.0/255.0 green:42.0/255.0 blue:19.0/255.0 alpha:1]];
	}
	else
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:19.0/255.0 green:182.0/255.0 blue:38.0/255.0 alpha:1]];
	}
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are no messages, then user clicked the no messages cell
	return ([self.messages count] <= indexPath.row ? nil : indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the archive button in MessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedMessages = [NSMutableArray new];
			
			for (NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedMessages addObject:[self.messages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedMessages:self.selectedMessages];
		}
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the archive button in MessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedMessages = [NSMutableArray new];
			
			for (NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedMessages addObject:[self.messages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedMessages:self.selectedMessages];
		}
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	// If navigating to MessageDetailViewController, but there are no messages, then user clicked the no messages found cell
	if ([identifier isEqualToString:@"showMessageDetail"])
	{
		return ! self.editing && [self.messages count] > 0;
	}
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageDetail"])
	{
		MessageDetailViewController *messageDetailViewController = segue.destinationViewController;
		long selectedRow = [self.tableView indexPathForSelectedRow].row;
		
		if ([self.messages count] > selectedRow)
		{
			id <MessageProtocol> message = [self.messages objectAtIndex:selectedRow];
			
			[messageDetailViewController setMessage:message];
		}
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


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel queued messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

// Delegate method from ArchivesViewController
- (void)filterArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	[self setArchiveAccountID:accountID];
	[self setArchiveStartDate:startDate];
	[self setArchiveEndDate:endDate];
	
	// Don't need to reload messages here because viewWillAppear fires when ArchivesPickerViewController is popped from navigation controller
}

// Compare messages to existing messages to determine which messages are new
- (NSArray *)computeNewMessages:(NSArray *)messages
{
	// Use NSSet's minusSet: to determine which messages are new
	NSSet *existingMessages = [NSSet setWithArray:self.messages];
	NSMutableSet *newMessages = [NSMutableSet setWithArray:messages];

	[newMessages minusSet:existingMessages];

	// Convert NSSet back into NSArray
	return [newMessages allObjects];
}

// Hide selected messages that are pending deletion (called from MessagesViewController)
- (void)hideSelectedMessages:(NSArray *)messages
{
	// If there are no messages to hide, then stop
	if ([messages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	for (id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages addObject:message];
		
		// Add index path for reloading in the table
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.messages indexOfObject:message] inSection:0]];
	}
	
	// Hide rows at specified index paths in the table
	[self reloadRowsAtIndexPaths:indexPaths];
	
	// Toggle the edit button
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.messages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
}

// Insert new rows into the table
- (void)insertNewRowsStartingAt:(NSInteger)startIndex endingAt:(NSInteger)endIndex withCompletion:(void (^)(BOOL))completion
{
	NSInteger numberOfRows = endIndex - startIndex;
	
	// If there are no rows to refresh, then execute the completion block
	if (numberOfRows == 0)
	{
		completion(YES);
		
		return;
	}

	NSMutableArray *newIndexPaths = [NSMutableArray new];
	
	for (int i = 0; i < numberOfRows; i++)
	{
		// Add index path for insertion into the table
		[newIndexPaths addObject:[NSIndexPath indexPathForRow:(startIndex + i) inSection:0]];
	}

	// Insert new rows at specified index paths into the table
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// iOS 11+ - performBatchUpdates: is preferred over beginUpdates and endUpdates (supported in iOS 11+)
		if (@available(iOS 11.0, *))
		{
			[self.tableView performBatchUpdates:^
			{
				[self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			}
			completion:completion];
		}
		// iOS < 11 - Fall back to using beginUpdates and endUpdates
		else
		{
			[self.tableView beginUpdates];
			
			[self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			
			[self.tableView endUpdates];
			
			completion(YES);
		}
	});
}

// Reload messages
- (void)loadMessages:(NSInteger)page
{
	// Get archived messages
	if ([self.messagesType isEqualToString:@"Archived"])
	{
		[self.messageModel getArchivedMessages:page forAccount:self.archiveAccountID startDate:self.archiveStartDate endDate:self.archiveEndDate];
	}
	// Get sent messages
	else if ([self.messagesType isEqualToString:@"Sent"])
	{
		[self.sentMessageModel getSentMessages];
	}
	// Get active messages
	else
	{
		[self.messageModel getActiveMessages:page];
	}
}

// TEMPORARY (remove this method when support for iOS 10 is dropped and instead simply call table view's performBatchUpdates: directly)
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// iOS 11+ - performBatchUpdates: is preferred over beginUpdates and endUpdates (supported in iOS 11+)
		if (@available(iOS 11.0, *))
		{
			[self.tableView performBatchUpdates:^
			{
				[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			}
			completion:nil];
		}
		// iOS < 11 - Fall back to using beginUpdates and endUpdates
		else
		{
			[self.tableView beginUpdates];
			
			[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			
			[self.tableView endUpdates];
		}
	});
}

// Active messages only (MessagesViewController)
- (void)removeSelectedMessages:(NSArray *)messages
{
	// If there are no messages to remove, then stop
	if ([messages count] == 0)
	{
		return;
	}
	
	NSArray *messagesCopy = [self.messages copy];
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	// Remove each message from the source data, hidden data, selected data, and the table itself
	for (id <MessageProtocol> message in messages)
	{
		[self.messages removeObject:message];
		[self.hiddenMessages removeObject:message];
		[self.selectedMessages removeObject:message];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[messagesCopy indexOfObject:message] inSection:0]];
	}
	
	// Remove rows at specified index paths from the table
	if ([self.messages count] > 0 && [self.messages count] > [self.hiddenMessages count])
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no messages left in the source data, simply reload the table to show the no messages cell
	else
	{
		[self.tableView reloadData];
		
		// Toggle the edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.messages count] == 0 || [self.messages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
	{
		[self.delegate setSelectedMessages:self.selectedMessages];
	}
}

// HOPEFULLY TEMPORARY: Reset active messages back to loading state (remove if pagination flaw is corrected - see MessagesViewController modifyMultipleMessagesStateSuccess: for more info)
- (void)resetActiveMessages
{
	// Reload first page of messages
	[self reloadMessages];
	
	[self setCurrentPage:1];
	[self setIsFirstPageLoaded:NO];
	[self setMessages:[NSMutableArray new]];
	[self setHiddenMessages:[NSMutableArray new]];
	[self setSelectedMessages:[NSMutableArray new]];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Reset archive messages back to loading state
- (void)resetArchivedMessages
{
	[self setCurrentPage:1];
	[self setIsFirstPageLoaded:NO];
	[self setMessages:[NSMutableArray new]];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Unhide selected messages that failed during deletion (called from MessagesViewController)
- (void)unhideSelectedMessages:(NSArray *)messages
{
	// If there are no messages to unhide, then stop
	if ([messages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	for (id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages removeObject:message];
		
		// Add index path for reloading in the table
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.messages indexOfObject:message] inSection:0]];
	}
	
	// Re-show rows at specified index paths in the table
	[self reloadRowsAtIndexPaths:indexPaths];
	
	// Show the edit button (there will always be at least one message when unhiding)
	[self.parentViewController.navigationItem setRightBarButtonItem:self.parentViewController.editButtonItem];
}

// Return messages from MessageModel delegate
- (void)updateMessages:(NSArray *)messages forPage:(NSInteger)page
{
	NSLog(@"UPDATE MESSAGES FOR PAGE: %ld", (long)page);
	
	[self setIsFetchingNextPage:NO];
	[self setIsFirstPageLoaded:YES];
	
	// If the number of items returned is less than the number of messages per page, then assume the last page has been loaded
	if ([messages count] < MessagesPerPage)
	{
		[self setIsLastPageLoaded:YES];
	}
	
	// Set initial messages if empty
	if ([self.messages count] == 0)
	{
		[self setMessages:[messages mutableCopy]];
		
		// Insert initial messages into the table
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableView reloadData];
			
			// Remove loading indicator from table view
			[self.tableView setTableFooterView:[[UIView alloc] init]];
			
			// If messages type is active
			if ([self.messagesType isEqualToString:@"Active"])
			{
				// Toggle the parent view controller's edit button based on whether there are any messages
				[self.parentViewController.navigationItem setRightBarButtonItem:([self.messages count] == 0 || [self.messages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
			}
			
			[self.refreshControl endRefreshing];
		});
	}
	// Add new messages resulting from a reload to the top of existing messages
	else if (page == 1)
	{
		// Extract out new messages that didn't exist in existing messages
		NSArray *newMessages = [self computeNewMessages:messages];
		NSInteger newMessageCount = [newMessages count];
		
		// Prepend any new messages to the beginning of the existing messages
		if (newMessageCount > 0)
		{
			[self.messages insertObjects:newMessages atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newMessageCount)]];
		}
		
		// Insert new messages into the table and end refreshing
		[self insertNewRowsStartingAt:0 endingAt:newMessageCount withCompletion:^(BOOL finished)
		{
			[self.refreshControl endRefreshing];
		}];
	}
	// Append new messages to the bottom of existing messages
	else
	{
		NSInteger existingMessageCount = [self.messages count];
		NSInteger newMessageCount = [messages count];
		
		if (newMessageCount > 0)
		{
			[self.messages addObjectsFromArray:messages];
		}
		
		// Insert new messages into the table with completion block
		[self insertNewRowsStartingAt:existingMessageCount endingAt:[self.messages count] withCompletion:^(BOOL finished)
		{
			[self.refreshControl endRefreshing];
			
			// Remove loading indicator from table view
			[self.tableView setTableFooterView:[[UIView alloc] init]];
		}];
	}
	
	// Refresh the first page of messages again after 25 second delay
	if (page == 1)
	{
		[self performSelector:@selector(reloadMessages) withObject:nil afterDelay:25.0];
	}
}

// Return error from MessageModel delegate
- (void)updateMessagesError:(NSError *)error
{
	[self setIsFetchingNextPage:NO];
	
	[self.refreshControl endRefreshing];
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
	// Prevent duplicate or unneeded web service requests
	if (self.isFetchingNextPage || self.isLastPageLoaded)
	{
		return;
	}
	
	// Get the last (maximum) row number from the array of index paths
	long maximumRow = (long)[[indexPaths valueForKeyPath:@"@max.row"] longValue] + 1;
	
	// If the last row is being pre-fetched, then fetch the next batch of messages
	if (maximumRow >= (self.currentPage * MessagesPerPage))
	{
		// Enable the isFetchingNextPage flag
		[self setIsFetchingNextPage:YES];
		
		// Increment the current page
		self.currentPage++;
		
		// Fetch the next page of messages
		[self loadMessages:self.currentPage];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
    		[self.tableView setTableFooterView:self.loadingActivityIndicator];
		});
	}
}
#endif


#pragma mark - Med2Med

#ifdef MED2MED
// Reload messages
- (void)loadMessages:(NSInteger)page
{
	[self.sentMessageModel getSentMessages];
	
	// Note: Don't trigger the isFetchingNextPage here (its only used for fetching "next" messages)
}
#endif

@end
