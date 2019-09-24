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

- (IBAction)refreshControlRequest:(id)sender;

@end

@implementation ChatMessagesTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Fix bug in iOS 7+ where text overlaps indicator on first run
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});
	
	// Set current user id
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	self.currentUserID = myProfileModel.ID;
	
	// Initialize ChatMessageModel
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
	
	// Initialize hidden messages
	[self setHiddenChatMessages:[NSMutableArray new]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	[self reloadChatMessages];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Cancel queued chat messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

// Action to perform when refresh control triggered
- (IBAction)refreshControlRequest:(id)sender
{
	// Cancel queued chat messages refresh when user leaves this screen
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self reloadChatMessages];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
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
	
//	NSMutableArray *oldChatMessages = [NSMutableArray new];
//	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
//
//	// Determine if new chat messages should replace any existing chat messages
//	for (ChatMessageModel *newChatMessage in newChatMessages)
//	{
//		// Sort new chat message participant ids
//		NSArray *newChatParticipantIDs = [[newChatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
//
//		for (ChatMessageModel *existingChatMessage in chatMessages)
//		{
//			// Sort existing chat message participant ids
//			NSArray *existingChatParticipantIDs = [[existingChatMessage.ChatParticipants valueForKey:@"ID"] sortedArrayUsingDescriptors:@[sortDescriptor]];
//
//			// If new chat participants matches existing chat participants, then delete the existing chat message
//			if ([newChatParticipantIDs isEqualToArray:existingChatParticipantIDs])
//			{
//				NSLog(@"Chat participants already exist for %@", existingChatMessage.ID);
//
//				// Remove existing chat message from existing chat messages
//				[oldChatMessages addObject:existingChatMessage];
//			}
//		}
//	}
//
//	return [oldChatMessages copy];
}

- (void)hideSelectedChatMessages:(NSArray *)chatMessages
{
	// If no chat messages to hide, cancel
	if ([chatMessages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	// Add each chat message to hidden chat messages
	for (ChatMessageModel *chatMessage in chatMessages)
	{
		[self.hiddenChatMessages addObject:chatMessage];
		
		// Add index path for reloading in the table
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
	}
	
	// Hide rows at specified index paths in the table
	[self reloadRowsAtIndexPaths:indexPaths];
	
	// Toggle the edit button
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == [self.hiddenChatMessages count] ? nil : self.parentViewController.editButtonItem)];
}

// Insert new rows and delete rows at specified index paths in the table
- (void)insertNewRows:(NSArray *)newIndexPaths deleteRows:(NSArray *)deleteIndexPaths withCompletion:(void (^)(BOOL))completion
{
	// Insert new rows and delete rows at specified index paths in the table
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// iOS 11+ - performBatchUpdates: is preferred over beginUpdates and endUpdates (supported in iOS 11+)
		if (@available(iOS 11.0, *))
		{
			[self.tableView performBatchUpdates:^
			{
				[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			}
			completion:completion];
		}
		// iOS 10 - Fall back to using beginUpdates and endUpdates
		else
		{
			[self.tableView beginUpdates];
			
			[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			[self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			
			[self.tableView endUpdates];
			
			completion(YES);
		}
	});
}

// Reload chat messages
- (void)reloadChatMessages
{
	[self.chatMessageModel getChatMessages];
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
		// iOS 10 - Fall back to using beginUpdates and endUpdates
		else
		{
			[self.tableView beginUpdates];
			
			[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			
			[self.tableView endUpdates];
		}
	});
}

- (void)removeSelectedChatMessages:(NSArray *)chatMessages
{
	// If no chat messages to remove, cancel
	if ([chatMessages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSMutableArray *mutableChatMessages = [self.chatMessages mutableCopy];
	
	// Remove each chat message from the source data, selected data, and the table itself
	for (ChatMessageModel *chatMessage in chatMessages)
	{
		[mutableChatMessages removeObject:chatMessage];
		[self.hiddenChatMessages removeObject:chatMessage];
		[self.selectedChatMessages removeObject:chatMessage];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
	}
	
	// Remove selected chat messages from chat messages array
	[self setChatMessages:[mutableChatMessages copy]];
	
	// Remove rows
	if ([self.chatMessages count] > 0 && [self.chatMessages count] > [self.hiddenChatMessages count])
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no chat messages left in the source data, simply reload the table to show the no chat messages cell (deleting the rows as above would result in an inconsistency in which the number of messages in source data (0) does not match the number of rows returned from numberOfRowsInSection: (1 - for the no messages cell))
	else
	{
		[self.tableView reloadData];
		
		// Toggle the edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 || [self.chatMessages count] == [self.hiddenChatMessages count] ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	[self.delegate setSelectedChatMessages:self.selectedChatMessages];
}

- (void)unhideSelectedChatMessages:(NSArray *)chatMessages
{
	// If no chat messages to hide, cancel
	if ([chatMessages count] == 0)
	{
		return;
	}
	
	NSMutableArray *indexPaths = [NSMutableArray new];
	
	// Remove each chat message from hidden chat messages
	for (ChatMessageModel *chatMessage in chatMessages)
	{
		[self.hiddenChatMessages removeObject:chatMessage];
		
		// Add index path for reloading in the table
		[indexPaths addObject:[NSIndexPath indexPathForItem:[self.chatMessages indexOfObject:chatMessage] inSection:0]];
	}
	
	// Hide rows at specified index paths in the table
	[self reloadRowsAtIndexPaths:indexPaths];
	
	// Show the edit button (there will always be at least one message when unhiding)
	[self.parentViewController.navigationItem setRightBarButtonItem:self.parentViewController.editButtonItem];
}

// Return chat messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSArray *)chatMessages
{
	[self setIsLoaded:YES];
	
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
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are chat messages and hidden chat messages and row is not the only row in the table
	if ([self.chatMessages count] > 0 && [self.hiddenChatMessages count] > 0 && (indexPath.row > 0 || [self.chatMessages count] != [self.hiddenChatMessages count]))
	{
		ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
		
		// Hide hidden chat messages by setting the cell's height to 0
		if ([self.hiddenChatMessages containsObject:chatMessage])
		{
			return 0.0f;
		}
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.chatMessages count] == 0 || (indexPath.row == 0 && [self.chatMessages count] == [self.hiddenChatMessages count]))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No chat messages available." : @"Loading...")];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageCell";
	ChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
	
	// Hide hidden chat messages
	if ([self.hiddenChatMessages count] > 0 && [self.hiddenChatMessages containsObject:chatMessage])
	{
		[cell setHidden:YES];
	}
	
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
	//if (indexPath.row % 2) // Only used for testing both styles
	{
		// Show blue bar
		[cell.viewUnopened setHidden:NO];
		
		// Style message
		[cell.labelMessage setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0]];
		[cell.labelMessage setFont:[UIFont boldSystemFontOfSize:cell.labelMessage.font.pointSize]];
	}
	// Set opened/read
	else
	{
		// Hide blue bar
		[cell.viewUnopened setHidden:YES];
		
		// Style message
		[cell.labelMessage setTextColor:cell.labelMessage.textColor];
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
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedChatMessages = [NSMutableArray new];
			
			for (NSIndexPath *indexPath in indexPaths)
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
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedChatMessages = [NSMutableArray new];
			
			for (NSIndexPath *indexPath in indexPaths)
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

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
