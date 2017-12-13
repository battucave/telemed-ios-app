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
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableArray *filteredMessages;
@property (nonatomic) NSMutableArray *hiddenMessages;
@property (nonatomic) NSMutableArray *selectedMessages;

@property (nonatomic) int messagesType; // 0 = Active, 1 = Archived, 2 = Sent
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
	
	// Fix bug in iOS 7 where text overlaps indicator on first run
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});
	
	// Initialize Message Model
	#ifdef MYTELEMED
		[self setMessageModel:[[MessageModel alloc] init]];
		[self.messageModel setDelegate:self];
	#endif
	
	// Initialize Sent Message Model
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

// Action to perform when Refresh Control triggered
- (IBAction)refreshControlRequest:(id)sender
{
	[self reloadMessages];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:@"swipeMessageDisabled"];
	
	[settings synchronize];
}

- (void)initMessagesWithType:(int)newMessagesType
{
	[self setMessages:nil];
	[self setFilteredMessages:nil];
	self.messagesType = newMessagesType;
	
	// If Messages Type is Active, re-enable Refresh Control
	if (newMessagesType == 0)
	{
		if (self.refreshControl == nil)
		{
			self.refreshControl = self.savedRefreshControl;
		}
	}
	// If Messages Type is Archives or Sent, disable Refresh Control
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
	
	// Don't need to Reload Messages here because viewWillAppear fires when ArchivesPickerViewController is popped from Navigation Controller
}

- (void)hideSelectedMessages:(NSArray *)messages
{
	self.hiddenMessages = [NSMutableArray new];
	
	// If no Messages to hide, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Add each Message to Hidden Messages
	for(id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages addObject:message];
	}
	
	// Toggle the Edit button
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	
	[self.tableView reloadData];
}

- (void)unHideSelectedMessages:(NSArray *)messages
{
	// If no Messages to hide, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Remove each Message from Hidden Messages
	for(id <MessageProtocol> message in messages)
	{
		[self.hiddenMessages removeObject:message];
	}
	
	// Show the Edit button (there will always be at least one Message when unhiding)
	[self.parentViewController.navigationItem setRightBarButtonItem:self.parentViewController.editButtonItem];
	
	[self.tableView reloadData];
}

- (void)removeSelectedMessages:(NSArray *)messages
{
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSArray *filteredMessagesCopy = [NSArray arrayWithArray:[self.filteredMessages copy]];
	
	// If no Messages to remove, cancel
	if (messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Remove each Message from the source data, filtered data, hidden data, selected data, and the table itself
	for(id <MessageProtocol> message in messages)
	{
		[self.messages removeObject:message];
		[self.filteredMessages removeObject:message];
		[self.hiddenMessages removeObject:message];
		[self.selectedMessages removeObject:message];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[filteredMessagesCopy indexOfObject:message] inSection:0]];
	}
	
	// Remove rows
	if ([self.filteredMessages count] > 0 && [self.filteredMessages count] > [self.hiddenMessages count])
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no Messages left in the source data, simply reload the row to show the No Messages cell
	else
	{
		[self.tableView reloadData];
		
		// Toggle the Edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == 0 || [self.filteredMessages count] == [self.hiddenMessages count] ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of Selected Messages
	[self.delegate setSelectedMessages:self.selectedMessages];
}

// Reset Messages back to Loading state
- (void)resetMessages
{
	[self setIsLoaded:NO];
	[self setMessages:[[NSMutableArray alloc] init]];
	
	[self.tableView reloadData];
}

// Return Messages from MessageModel delegate
- (void)updateMessages:(NSMutableArray *)messages
{
	[self setIsLoaded:YES];
	[self setMessages:messages];
	[self setFilteredMessages:messages];

	// If Messages Type is Active, toggle the parent ViewController's Edit button based on whether there are any Filtered Messages
	if (self.messagesType == 0)
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

// Return Sent Messages from SentMessageModel delegate
- (void)updateSentMessages:(NSMutableArray *)sentMessages
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
	if ([self.filteredMessages count] == 0)
	{
		return 1;
	}
	
	return [self.filteredMessages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are Filtered Messages and Hidden Messages and row is not the only row in the table
	if (self.messagesType != 2 && [self.filteredMessages count] > 0 && [self.hiddenMessages count] > 0 && (indexPath.row > 0 || [self.filteredMessages count] != [self.hiddenMessages count]))
	{
		id <MessageProtocol> message = [self.filteredMessages objectAtIndex:indexPath.row];
		
		// Hide Hidden Messages by setting its height to 0
		if ([self.hiddenMessages containsObject:message])
		{
			return 0.0f;
		}
	}
	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.filteredMessages count] == 0 || (indexPath.row == 0 && [self.filteredMessages count] == [self.hiddenMessages count]))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"MessageCell";
	MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	id message = [self.filteredMessages objectAtIndex:indexPath.row];
	
	// Sent Messages
	if (self.messagesType == 2)
	{
		return [self cellForSentMessage:cell withMessage:message atIndexPath:indexPath];
	}
	// Active and Archived Messages
	else
	{
		return [self cellForReceivedMessage:cell withMessage:message atIndexPath:indexPath];
	}
}

- (UITableViewCell *)cellForReceivedMessage:(MessageCell *)cell withMessage:(id <MessageProtocol>)message atIndexPath:(NSIndexPath *)indexPath
{
	// Hide Hidden Messages
	if ([self.hiddenMessages count] > 0 && [self.hiddenMessages containsObject:message])
	{
		[cell setHidden:YES];
	}
	
	// Set Name, Phone Number, and Message
	[cell.labelName setText:message.SenderName];
	[cell.labelPhoneNumber setText:message.SenderContact];
	[cell.labelMessage setText:message.FormattedMessageText];
	
	// Set Date and Time
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
	
	// If Message has been read, change Status image to Unread icon
	if ([message.State isEqualToString:@"Unread"])
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Unread"]];
	}
	else
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Read"]];
	}
	
	/*/ TESTING ONLY (used for generating Screenshots)
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
	
	// Set Message Priority color
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
	// Set Name, Phone Number, and Message
	[cell.labelName setText:[sentMessage.Recipients stringByReplacingOccurrencesOfString:@";" withString:@"; "]];
	[cell.labelPhoneNumber setText:@""];
	[cell.labelMessage setText:sentMessage.FormattedMessageText];
	
	// Set Date and Time
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
	
	// Hide Status image
	[cell.imageStatus setHidden:YES];
	[cell.constraintNameLeadingSpace setConstant:7.0f];
	
	// Set Message Priority color
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are no Filtered Messages, then user clicked the No Messages found cell so do nothing
	if ([self.filteredMessages count] == 0)
	{
		return;
	}
	// If in editing mode, toggle the Archive button in MessagesViewController
	else if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedMessages = [NSMutableArray new];
			
			for(NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedMessages addObject:[self.filteredMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedMessages:self.selectedMessages];
		}
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the Archive button in MessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedMessages = [NSMutableArray new];
			
			for(NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedMessages addObject:[self.filteredMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedMessages:self.selectedMessages];
		}
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	// If navigating to Message Detail, but there are no Filtered Messages, then user clicked the No Messages found cell
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
		
		if ([self.filteredMessages count] > [self.tableView indexPathForSelectedRow].row)
		{
			id <MessageProtocol> message = [self.filteredMessages objectAtIndex:[self.tableView indexPathForSelectedRow].row];
			
			[message setMessageType:self.messagesType];
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
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
// Reload Messages
- (void)reloadMessages
{
	switch (self.messagesType)
	{
		// Get Archived Messages
		case 1:
			[self.messageModel getArchivedMessages:self.archiveAccountID startDate:self.archiveStartDate endDate:self.archiveEndDate];
			break;
		
		// Get Sent Messages
		case 2:
			[self.sentMessageModel getSentMessages];
			break;
			
		// Get Active Messages
		case 0:
		default:
			[self.messageModel getActiveMessages];
			break;
	}
}
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED
// Reload Messages
- (void)reloadMessages
{
	[self.sentMessageModel getSentMessages];
}
#endif

@end
