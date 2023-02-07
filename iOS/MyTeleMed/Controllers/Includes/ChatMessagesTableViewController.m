//
//  ChatMessagesTableViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/29/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessagesTableViewController.h"
#import "ChatMessageDetailViewController.h"
#import "ErrorAlertController.h"
#import "ChatMessageCell.h"
#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"
#import "MyProfileModel.h"

@interface ChatMessagesTableViewController ()

@property (nonatomic) ChatMessageModel *chatMessageModel;

@property (nonatomic) BOOL isLoaded;

@property (nonatomic) NSMutableArray *hiddenChatMessages;
@property (nonatomic) NSMutableArray *selectedChatMessages;
@property (nonatomic) NSNumber *currentUserID;

@end

@implementation ChatMessagesTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Fix bug where text overlaps indicator on first run
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});
	
	// Set current user id
	MyProfileModel *myProfileModel = MyProfileModel.sharedInstance;
	self.currentUserID = myProfileModel.ID;
	
	// Initialize ChatMessageModel
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
	
	// Initialize hidden and selected chat messages
	[self setHiddenChatMessages:[NSMutableArray new]];
	[self setSelectedChatMessages:[NSMutableArray new]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Always reload messages to ensure that any new messages are fetched from server when user returns to this screen
	[self reloadChatMessages];
	
	// Add application did become active observer to reload chat messages when this screen is visible
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reloadChatMessages) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove application did become active observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

// Action to perform when refresh control triggered
- (IBAction)refreshControlRequest:(id)sender
{	
	[self reloadChatMessages];
	
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
	
	[settings synchronize];
}

// Compare chat messages to existing chat messages to determine which chat messages are new
- (NSArray *)computeNewChatMessages:(NSArray *)newChatMessages from:(NSArray *)chatMessages
{
	// Use NSSet's minusSet: to determine which messages are new
	NSSet *existingChatMessagesSet = [NSSet setWithArray:chatMessages];
	NSMutableSet *newChatMessagesSet = [NSMutableSet setWithArray:newChatMessages];

	[newChatMessagesSet minusSet:existingChatMessagesSet];

	// Convert NSMutableSet back into NSArray
	return [newChatMessagesSet allObjects];
}

// Compare existing chat messages to new chat messages to determine which existing chat messages should be replaced by new chat messages
- (NSArray *)computeOldChatMessages:(NSArray *)newChatMessages from:(NSArray *)chatMessages
{
	// Use NSSet's minusSet: to determine which messages should be replaced
	NSSet *newChatMessagesSet = [NSSet setWithArray:newChatMessages];
	NSMutableSet *oldChatMessagesSet = [NSMutableSet setWithArray:chatMessages];
	
	[oldChatMessagesSet minusSet:newChatMessagesSet];
	
	// Convert NSMutableSet back into NSArray
	return [oldChatMessagesSet allObjects];
}

// Insert new rows and delete rows at specified index paths in the table
- (void)insertNewRows:(NSArray *)newIndexPaths deleteRows:(NSArray *)deleteIndexPaths withCompletion:(void (^)(BOOL))completion
{
	// Insert new rows and delete rows at specified index paths in the table
	dispatch_async(dispatch_get_main_queue(), ^
	{
        [self.tableView performBatchUpdates:^
        {
            [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        completion:completion];
	});
}

// Reload chat messages
- (void)reloadChatMessages
{
	[self.chatMessageModel getChatMessages];
}

// Remove selected chat messages
- (void)removeSelectedChatMessages:(NSArray *)chatMessages
{
	// If no chat messages to remove, cancel
	if ([chatMessages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	// Add the index path for each chat message to be removed
	for (ChatMessageModel *chatMessage in chatMessages)
	{
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
	}
	
	// Remove chat messages from source data
	NSMutableArray *mutableChatMessages = [self.chatMessages mutableCopy];
	
	[mutableChatMessages removeObjectsInArray:chatMessages];
	[self setChatMessages:[mutableChatMessages copy]];
	
	// Remove chat messages from selected data
	[self.selectedChatMessages removeObjectsInArray:chatMessages];
	
	// Add chat messages to hidden data
	[self.hiddenChatMessages addObjectsFromArray:chatMessages];
	
	// If there are no chat messages left in the source data, simply reload the table to show the no chat messages cell (deleting the rows as above would result in an inconsistency in which the number of messages in source data (0) does not match the number of rows returned from numberOfRowsInSection: (1 - for the no messages cell))
	if ([self.chatMessages count] == 0)
	{
		[self resetChatMessages:NO];
		
		// Toggle the parent view controller's edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
	}
	// Remove rows
	else
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	
	// Update delegate's list of selected messages
	if ([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
	{
		[self.delegate setSelectedChatMessages:self.selectedChatMessages];
	}
}

// Reset chat messages back to loading state
- (void)resetChatMessages:(BOOL)resetHidden
{
	self.chatMessages = [NSMutableArray new];
	[self.selectedChatMessages removeAllObjects];
	
	// Additionally reset hidden chat messages
	if (resetHidden)
	{
		[self.hiddenChatMessages removeAllObjects];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
}

// Return chat messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSArray *)chatMessages
{
	[self setIsLoaded:YES];
	
	// Filter out chat messages that have been archived locally, but are still pending web service response
	if ([self.hiddenChatMessages count] > 0)
	{
		chatMessages = [self computeNewChatMessages:chatMessages from:self.hiddenChatMessages];
	}
	
	// Set initial chat messages if empty
	if ([self.chatMessages count] == 0)
	{
		[self setChatMessages:chatMessages];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableView reloadData];
			
			[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
			
			[self.refreshControl endRefreshing];
		});
	}
	// Add new chat messages resulting from a reload to the top of existing chat messages
	else
	{
		// Extract out new chat messages that don't exist in the existing chat messages
		NSArray *newChatMessages = [self computeNewChatMessages:chatMessages from:self.chatMessages];
		NSInteger newChatMessageCount = [newChatMessages count];
		
		// Extract out old chat messages that no longer exist in the chat messages
		NSArray *oldChatMessages = [self computeOldChatMessages:chatMessages from:self.chatMessages];
		NSInteger oldChatMessageCount = [oldChatMessages count];
		
		if (newChatMessageCount > 0 || oldChatMessageCount > 0)
		{
			NSMutableArray *deleteIndexPaths = [NSMutableArray new];
			NSMutableArray *newIndexPaths = [NSMutableArray new];
			
			// Add index path for deletion from table
			for (ChatMessageModel *oldChatMessage in oldChatMessages)
			{
				[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[self.chatMessages indexOfObject:oldChatMessage] inSection:0]];
			}
			
			[self setChatMessages:chatMessages];
			
			// Add index path for insertion into table
			for (ChatMessageModel *newChatMessage in newChatMessages)
			{
				[newIndexPaths addObject:[NSIndexPath indexPathForRow:[self.chatMessages indexOfObject:newChatMessage] inSection:0]];
			}
			
			// Insert new chat messages into the table, remove old chat messages from the table, and end refreshing
			[self insertNewRows:newIndexPaths deleteRows:deleteIndexPaths withCompletion:^(BOOL finished)
			{
				[self.refreshControl endRefreshing];
			}];
		}
		// End refreshing
		else
		{
			[self.refreshControl endRefreshing];
		}
	}
}

// Return error from ChatMessageModel delegate
- (void)updateChatMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
	[self.refreshControl endRefreshing];
	
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
	return MAX([self.chatMessages count], 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.chatMessages count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// iOS 13+ - Support dark mode
		if (@available(iOS 13.0, *))
		{
			[emptyCell setBackgroundColor:[UIColor clearColor]];
		}
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No chat messages available." : @"Loading...")];
        [emptyCell.textLabel setTextColor:[UIColor whiteColor]];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageCell";
	ChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
	
	// Set chat participants
	if (chatMessage.ChatParticipants)
	{
		// Remove self from chat participants
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID != %@", self.currentUserID];
		NSArray *chatParticipants = [chatMessage.ChatParticipants filteredArrayUsingPredicate:predicate];
		
		NSString *chatParticipantNames = @"";
		NSInteger chatParticipantsCount = [chatParticipants count];
		
		// Format chat participant names
		if (chatParticipantsCount > 0)
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
					// iPhone 6+ can handle more names
					if ([UIScreen mainScreen].bounds.size.width > 320.0f)
					{
						chatParticipantNames = [NSString stringWithFormat:@"%@, %@ & %ld more...", chatParticipant1.LastName, chatParticipant2.LastName, (long)chatParticipantsCount - 2];
					}
					else
					{
						chatParticipantNames = [NSString stringWithFormat:@"%@ & %ld more...", chatParticipant1.LastName, (long)chatParticipantsCount - 2];
					}
					break;
			}
		}
		
		[cell.labelChatParticipants setText:chatParticipantNames];
	}
	
	// Set date and time
	if (chatMessage.TimeSent_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:chatMessage.TimeSent_LCL];
		
		[dateFormatter setDateFormat:@"M/dd/yy"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[dateFormatter setDateFormat:@"h:mm a"];
		NSString *time = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
		[cell.labelTime setText:time];
	}
	
	// Set message
	[cell.labelMessage setText:chatMessage.Text];
	
	// Set unopened/unread
	if (chatMessage.Unopened)
	// if (indexPath.row % 2) // Only used for testing both styles
	{
		// Show blue bar
		[cell.viewUnopened setHidden:NO];
		
		// Style message
		[cell.labelMessage setFont:[UIFont boldSystemFontOfSize:cell.labelMessage.font.pointSize]];
	}
	// Set opened/read
	else
	{
		// Hide blue bar
		[cell.viewUnopened setHidden:YES];
		
		// Style message
		[cell.labelMessage setFont:[UIFont systemFontOfSize:cell.labelMessage.font.pointSize]];
	}
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are no chat messages, then user clicked the no chat messages cell
	return ([self.chatMessages count] <= indexPath.row ? nil : indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the delete button in chat MessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
		{
			NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
			
			[self.selectedChatMessages removeAllObjects];
			
			for (NSIndexPath *indexPath in selectedIndexPaths)
			{
				[self.selectedChatMessages addObject:[self.chatMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedChatMessages:self.selectedChatMessages];
		}
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the delete button in chat MessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
		{
			NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
			
			[self.selectedChatMessages removeAllObjects];
			
			for (NSIndexPath *indexPath in selectedIndexPaths)
			{
				[self.selectedChatMessages addObject:[self.chatMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedChatMessages:self.selectedChatMessages];
		}
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	// If navigating to message detail, but there are no chat messages, then user clicked the no chat messages found cell
	if ([identifier isEqualToString:@"showChatMessageDetail"])
	{
		return ! self.editing && [self.chatMessages count] > 0;
	}
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showChatMessageDetail"])
	{
		ChatMessageDetailViewController *chatMessageDetailViewController = segue.destinationViewController;
		
		if ([self.chatMessages count] > [self.tableView indexPathForSelectedRow].row)
		{
			ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:[self.tableView indexPathForSelectedRow].row];
			
			[chatMessageDetailViewController setIsNewChat:NO];
			[chatMessageDetailViewController setConversationID:chatMessage.ID];
		}
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
