//
//  ChatMessagesTableViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/29/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessagesTableViewController.h"
#import "ChatMessageDetailViewController.h"
#import "ChatMessageCell.h"
#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"
#import "MyProfileModel.h"

@interface ChatMessagesTableViewController ()

@property (nonatomic) ChatMessageModel *chatMessageModel;
@property (nonatomic) MyProfileModel *myProfileModel;

@property (nonatomic) NSMutableArray *chatMessages;
@property (nonatomic) NSMutableArray *selectedChatMessages;

@property (nonatomic) BOOL isLoaded;

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
	
	// Initialize Chat Message Model
	[self setChatMessageModel:[[ChatMessageModel alloc] init]];
	[self.chatMessageModel setDelegate:self];
	
	// Initialize My Profile Model
	[self setMyProfileModel:[MyProfileModel sharedInstance]];
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

// Check Chat Messages
- (void)reloadChatMessages
{
	[self.chatMessageModel getChatMessages];
}

- (void)removeSelectedChatMessages:(NSArray *)chatMessages
{
	NSMutableArray *indexPaths = [NSMutableArray new];
	NSArray *chatMessagesCopy = [NSArray arrayWithArray:[self.chatMessages copy]];
	
	// If no Chat Messages to remove, cancel
	if(chatMessages == nil || [chatMessages count] == 0)
	{
		return;
	}
	
	// Remove each Chat Message from the source data, selected data, and the table itself
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		[self.chatMessages removeObject:chatMessage];
		[self.selectedChatMessages removeObject:chatMessage];
		
		[indexPaths addObject:[NSIndexPath indexPathForItem:[chatMessagesCopy indexOfObject:chatMessage] inSection:0]];
	}
	
	// Remove rows
	if([self.chatMessages count] > 0)
	{
		[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	// If there are no Chat Messages left in the source data, reload the table to show the No Messages cell (deleting the rows as above would result in an inconsistency in which the number of messages in source data (0) does not match the number of rows returned from the numberOfRowsInSection method (1 - for the No Messages cell))
	else
	{
		[self.tableView reloadData];
		
		[self.parentViewController.navigationItem setRightBarButtonItem:([self.chatMessages count] == 0 ? nil : self.parentViewController.editButtonItem)];
	}
	
	// Update delegate's list of selected messages
	[self.delegate setSelectedChatMessages:self.selectedChatMessages];
}

// Return Chat Messages from ChatMessageModel delegate
- (void)updateChatMessages:(NSMutableArray *)chatMessages
{
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
	[self.chatMessageModel showError:error];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.chatMessages count] == 0)
	{
		return 1;
	}
	
	return [self.chatMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.chatMessages count] == 0)
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
	
	// Set Participants
	if(chatMessage.ChatParticipants)
	{
		// Remove self from Chat Participants
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID != %@", self.myProfileModel.ID];
		NSArray *chatParticipants = [chatMessage.ChatParticipants filteredArrayUsingPredicate:predicate];
		
		NSString *chatParticipantNames = @"";
		NSInteger chatParticipantsCount = [chatParticipants count];
		
		// Format Chat Participant Names
		if(chatParticipantsCount > 0)
		{
			ChatParticipantModel *chatParticipant = [chatParticipants objectAtIndex:0];
			
			if(chatParticipantsCount > 1)
			{
				chatParticipantNames = [chatParticipant.LastName stringByAppendingFormat:@" & %ld more...", (long)chatParticipantsCount - 1];
			}
			else
			{
				chatParticipantNames = chatParticipant.FormattedNameLNF;
			}
		}
		
		[cell.labelChatParticipants setText:chatParticipantNames];
	}
	
	// Set Date and Time
	if(chatMessage.TimeSent_LCL)
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
	if(chatMessage.Unopened)
	//if(indexPath.row % 2) // Only used for testing both styles
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
	if([self.chatMessages count] == 0)
	{
		return;
	}
	// If in editing mode, toggle the Delete button in ChatMessagesViewController
	else if(self.editing)
	{
		if([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
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
	if(self.editing)
	{
		if([self.delegate respondsToSelector:@selector(setSelectedChatMessages:)])
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
	if([identifier isEqualToString:@"showChatMessageDetail"])
	{
		return ! self.editing && [self.chatMessages count] > 0;
	}
	
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:@"showChatMessageDetail"])
	{
		ChatMessageDetailViewController *chatMessageDetailViewController = segue.destinationViewController;
		
		if([self.chatMessages count] > [self.tableView indexPathForSelectedRow].row)
		{
			ChatMessageModel *chatMessage = [self.chatMessages objectAtIndex:[self.tableView indexPathForSelectedRow].row];
			
			NSLog(@"Get Chat Message Detail");
			NSLog(@"ID: %@", chatMessage.ID);
			NSLog(@"Text: %@", chatMessage.Text);
			NSLog(@"SenderID: %@", chatMessage.SenderID);
			NSLog(@"Unopened: %@", (chatMessage.Unopened ? @"Yes" : @"No"));
			NSLog(@"TimeSent_LCL: %@", chatMessage.TimeSent_LCL);
			NSLog(@"TimeSent_UTC: %@", chatMessage.TimeSent_UTC);
	 
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
