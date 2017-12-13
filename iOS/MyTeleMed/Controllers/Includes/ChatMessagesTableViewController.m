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
	
	// Fix bug in iOS 7 where text overlaps indicator on first run
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});
	
	// Set Current User ID
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	self.currentUserID = myProfileModel.ID;
	
	// Initialize Chat Message Model
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	[self reloadChatMessages];
}

// Action to perform when Refresh Control triggered
- (IBAction)refreshControlRequest:(id)sender
{
	[self reloadChatMessages];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:@"swipeMessageDisabled"];
	
	[settings synchronize];
}

// Reload Chat Messages
- (void)reloadChatMessages
{
	[self.chatMessageModel getChatMessages];
}

- (void)hideSelectedChatMessages:(NSArray *)chatMessages
{
	self.hiddenChatMessages = [NSMutableArray new];
	
	// If no Chat Messages to hide, cancel
	if (chatMessages == nil || [chatMessages count] == 0)
	{
		return;
	}
	
	// Add each Chat Message to Hidden Chat Messages
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		[self.hiddenChatMessages addObject:chatMessage];
	}
	
	// Toggle the Edit button
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == [self.hiddenChatMessages count] ? nil : self.parentViewController.editButtonItem)];
	
	[self.tableView reloadData];
}

- (void)unHideSelectedChatMessages:(NSArray *)chatMessages
{
	// If no Chat Messages to hide, cancel
	if (chatMessages == nil || [chatMessages count] == 0)
	{
		return;
	}
	
	// Remove each Chat Message from Hidden Chat Messages
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		[self.hiddenChatMessages removeObject:chatMessage];
	}
	
	// Show the Edit button (there will always be at least one Message when unhiding)
	[self.parentViewController.navigationItem setRightBarButtonItem:self.parentViewController.editButtonItem];
	
	[self.tableView reloadData];
}

- (void)removeSelectedChatMessages:(NSArray *)chatMessages
{
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSArray *chatMessagesCopy = [NSArray arrayWithArray:[self.chatMessages copy]];
	
	// If no Chat Messages to remove, cancel
	if (chatMessages == nil || [chatMessages count] == 0)
	{
		return;
	}
	
	// Remove each Chat Message from the source data, selected data, and the table itself
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		[self.chatMessages removeObject:chatMessage];
		[self.hiddenChatMessages removeObject:chatMessage];
		[self.selectedChatMessages removeObject:chatMessage];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[chatMessagesCopy indexOfObject:chatMessage] inSection:0]];
	}
	
	// Remove rows
	if ([self.chatMessages count] > 0 && [self.chatMessages count] > [self.hiddenChatMessages count])
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no Chat Messages left in the source data, simply reload the table to show the No Messages cell (deleting the rows as above would result in an inconsistency in which the number of messages in source data (0) does not match the number of rows returned from the numberOfRowsInSection method (1 - for the No Messages cell))
	else
	{
		[self.tableView reloadData];
		
		// Toggle the Edit button
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 || [self.chatMessages count] == [self.hiddenChatMessages count] ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	[self.delegate setSelectedChatMessages:self.selectedChatMessages];
}

// Return Chat Messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSMutableArray *)chatMessages
{
	// Sort Chat Messages by Date Descending
	if ([chatMessages count] > 0)
	{
		chatMessages = [[chatMessages sortedArrayUsingComparator:^NSComparisonResult(ChatMessageModel *chatMessageModelA, ChatMessageModel *chatMessageModelB)
		{
			return [chatMessageModelB.TimeSent_UTC compare:chatMessageModelA.TimeSent_UTC];
		}] mutableCopy];
	}
	
	[self setIsLoaded:YES];
	[self setChatMessages:chatMessages];
	
	[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView reloadData];
	});
	
	[self.refreshControl endRefreshing];
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
	if ([self.chatMessages count] == 0)
	{
		return 1;
	}
	
	return [self.chatMessages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are Chat Messages and Hidden Chat Messages and row is not the only row in the table
	if ([self.chatMessages count] > 0 && [self.hiddenChatMessages count] > 0 && (indexPath.row > 0 || [self.chatMessages count] != [self.hiddenChatMessages count]))
	{
		ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
		
		// Hide Hidden Chat Messages by setting its height to 0
		if ([self.hiddenChatMessages containsObject:chatMessage])
		{
			return 0.0f;
		}
	}
	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.chatMessages count] == 0 || (indexPath.row == 0 && [self.chatMessages count] == [self.hiddenChatMessages count]))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? @"No chat messages found." : @"Loading...")];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"ChatMessageCell";
	ChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
	
	// Hide Hidden Chat Messages
	if ([self.hiddenChatMessages count] > 0 && [self.hiddenChatMessages containsObject:chatMessage])
	{
		[cell setHidden:YES];
	}
	
	// Set Participants
	if (chatMessage.ChatParticipants)
	{
		// Remove self from Chat Participants
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID != %@", self.currentUserID];
		NSArray *chatParticipants = [chatMessage.ChatParticipants filteredArrayUsingPredicate:predicate];
		
		NSString *chatParticipantNames = @"";
		NSInteger chatParticipantsCount = [chatParticipants count];
		
		// Format Chat Participant Names
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
	
	// Set Date and Time
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
	
	// Set Message
	[cell.labelMessage setText:chatMessage.Text];
	
	// Set Unopened/Unread
	if (chatMessage.Unopened)
	//if (indexPath.row % 2) // Only used for testing both styles
	{
		// Show blue bar
		[cell.viewUnopened setHidden:NO];
		
		// Style Message
		[cell.labelMessage setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0]];
		[cell.labelMessage setFont:[UIFont boldSystemFontOfSize:cell.labelMessage.font.pointSize]];
	}
	// Set Opened/Read
	else
	{
		// Hide blue bar
		[cell.viewUnopened setHidden:YES];
		
		// Style Message
		[cell.labelMessage setTextColor:cell.labelMessage.textColor];
		[cell.labelMessage setFont:[UIFont systemFontOfSize:cell.labelMessage.font.pointSize]];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are no Chat Messages, then user clicked the No Chat Messages found cell so do nothing
	if ([self.chatMessages count] == 0)
	{
		return;
	}
	// If in editing mode, toggle the Delete button in ChatMessagesViewController
	else if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedChatMessages = [NSMutableArray new];
			
			for(NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedChatMessages addObject:[self.chatMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedChatMessages:self.selectedChatMessages];
		}
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If in editing mode, toggle the Delete button in ChatMessagesViewController
	if (self.editing)
	{
		if ([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
		{
			NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
			self.selectedChatMessages = [NSMutableArray new];
			
			for(NSIndexPath *indexPath in indexPaths)
			{
				[self.selectedChatMessages addObject:[self.chatMessages objectAtIndex:indexPath.row]];
			}
			
			[self.delegate setSelectedChatMessages:self.selectedChatMessages];
		}
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	// If navigating to Message Detail, but there are no Chat Messages, then user clicked the No Chat Messages found cell
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
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
