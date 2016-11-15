//
//  MessagesTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessagesTableViewController.h"
#import "MessageDetailViewController.h"
#import "MessageCell.h"
#import "MessageModel.h"

@interface MessagesTableViewController ()

@property (nonatomic) MessageModel *messageModel;

@property (nonatomic) UIRefreshControl *savedRefreshControl;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableArray *filteredMessages;
@property (nonatomic) NSMutableArray *selectedMessages;

@property (nonatomic) int messagesType; // 0 = Active, 1 = Archived
@property (nonatomic) int priorityFilter; // 0 = All, 1 = Stat, 2 = Priority, 3 = Normal
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
	[self setMessageModel:[[MessageModel alloc] init]];
	[self.messageModel setDelegate:self];
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
	if(newMessagesType == 0)
	{
		if(self.refreshControl == nil)
		{
			self.refreshControl = self.savedRefreshControl;
		}
	}
	// If Messages Type is Archives, disable Refresh Control
	else
	{
		self.savedRefreshControl = self.refreshControl;
		self.refreshControl = nil;
	}
}

- (void)filterActiveMessages:(int)newPriorityFilter
{
	NSString *priorityString = nil;
	
	[self.filteredMessages removeAllObjects];
	
	switch(newPriorityFilter)
	{
		// Stat
		case 1:
			priorityString = @"Stat";
			break;
		
		// Priority
		case 2:
			priorityString = @"Priority";
			break;
		
		// Normal
		case 3:
			priorityString = @"Normal";
			break;
	}
	
	// If Priority set
	if(priorityString != nil)
	{
		for(MessageModel *message in self.messages)
		{
			if([message.Priority isEqualToString:priorityString])
			{
				[self.filteredMessages addObject:message];
			}
		}
	}
	// If Priority All or not set
	else
	{
		[self setFilteredMessages:[self.messages mutableCopy]];
	}
	
	// If Messages Type is Active, toggle the parent ViewController's Edit button based on whether there are any Filtered Messages
	if(self.messagesType == 0)
	{
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
	}
	
	[self setPriorityFilter:newPriorityFilter];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Delegate method from ArchivesViewController
- (void)filterArchiveMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	[self setArchiveAccountID:accountID];
	[self setArchiveStartDate:startDate];
	[self setArchiveEndDate:endDate];
	
	// Don't need to Reload Messages here because viewWillAppear fires when ArchivesPickerViewController is popped from Navigation Controller
}

- (void)removeSelectedMessages:(NSArray *)messages
{
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSArray *filteredMessagesCopy = [NSArray arrayWithArray:[self.filteredMessages copy]];
	
	// If no Messages to remove, cancel
	if(messages == nil || [messages count] == 0)
	{
		return;
	}
	
	// Remove each Message from the source data, selected data, and the table itself
	for(MessageModel *message in messages)
	{
		[self.filteredMessages removeObject:message];
		[self.selectedMessages removeObject:message];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[filteredMessagesCopy indexOfObject:message] inSection:0]];
	}
	
	// Remove rows
	if([self.filteredMessages count] > 0)
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no Messages left in the source data, reload the table to show the No Messages cell (deleting the rows as above would result in an inconsistency in which the number of messages in source data (0) does not match the number of rows returned from the numberOfRowsInSection method (1 - for the No Messages cell))
	else
	{
		[self.tableView reloadData];
		
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.filteredMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	[self.delegate setSelectedMessages:self.selectedMessages];
}

// Reset Messages back to loading
- (void)resetMessages
{
	[self setIsLoaded:NO];
	[self setMessages:[[NSMutableArray alloc] init]];
	
	[self.tableView reloadData];
}

// Check Messages
- (void)reloadMessages
{
	// Get Archived Messages
	if(self.messagesType == 1)
	{
		[self.messageModel getArchivedMessages:self.archiveAccountID startDate:self.archiveStartDate endDate:self.archiveEndDate];
	}
	// Get Active Messages
	else
	{
		[self.messageModel getActiveMessages];
	}
}

// Return Messages from MessageModel delegate
- (void)updateMessages:(NSMutableArray *)messages
{
	[self setIsLoaded:YES];
	[self setMessages:messages];
	
	[self filterActiveMessages:self.priorityFilter];
	
	[self.refreshControl endRefreshing];
}

// Return error from MessageModel delegate
- (void)updateMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
	[self.refreshControl endRefreshing];
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet/* || error.code == NSURLErrorTimedOut*/)
	{
		return [self.messageModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Messages Error" message:@"There was a problem retrieving your Messages. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.filteredMessages count] == 0)
	{
		return 1;
	}
	
	return [self.filteredMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.filteredMessages count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"MessageCell";
	MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	MessageModel *message = [self.filteredMessages objectAtIndex:indexPath.row];
	
	// Set Date and Time
	if(message.TimeReceived_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:message.TimeReceived_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if(dateTime == nil)
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
	
	// Set Name, Phone Number, and Message
	[cell.labelName setText:message.SenderName];
	[cell.labelPhoneNumber setText:message.SenderContact];
	[cell.labelMessage setText:message.FormattedMessageText];
	
	// If Message has been read, change Status image to Unread icon
	if([message.State isEqualToString:@"Unread"])
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Unread"]];
	}
	else
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Read"]];
	}
	
	/*/ TESTING ONLY (used for generating Screenshots)
	#if defined(DEBUG)
	[cell.labelName setText:@"TeleMed"];
	[cell.labelPhoneNumber setText:@"800-420-4695"];
	[cell.labelMessage setText:@"Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details."];
	
	if(indexPath.row < 3)
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Unread"]];
	}
	else
	{
		[cell.imageStatus setImage:[UIImage imageNamed:@"icon-Mail-Read"]];
	}
	#endif
	// END TESTING ONLY*/
	
	// Set Message Priority color
	if([message.Priority isEqualToString:@"Priority"])
	{
		[cell.viewPriority setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:199.0/255.0 blue:48.0/255.0 alpha:1]];
	}
	else if([message.Priority isEqualToString:@"Stat"])
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
	if([self.filteredMessages count] == 0)
	{
		return;
	}
	// If in editing mode, toggle the Archive button in MessagesViewController
	else if(self.editing)
	{
		if([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
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
	if(self.editing)
	{
		if([self.delegate respondsToSelector:@selector(setSelectedMessages:)])
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
	if([identifier isEqualToString:@"showMessageDetail"])
	{
		return ! self.editing && [self.filteredMessages count] > 0;
	}
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:@"showMessageDetail"])
	{
		MessageDetailViewController *messageDetailViewController = segue.destinationViewController;
		
		if([self.filteredMessages count] > [self.tableView indexPathForSelectedRow].row)
		{
			MessageModel *message = [self.filteredMessages objectAtIndex:[self.tableView indexPathForSelectedRow].row];
			
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

@end
