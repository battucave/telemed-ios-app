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

/*TESTING ONLY (generate test messages)
#if DEBUG
	#import "MyProfileModel.h"
#endif
// END TESTING ONLY */

@interface ChatMessageModel()

@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) NSMutableArray *failedChatMessages;
@property (nonatomic) BOOL queueCancelled;

@end

@implementation ChatMessageModel

- (void)getChatMessages
{
	[self getChatMessagesByID:nil];
}

- (void)getChatMessagesByID:(NSNumber *)chatMessageID
{
	[self getChatMessagesByID:chatMessageID withCallback:nil];
}

- (void)getChatMessagesByID:(NSNumber *)chatMessageID withCallback:(void (^)(BOOL success, NSArray *chatMessages, NSError *error))callback
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
		
		/*/ TESTING ONLY (generate test messages)
        #if DEBUG
            NSMutableArray *xmlMessages = [NSMutableArray new];
            
            for (int i = 1; i < 76; i++)
            {
                NSString *xmlMessage = [NSString stringWithFormat:@"<ChatMessage><ID>%ld</ID><Participants><Person><FirstName>Sender</FirstName><FormattedName>Sender Name</FormattedName><FormattedNameLNF>Name, Sender</FormattedNameLNF><ID>%@</ID><LastName>Name</LastName></Person><Person><FirstName>Person</FirstName><FormattedName>Person %d</FormattedName><FormattedNameLNF>%d, Person</FormattedNameLNF><ID>%d</ID><LastName>%d</LastName></Person></Participants><SenderID>%@</SenderID><Text>Chat Message %d</Text><TimeSent_LCL>2021-06-25T15:19:05.831</TimeSent_LCL><TimeSent_UTC>2021-06-25T19:19:05.831Z</TimeSent_UTC><Unopened>true</Unopened></ChatMessage>",
					(long)10000000 + i,
					MyProfileModel.sharedInstance.ID,
					i,
					i,
					i,
					i,
					MyProfileModel.sharedInstance.ID,
					i
                ];
                
                [xmlMessages addObject:xmlMessage];
            }
            
            NSString *xmlString = [NSString stringWithFormat:@"<ArrayOfChatMessage xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">%@</ArrayOfChatMessage>", [xmlMessages componentsJoinedByString:@""]];
            xmlParser = [[NSXMLParser alloc] initWithData:[xmlString dataUsingEncoding:NSUnicodeStringEncoding]];
        #endif
        // END TESTING ONLY */
        
		ChatMessageXMLParser *parser = [[ChatMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			NSArray *chatMessages;
			
			// Sort chat messages for specific conversation by time sent in ascending order
			if (chatMessageID)
			{
				chatMessages = [parser.chatMessages sortedArrayUsingComparator:^NSComparisonResult(ChatMessageModel *chatMessageModelA, ChatMessageModel *chatMessageModelB)
				{
					return [chatMessageModelA.TimeSent_UTC compare:chatMessageModelB.TimeSent_UTC];
				}];
			}
			// Sort chat messages by time sent in descending order
			else
			{
				chatMessages = [parser.chatMessages sortedArrayUsingComparator:^NSComparisonResult(ChatMessageModel *chatMessageModelA, ChatMessageModel *chatMessageModelB)
				{
					return [chatMessageModelB.TimeSent_UTC compare:chatMessageModelA.TimeSent_UTC];
				}];
			}
			
			if ([chatMessages count] > 0)
			{
				for (ChatMessageModel *chatMessage in chatMessages)
				{
					// Sort chat participants by last name, first name
					chatMessage.ChatParticipants = [chatMessage.ChatParticipants sortedArrayUsingComparator:^NSComparisonResult(ChatParticipantModel *chatParticipantModelA, ChatParticipantModel *chatParticipantModelB)
					{
						return [chatParticipantModelA.FormattedNameLNF compare:chatParticipantModelB.FormattedNameLNF];
					}];
				}
			}
			
			// Handle success via callback
			if (callback)
			{
				callback(YES, chatMessages, nil);
			}
			// Handle success via delegate
			else if (self.delegate && [self.delegate respondsToSelector:@selector(updateChatMessages:)])
			{
				[self.delegate updateChatMessages:chatMessages];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Chat Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			if (callback)
			{
				callback(NO, nil, error);
			}
			// Handle error via delegate
			else if (self.delegate && [self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
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
		
		// Handle error via callback
		if (callback)
		{
			callback(NO, nil, error);
		}
		// Handle error via delegate
		else if (self.delegate && [self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
		{
			[self.delegate updateChatMessagesError:error];
		}
	}];
}

// (Not used)
- (void)deleteChatMessage:(NSNumber *)chatMessageID
{
    NSDictionary *parameters = @{
		@"chatMsgID"	: chatMessageID,
		@"entireConvo"	: @"true"
	};
	
	// Notify delegate that delete chat message is pending server response
	if (self.delegate && [self.delegate respondsToSelector:@selector(deleteChatMessagePending)])
	{
		[self.delegate deleteChatMessagePending];
	}
	// Show activity indicator
    else
    {
        [self showActivityIndicator:@"Deleting..."];
    }
	
	[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
        [self hideActivityIndicator:^
        {
            // Successful post returns a 204 code with no response
            if (operation.response.statusCode == 204)
            {
                // Handle success via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(deleteChatMessageSuccess)])
                {
                    [self.delegate deleteChatMessageSuccess];
                }
            }
            else
            {
                NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
                
                // Handle error via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
                {
                    [self.delegate deleteChatMessageError:error];
                }
                
                // Show error even if user has navigated to another screen
                [self showError:error withRetryCallback:^
                {
                    // Include callback to retry the request
                    [self deleteChatMessage:chatMessageID];
                }];
            }
        }];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem deleting the Chat Message." andTitle:@"Chat Message Error"];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
			{
				[self.delegate deleteChatMessageError:error];
			}
		
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self deleteChatMessage:chatMessageID];
			}];
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
	
	// Notify delegate that multiple chat message deletions are pending server response
	if (self.delegate && [self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesPending)])
	{
		[self.delegate deleteMultipleChatMessagesPending];
	}
	// Show activity indicator
    else
    {
        [self showActivityIndicator:@"Deleting..."];
    }
	
	for (ChatMessageModel *chatMessage in chatMessages)
	{
		NSDictionary *parameters = @{
			@"chatMsgID"	: chatMessage.ID,
			@"entireConvo"	: @"true"
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful post returns a 204 code with no response
			
			if (operation.response.statusCode != 204)
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Delete Error", NSLocalizedFailureReasonErrorKey, @"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"ChatMessageModel Error: %@", error);
				
				// Add chat message to failed chat messages
				[self.failedChatMessages addObject:chatMessage];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute queue finished method if all operations have completed
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
			
			// Add chat message to failed chat messages
			[self.failedChatMessages addObject:chatMessage];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute queue finished method if all operations have completed
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
	
	// Close activity indicator with callback
	[self hideActivityIndicator:^
	{
		// If a failure occurred while deleting chat message
		if ([self.failedChatMessages count] > 0)
		{
			NSArray *failedChatMessages = [self.failedChatMessages copy];
		
			// Default to all chat messages failed to delete
			NSString *errorMessage = @"There was a problem deleting your Chat Messages.";
			
			// Only some chat messages failed to delete
			if ([failedChatMessages count] != self.totalNumberOfOperations)
			{
				errorMessage = @"There was a problem deleting some of your Chat Messages.";
			}
			
			// Show error message
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Delete Chat Messages Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
			
			// Handle success via delegate to reset chat messages
			if (self.delegate && [self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesError:)])
			{
				[self.delegate deleteMultipleChatMessagesError:failedChatMessages];
			}
		
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self deleteMultipleChatMessages:failedChatMessages];
			}];
		}
		// If request was not cancelled, then handle success via delegate (not currently used)
		else if (! self.queueCancelled && self.delegate && [self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesSuccess)])
		{
			[self.delegate deleteMultipleChatMessagesSuccess];
		}
		
		// Reset queue variables
		self.totalNumberOfOperations = 0;
		self.numberOfFinishedOperations = 0;
		
		[self.failedChatMessages removeAllObjects];
	}];
}

// Returns an integer hash code for this object. Required for object comparison using isEqual
- (NSUInteger)hash
{
	return [self.ID hash];
}

// Compare this object with the specified object to determine if they are equal
- (BOOL)isEqual:(id)object
{
	return ([object isKindOfClass:[ChatMessageModel class]] && [self.ID isEqual:[object ID]]);
}

@end
