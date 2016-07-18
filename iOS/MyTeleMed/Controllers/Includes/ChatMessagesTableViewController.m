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

@interface ChatMessagesTableViewController ()

@property (nonatomic) ChatMessageModel *chatMessageModel;

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
		//[self.tableView setEditing:YES animated:YES];
	});
	
	[self.refreshControl endRefreshing];
}

// Return error from ChatMessageModel delegate
- (void)updateChatMessagesError:(NSError *)error
{
	[self setIsLoaded:YES];
	
	[self.refreshControl endRefreshing];
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.chatMessageModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Chat Messages Error" message:@"There was a problem retrieving your Chat Messages. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
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
	// TEMPORARY
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
	
	// Set Date and Time
	if(chatMessage.TimeReceived_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:chatMessage.TimeReceived_LCL];
		
		[dateFormatter setDateFormat:@"M/dd/yy"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[dateFormatter setDateFormat:@"h:mm a"];
		NSString *time = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
		[cell.labelTime setText:time];
	}
	
	// Set Name and Message
	[cell.labelName setText:chatMessage.SenderName];
	[cell.labelMessage setText:chatMessage.Text];
	
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
