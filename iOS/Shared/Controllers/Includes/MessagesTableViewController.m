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

@property (nonatomic) UIRefreshControl *savedRefreshControl;
@property (nonatomic) NSArray *messages;
@property (nonatomic) NSMutableArray *filteredMessages;
@property (nonatomic) NSMutableArray *hiddenMessages;
@property (nonatomic) NSMutableArray *selectedMessages;

@property (nonatomic) NSString *messagesType; // Active, Archived, Sent
@property (nonatomic) NSNumber *archiveAccountID;
@property (nonatomic) NSDate *archiveStartDate;
@property (nonatomic) NSDate *archiveEndDate;

@property (nonatomic) BOOL isLoaded;

- (IBAction)refreshControlRequest:(id)sender;

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
	
	// Initialize MessageModel
	#ifdef MYTELEMED
		[self setMessageModel:[[MessageModel alloc] init]];
		[self.messageModel setDelegate:self];
	#endif
	
	// Initialize SentMessageModel
	[self setSentMessageModel:[[SentMessageModel alloc] init]];
	[self.sentMessageModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	[self reloadMessages];
}

// Action to perform when refresh control triggered
- (IBAction)refreshControlRequest:(id)sender
{
	[self reloadMessages];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
	
	[settings synchronize];
}

- (void)initMessagesWithType:(NSString *)newMessagesType
{
	[self setMessages:nil];
	[self setFilteredMessages:nil];
	self.messagesType = newMessagesType;
	
	// If messages type is active, re-enable refresh control
	if ([newMessagesType isEqualToString:@"Active"])
	{
		if (self.refreshControl == nil)
		{
			self.refreshControl = self.savedRefreshControl;
		}
	}
	// If messages type is archives or sent, disable refresh control
	else
	{
		self.savedRefreshControl = self.refreshControl;
		self.refreshControl = nil;
	}
}

// Delegate method from ArchivesViewController
- (void)filterArchiveMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	[self setArchiveAccountID:accountID];
	[self setArchiveStartDate:startDate];
	[self setArchiveEndDate:endDate];
	
	// Don't need to reload messages here because viewWillAppear fires when ArchivesPickerViewController is popped from navigation controller
}

- (void)hideSelectedMessages:(NSArray *)messages
{
	self.hiddenMessages = [NSMutableArray new];
	
	// If no messages to hide, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Add each message to hidden messages
	for (id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages addObject:message];
	}
	
	// Toggle the edit button
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	
	[self.tableView reloadData];
}

- (void)removeSelectedMessages:(NSArray *)messages
{
	NSArray *filteredMessagesCopy = [self.filteredMessages copy];
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSMutableArray *mutableMessages = [self.messages mutableCopy];
	
	// If no messages to remove, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Remove each message from the source data, filtered data, hidden data, selected data, and the table itself
	for (id <MessageProtocol> message in messages)
	{
		[mutableMessages removeObject:message];
		[self.filteredMessages removeObject:message];
		[self.hiddenMessages removeObject:message];
		[self.selectedMessages removeObject:message];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[filteredMessagesCopy indexOfObject:message] inSection:0]];
	}
	
	// Remove selected messages from messages array
	[self setMessages:[mutableMessages copy]];
	
	// Remove rows
	if ([self.filteredMessages count] > 0 && [self.filteredMessages count] > [self.hiddenMessages count])
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no messages left in the source data, simply reload the row to show the no messages cell
	else
	{
		[self.tableView reloadData];
		
		// Toggle the edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == 0 || [self.filteredMessages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	[self.delegate setSelectedMessages:self.selectedMessages];
}

// Reset messages back to loading state
- (void)resetMessages
{
	[self setIsLoaded:NO];
	[self setMessages:[[NSMutableArray alloc] init]];
	
	[self.tableView reloadData];
}

- (void)unHideSelectedMessages:(NSArray *)messages
{
	// If no messages to hide, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Remove each message from hidden messages
	for (id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages removeObject:message];
	}
	
	// Show the edit button (there will always be at least one message when unhiding)
	[self.parentViewController.navigationItem setRightBarButtonItem:self.parentViewController.editButtonItem];
	
	[self.tableView reloadData];
}

// Return messages from MessageModel delegate
- (void)updateMessages:(NSArray *)messages
{
	[self setIsLoaded:YES];
	[self setMessages:messages];
	[self setFilteredMessages:[messages mutableCopy]];

	// If messages type is active, toggle the parent view controller's edit button based on whether there are any filtered messages
	if ([self.messagesType isEqualToString:@"Active"])
	{
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == 0 || [self.filteredMessages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	}

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
	
	[self.refreshControl endRefreshing];
}

// Return error from MessageModel delegate
#ifdef MYTELEMED
- (void)updateMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
	[self.refreshControl endRefreshing];
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}
#endif

// Return sent messages from SentMessageModel delegate
- (void)updateSentMessages:(NSArray *)sentMessages
{
	[self updateMessages:sentMessages];
}

// Return error from SentMessageModel delegate
- (void)updateSentMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
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
	return MAX([self.filteredMessages count], 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are filtered messages and hidden messages and row is not the only row in the table
	if (! [self.messagesType isEqualToString:@"Sent"] && [self.filteredMessages count] > 0 && [self.hiddenMessages count] > 0 && (indexPath.row > 0 || [self.filteredMessages count] != [self.hiddenMessages count]))
	{
		id <MessageProtocol> message = [self.filteredMessages objectAtIndex:indexPath.row];
		
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
	if ([self.filteredMessages count] == 0 || (indexPath.row == 0 && [self.filteredMessages count] == [self.hiddenMessages count]))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No messages available." : @"Loading...")];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"MessageCell";
	MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	id message = [self.filteredMessages objectAtIndex:indexPath.row];
	
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
	// Hide hidden messages
	if ([self.hiddenMessages count] > 0 && [self.hiddenMessages containsObject:message])
	{
		[cell setHidden:YES];
	}
	
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
			messageRecipientNames = [messageRecipientNames stringByAppendingFormat:@" & %lu more...", [messageRecipients count] - 1];
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
	// If there are no filtered messages, then user clicked the no messages cell
	return ([self.filteredMessages count] <= indexPath.row ? nil : indexPath);
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
				[self.selectedMessages addObject:[self.filteredMessages objectAtIndex:indexPath.row]];
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
				[self.selectedMessages addObject:[self.filteredMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedMessages:self.selectedMessages];
		}
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	// If navigating to MessageDetailViewController, but there are no filtered messages, then user clicked the no messages found cell
	if ([identifier isEqualToString:@"showMessageDetail"])
	{
		return ! self.editing && [self.filteredMessages count] > 0;
	}
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMessageDetail"])
	{
		MessageDetailViewController *messageDetailViewController = segue.destinationViewController;
		long selectedRow = [self.tableView indexPathForSelectedRow].row;
		
		if ([self.filteredMessages count] > selectedRow)
		{
			id <MessageProtocol> message = [self.filteredMessages objectAtIndex:selectedRow];
			
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
// Reload messages
- (void)reloadMessages
{
	// Get archived messages
	if ([self.messagesType isEqualToString:@"Archived"])
	{
		[self.messageModel getArchivedMessages:self.archiveAccountID startDate:self.archiveStartDate endDate:self.archiveEndDate];
	}
	// Get sent messages
	else if ([self.messagesType isEqualToString:@"Sent"])
	{
		[self.sentMessageModel getSentMessages];
	}
	// Get active messages
	else
	{
		[self.messageModel getActiveMessages];
	}
}
#endif


#pragma mark - Med2Med

#ifdef MED2MED
// Reload messages
- (void)reloadMessages
{
	[self.sentMessageModel getSentMessages];
}
#endif

@end
