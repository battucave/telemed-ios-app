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

#if MYTELEMED
	#import "MessageModel.h"
#endif

@interface MessagesTableViewController ()

#if MYTELEMED
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
	
	// Fix bug where text overlaps indicator on first run
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
	
	// Initialize all and selected messages
	[self setMessages:[NSMutableArray new]];
	[self setSelectedMessages:[NSMutableArray new]];
	
	#if MYTELEMED
		// Initialize MessageModel
		[self setMessageModel:[[MessageModel alloc] init]];
		[self.messageModel setDelegate:self];
		
		// Initialize hidden messages
		[self setHiddenMessages:[NSMutableArray new]];
	
		// Initialize loading activity indicator to be used when loading additional messages
		[self setLoadingActivityIndicator:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];

		// Use custom color from asset catalog with dark mode support
		[self.loadingActivityIndicator setColor:[UIColor colorNamed:@"systemBlackColor"]];
		
		[self.loadingActivityIndicator setFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 60.0)];
		[self.loadingActivityIndicator startAnimating];
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Always reload messages to ensure that any new messages are fetched from server when user returns to this screen
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
	
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
	
	[settings synchronize];
}

// Reload messages
- (void)reloadMessages
{
	[self loadMessages:1];
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
	ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
	
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.messages count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// iOS 13+ - Support dark mode
		if (@available(iOS 13.0, *))
		{
			[emptyCell setBackgroundColor:[UIColor secondarySystemGroupedBackgroundColor]];
		}
		
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
		// If this is the last row, then manually call prefetch rows logic to fetch next batch of messages
		// This should only be triggered after user archives multiple messages, forcing an immediate render of cells that weren't already "prefetched"
		if (indexPath.row + 1 >= [self.messages count])
		{
			[self tableView:tableView prefetchRowsAtIndexPaths:@[indexPath]];
		}
		
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
		// iOS 13+ - Use SF Symbols
		if (@available(iOS 13.0, *))
		{
			[cell.imageStatus setImage:[UIImage systemImageNamed:@"envelope"]];
		}
		// iOS < 13 - Fall back to vector image from asset catalog
		else
		{
			[cell.imageStatus setImage:[UIImage imageNamed:@"envelope"]];
		}
	}
	else
	{
		// iOS 13+ - Use SF Symbols
		if (@available(iOS 13.0, *))
		{
			[cell.imageStatus setImage:[UIImage systemImageNamed:@"envelope.open"]];
		}
		// iOS < 13 - Fall back to vector image from asset catalog
		else
		{
			// Note: image name cannot contain "." as anything after it will be treated as a file extension
			[cell.imageStatus setImage:[UIImage imageNamed:@"envelope-open"]];
		}
	}
	
	/*/ TESTING ONLY (used for generating screenshots)
	#if DEBUG
		[cell.labelName setText:@"TeleMed"];
		[cell.labelPhoneNumber setText:@"800-420-4695"];
		[cell.labelMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
		
		// iOS 13+ - Use SF Symbols
		if (@available(iOS 13.0, *))
		{
			if (indexPath.row < 3)
			{
				[cell.imageStatus setImage:[UIImage systemImageNamed:@"envelope"]];
			}
			else
			{
				[cell.imageStatus setImage:[UIImage systemImageNamed:@"envelope.open"]];
			}
		}
		// iOS < 13 - Fall back to vector image from asset catalog
		else
		{
			if (indexPath.row < 3)
			{
				[cell.imageStatus setImage:[UIImage imageNamed:@"envelope"]];
			}
			else
			{
				// Note: image name cannot contain "." as anything after it will be treated as a file extension
				[cell.imageStatus setImage:[UIImage imageNamed:@"envelope-open"]];
			}
		}
	#endif
	// END TESTING ONLY */
	
	// Set message priority color
	if ([message.Priority isEqualToString:@"Priority"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemYellowColor]];
	}
	else if ([message.Priority isEqualToString:@"Stat"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemRedColor]];
	}
	else
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemGreenColor]];
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
	#if DEBUG
		[cell.labelName setText:@"TeleMed"];
		[cell.labelMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
	#endif
	// END TESTING ONLY */
	
	// Set message priority color
	if ([sentMessage.Priority isEqualToString:@"Priority"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemYellowColor]];
	}
	else if ([sentMessage.Priority isEqualToString:@"Stat"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemRedColor]];
	}
	else
	{
		[cell.viewPriority setBackgroundColor:[UIColor systemGreenColor]];
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
			NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
			
			[self.selectedMessages removeAllObjects];
			
			for (NSIndexPath *indexPath in selectedIndexPaths)
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
			NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
			
			[self.selectedMessages removeAllObjects];
			
			for (NSIndexPath *indexPath in selectedIndexPaths)
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
	[NSNotificationCenter.defaultCenter removeObserver:self];
}


#pragma mark - MyTeleMed

#if MYTELEMED
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop refreshing messages when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

// Compare new messages to existing messages to determine which messages are new
- (NSArray *)computeNewMessages:(NSArray *)newMessages from:(NSArray *)messages
{
	// Use NSSet's minusSet: to determine which messages are new
	NSSet *existingMessagesSet = [NSSet setWithArray:messages];
	NSMutableOrderedSet *newMessagesSet = [NSMutableOrderedSet orderedSetWithArray:newMessages];

	[newMessagesSet minusSet:existingMessagesSet];

	// Convert NSMutableOrderedSet back into NSArray
	return [newMessagesSet array];
}

// Delegate method from ArchivesViewController
- (void)filterArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	[self setArchiveAccountID:accountID];
	[self setArchiveStartDate:startDate];
	[self setArchiveEndDate:endDate];
	
	// Don't need to reload messages here because viewWillAppear fires when ArchivesPickerViewController is popped from navigation controller
}

// Insert new rows at specified index paths in the table
- (void)insertNewRows:(NSArray *)newIndexPaths useAnimation:(BOOL)useAnimation onComplete:(void (^)(BOOL))completion
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
        // Disable animation when appending rows for pagination
        if (! useAnimation)
        {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
        }
        
        [self.tableView performBatchUpdates:^
        {
            [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        completion:^(BOOL finished)
        {
            completion(finished);
            
            // Disable animation when appending rows for pagination
            if (! useAnimation)
            {
                [CATransaction commit];
            }
        }];
	});
}

// Reload messages
- (void)loadMessages:(NSInteger)page
{
	if (! self.isFetchingNextPage)
	{
		// Enable the isFetchingNextPage flag
		[self setIsFetchingNextPage:YES];
		
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
}

// Remove selected messages. Active messages only
- (void)removeSelectedMessages:(NSArray *)messages
{
	// If there are no messages to remove, then stop
	if ([messages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	// Add the index path for each message to be removed
	for (id <MessageProtocol> message in messages)
	{
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.messages indexOfObject:message] inSection:0]];
	}
	
	// Remove messages from source data and selected data
	[self.messages removeObjectsInArray:messages];
	[self.selectedMessages removeObjectsInArray:messages];
	
	// Add messages to hidden data
	[self.hiddenMessages addObjectsFromArray:messages];
	
	// If there are no messages left in the source data or if removing more than one page of messages (25), then reset and reload messages
	// Note: Due to flaw in pagination, removing more than one page of messages would result in skipped messages when loading the next page
	// (See MessagesViewController::modifyMultipleMessagesStatePending: for more info)
	if ([self.messages count] == 0 || [messages count] > MessagesPerPage)
	{
		[self resetMessages:NO];
		
		[self reloadMessages];
	}
	// Remove rows at specified index paths from the table
	else
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
		
		// Due to flaw in pagination, reload current page of messages to backfill any messages that would be skipped when loading the next page
		// (See MessagesViewController::modifyMultipleMessagesStatePending: for more info)
		[self loadMessages:self.currentPage];
		
	}
	
	// Update delegate's list of selected messages
	if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
	{
		[self.delegate setSelectedMessages:self.selectedMessages];
	}
}

// Reset messages back to loading state
- (void)resetMessages:(BOOL)resetHidden
{
	[self setCurrentPage:1];
	[self setIsFirstPageLoaded:NO];
	[self setIsLastPageLoaded:NO];
	[self.messages removeAllObjects];
	[self.selectedMessages removeAllObjects];
	
	// Additionally reset hidden messages
	if (resetHidden)
	{
		[self.hiddenMessages removeAllObjects];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Return messages from MessageModel delegate
- (void)updateMessages:(NSArray *)messages forPage:(NSInteger)page
{
	NSLog(@"UPDATE MESSAGES FOR PAGE: %ld", (long)page);
	
	[self setIsFetchingNextPage:NO];
	[self setIsFirstPageLoaded:YES];
	
	// If the number of messages returned is less than the number of messages per page, then assume the last page has been loaded
	if ([messages count] < MessagesPerPage)
	{
		[self setIsLastPageLoaded:YES];
	}
	
	// Filter out messages that have been archived locally, but are still pending web service response
	if ([self.hiddenMessages count] > 0)
	{
		messages = [self computeNewMessages:messages from:self.hiddenMessages];
	}
	
	// Set initial messages if empty
	if ([self.messages count] == 0)
	{
		// Insert initial messages into the table
		[self setMessages:[messages mutableCopy]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableView reloadData];
			
			// Remove loading indicator from table view
			[self.tableView setTableFooterView:[[UIView alloc] init]];
			
			// If messages type is active
			if ([self.messagesType isEqualToString:@"Active"])
			{
				// Toggle the parent view controller's edit button based on whether there are any messages
				[self.parentViewController.navigationItem setRightBarButtonItem:([self.messages count] == 0 ? nil : self.parentViewController.editButtonItem)];
			}
			
			[self.refreshControl endRefreshing];
		});
	}
	else
	{
		// Extract out new messages that don't exist in the existing messages
		NSArray *newMessages = [self computeNewMessages:messages from:self.messages];
		NSInteger newMessageCount = [newMessages count];
		
		if (newMessageCount > 0)
		{
			NSMutableArray *newIndexPaths = [NSMutableArray new];
			BOOL useAnimation = YES;
			
			// Add new messages resulting from a reload
			if (page == 1)
			{
				for (MessageModel *newMessage in newMessages)
				{
					// Determine where the message should be inserted (usually at the top, but it can be the bottom if user deleted a message from another device)
					NSUInteger newMessageIndex = [messages indexOfObject:newMessage];
					
					// Add the new message to the existing messages
					[self.messages insertObject:newMessage atIndex:newMessageIndex];
					
					// Add index path for row to be added to the table
					[newIndexPaths addObject:[NSIndexPath indexPathForRow:newMessageIndex inSection:0]];
				}
			}
			// Append new messages to the bottom of existing messages
			else
			{
				NSInteger existingMessageCount = [self.messages count];
				
				// Animation messes up the scroll position when appending messages to the bottom
				useAnimation = NO;
				
				// Append new messages to the bottom of existing messages
				[self.messages addObjectsFromArray:newMessages];
				
				for (NSInteger i = existingMessageCount; i < newMessageCount + existingMessageCount; i++)
				{
					// Add index path for row to be added to the table
					[newIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
				}
			}
			
			// Insert new messages into the table
			[self insertNewRows:newIndexPaths useAnimation:useAnimation onComplete:^(BOOL finished)
			{
				// Remove loading indicator from table view
				[self.tableView setTableFooterView:[[UIView alloc] init]];
				
				// End refreshing
				[self.refreshControl endRefreshing];
			}];
		}
		else
		{
			// Remove loading indicator from table view
			[self.tableView setTableFooterView:[[UIView alloc] init]];
			
			// End refreshing
			[self.refreshControl endRefreshing];
		}
	}
}

// Return error from MessageModel delegate
- (void)updateMessagesError:(NSError *)error
{
	[self setIsFetchingNextPage:NO];
	
	// Decrement current page so the previous one can be retried
	self.currentPage--;
	
	[self.refreshControl endRefreshing];
	
	// Show error message
	ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
	
	[errorAlertController show:error];
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
	// Prevent duplicate or unnecessary web service requests
	if (self.isFetchingNextPage || self.isLastPageLoaded)
	{
		return;
	}
	
	// Get the last (maximum) row number from the array of index paths
	long maximumRow = (long)[[indexPaths valueForKeyPath:@"@max.row"] longValue] + 1;
	
	// NSLog(@"PREFETCH ROW AT: %ld", maximumRow);
	// NSLog(@"NEXT FETCH: %ld", [self.messages count]);
	
	// If the last row is being pre-fetched, then fetch the next batch of messages
	if (maximumRow >= [self.messages count])
	{
		[self loadMessages:++self.currentPage];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
    		[self.tableView setTableFooterView:self.loadingActivityIndicator];
		});
	}
}
#endif


#pragma mark - Med2Med

#if MED2MED
// Reload messages
- (void)loadMessages:(NSInteger)page
{
	if (! self.isFetchingNextPage)
	{
		// Enable the isFetchingNextPage flag
		[self setIsFetchingNextPage:YES];
			
		[self.sentMessageModel getSentMessages];
	}
}
#endif

@end
