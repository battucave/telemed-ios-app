//
//  ChatMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"
#import "ChatMessageXMLParser.h"

@interface ChatMessageModel()

@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) NSMutableArray *failedChatMessages;
@property (nonatomic) BOOL queueCancelled;
@property (nonatomic) BOOL pendingComplete;

@end

@implementation ChatMessageModel

- (void)getChatMessages
{
	[self getChatMessagesByID:nil];
}

- (void)getChatMessagesByID:(NSNumber *)chatMessageID
{
	NSDictionary *parameters = nil;
	
	if (chatMessageID)
	{
		parameters = @{
			@"chatMsgID"	: chatMessageID
		};
	}
	
	[self.operationManager GET:@"ChatMessages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatMessageXMLParser *parser = [[ChatMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			NSMutableArray *chatMessages = [parser chatMessages];
			
			if ([chatMessages count] > 0)
			{
				for(ChatMessageModel *chatMessage in chatMessages)
				{
					// Sort Chat Participants by Last Name, First Name
					chatMessage.ChatParticipants = [chatMessage.ChatParticipants sortedArrayUsingComparator:^NSComparisonResult(ChatParticipantModel *chatParticipantModelA, ChatParticipantModel *chatParticipantModelB)
					{
						return [chatParticipantModelA.FormattedNameLNF compare:chatParticipantModelB.FormattedNameLNF];
					}];
				}
			}
			
			if ([self.delegate respondsToSelector:@selector(updateChatMessages:)])
			{
				[self.delegate updateChatMessages:chatMessages];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Chat Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if ([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
			{
				[self.delegate updateChatMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Chat Messages." andTitle:@"Chat Messages Error"];
		
		// Only handle error if user still on same screen
		if ([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
		{
			[self.delegate updateChatMessagesError:error];
		}
	}];
}

- (void)deleteChatMessage:(NSNumber *)chatMessageID
{
	// Show Activity Indicator
	[self showActivityIndicator:@"Deleting..."];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSDictionary *parameters = @{
		@"chatMsgID"	: chatMessageID,
		@"entireConvo"	: @"true"
	};
	
	[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			if ([self.delegate respondsToSelector:@selector(deleteChatMessageSuccess)])
			{
				[self.delegate deleteChatMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self deleteChatMessage:chatMessageID];
			}];
			
			/* if ([self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
			{
				[self.delegate deleteChatMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		/* if ([self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate deleteChatMessageError:error];
			}];
		}
		else
		{*/
			// Close Activity Indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem deleting the Chat Message." andTitle:@"Chat Message Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self deleteChatMessage:chatMessageID];
		}];
	}];
}

- (void)deleteMultipleChatMessages:(NSArray *)chatMessages
{
	self.failedChatMessages = [[NSMutableArray alloc] init];
	
	if ([chatMessages count] < 1)
	{
		return;
	}
	
	NSLog(@"Delete Multiple Chat Messages");
	
	// Show Activity Indicator
	[self showActivityIndicator:@"Deleting..."];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		NSDictionary *parameters = @{
			@"chatMsgID"	: chatMessage.ID,
			@"entireConvo"	: @"true"
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful Post returns a 204 code with no response
			
			if (operation.response.statusCode != 204)
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Delete Error", NSLocalizedFailureReasonErrorKey, @"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"ChatMessageModel Error: %@", error);
				
				// Add Chat Message to failed Chat Messages
				[self.failedChatMessages addObject:chatMessage];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self chatMessageDeleteQueueFinished];
			}
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error)
		{
			NSLog(@"ChatMessageModel Error: %@", error);
			
			// Handle device offline error
			if (error.code == NSURLErrorNotConnectedToInternet)
			{
				// Cancel further operations to prevent multiple error messages
				[self.operationManager.operationQueue cancelAllOperations];
				self.queueCancelled = YES;
				
				[self chatMessageDeleteQueueFinished];
				
				return;
			}
			
			// Add Chat Message to failed Chat Messages
			[self.failedChatMessages addObject:chatMessage];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self chatMessageDeleteQueueFinished];
			}
		}];
	}
}

- (void)chatMessageDeleteQueueFinished
{
	NSLog(@"Queue Finished: %lu of %d operations failed", (unsigned long)[self.failedChatMessages count], self.totalNumberOfOperations);
	
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// If a failure occurred while deleting Chat Message
	if ([self.failedChatMessages count] > 0)
	{
		NSArray *failedChatMessages = [self.failedChatMessages copy];
	
		// Still being used to reset Chat Messages
		if ([self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesError:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate deleteMultipleChatMessagesError:failedChatMessages];
			}];
		}
		else
		{
			// Close Activity Indicator
			[self hideActivityIndicator];
		}
	
		// Default to all Chat Messages failed to delete
		NSString *errorMessage = @"There was a problem deleting your Chat Messages.";
		
		// Only some Chat Messages failed to delete
		if ([failedChatMessages count] != self.totalNumberOfOperations)
		{
			errorMessage = @"There was a problem deleting some of your Chat Messages.";
		}
		
		// Show error message
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Delete Chat Messages Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self deleteMultipleChatMessages:failedChatMessages];
		}];
	}
	// If request was not cancelled, then it was successful (not currently used)
	else if ( ! self.queueCancelled && [self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesSuccess)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate deleteMultipleChatMessagesSuccess];
		}];
	}
	else
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
	}
	
	// Reset Queue Variables
	self.totalNumberOfOperations = 0;
	self.numberOfFinishedOperations = 0;
	
	[self.failedChatMessages removeAllObjects];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Delete Chat Message has been sent to server
	if ( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(deleteChatMessagePending)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate deleteChatMessagePending];
		}];
	}
	// Notify delegate that Multiple Chat Message Deletions have begun being sent to server (should always run multiple times if needed)
	else if ([self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesPending)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate deleteMultipleChatMessagesPending];
		}];
	}
	else
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
