//
//  ChatMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessageModel.h"
#import "ChatMessageXMLParser.h"

@interface ChatMessageModel()

@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) NSMutableArray *failedChatMessageIDs;
@property BOOL queueCancelled;

@end

@implementation ChatMessageModel

- (void)getChatMessages
{
	// TEMPORARY
	NSData *xmlData = [@"<ArrayOfChatMessage xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\"><ChatMessage><Text>[A]  Counselo Matt Rogers Evidence gas been collected</Text><ID>5133538688706197</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Unread</State><TimeReceived_LCL>2016-06-17T16:46:10.248</TimeReceived_LCL><TimeReceived_UTC>2016-06-17T20:46:10.248Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  TECH Jason Hutchison Another joint to Shane and Matt</Text><ID>5133538688700713</ID><SenderID>5320</SenderID><SenderName>Hutchison, Jason</SenderName><State>Read</State><TimeReceived_LCL>2016-06-17T12:54:15.474</TimeReceived_LCL><TimeReceived_UTC>2016-06-17T16:54:15.474Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers What's happening?</Text><ID>5133538688700703</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-17T12:43:11.644</TimeReceived_LCL><TimeReceived_UTC>2016-06-17T16:43:11.644Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers What?!</Text><ID>5133538688695417</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T14:53:21.414</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T18:53:21.414Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  TECH Jason Hutchison Test message from Jason to Matt abd Shane.</Text><ID>5133538688695397</ID><SenderID>5320</SenderID><SenderName>Hutchison, Jason</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T13:55:29.378</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T17:55:29.378Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Testing push</Text><ID>5133538688695386</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T13:38:41.024</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T17:38:41.024Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Another just because</Text><ID>5133538688695372</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T13:36:41.138</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T17:36:41.138Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Oh no</Text><ID>5133538688695362</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T13:35:49.994</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T17:35:49.994Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Oh yes</Text><ID>5133538688695349</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-06-02T13:33:45.881</TimeReceived_LCL><TimeReceived_UTC>2016-06-02T17:33:45.881Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]   Welcome to MyTeleMed. The MyTeleMed app gives you new options for your locate plan. Please call TeleMed for details.</Text><ID>5133538688695337</ID><SenderID>10</SenderID><SenderName>TeleMed</SenderName><State>Read</State><TimeReceived_LCL>2016-05-31T11:01:30.728</TimeReceived_LCL><TimeReceived_UTC>2016-05-31T15:01:30.728Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  TECH Jason Hutchison Test joint message</Text><ID>5133538688695018</ID><SenderID>5320</SenderID><SenderName>Hutchison, Jason</SenderName><State>Read</State><TimeReceived_LCL>2016-05-11T16:53:23.944</TimeReceived_LCL><TimeReceived_UTC>2016-05-11T20:53:23.944Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers One more test</Text><ID>5133538688694982</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-05-10T16:45:59.281</TimeReceived_LCL><TimeReceived_UTC>2016-05-10T20:45:59.281Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Comment hackery.</Text><ID>5133538688694968</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-05-10T16:39:54.081</TimeReceived_LCL><TimeReceived_UTC>2016-05-10T20:39:54.081Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Hehehehe</Text><ID>5133538688694954</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-05-10T16:37:01.864</TimeReceived_LCL><TimeReceived_UTC>2016-05-10T20:37:01.864Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Did you receive this?</Text><ID>5133538688694931</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-05-10T16:32:58.018</TimeReceived_LCL><TimeReceived_UTC>2016-05-10T20:32:58.018Z</TimeReceived_UTC></ChatMessage><ChatMessage><Text>[A]  Counselo Matt Rogers Comments test</Text><ID>5133538688694827</ID><SenderID>829772</SenderID><SenderName>Rogers, Matt</SenderName><State>Read</State><TimeReceived_LCL>2016-05-09T19:21:27.231</TimeReceived_LCL><TimeReceived_UTC>2016-05-09T23:21:27.231Z</TimeReceived_UTC></ChatMessage></ArrayOfChatMessage>" dataUsingEncoding:NSUTF8StringEncoding];
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
	ChatMessageXMLParser *parser = [[ChatMessageXMLParser alloc] init];
	
	[xmlParser setDelegate:parser];
	
	// Parse the XML file
	if([xmlParser parse])
	{
		[self.delegate updateChatMessages:[parser chatMessages]];
	}
	
	return;
	
	[self.operationManager GET:@"ChatMessages" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatMessageXMLParser *parser = [[ChatMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateChatMessages:)])
			{
				[self.delegate updateChatMessages:[parser chatMessages]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem retrieving the Chat Messages.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
			{
				[self.delegate updateChatMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Chat Messages."];
		
		if([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
		{
			[self.delegate updateChatMessagesError:error];
		}
	}];
}

- (void)getChatMessageByID:(NSNumber *)chatMessageID
{
	NSLog(@"GetChatMessagesByID");
	return;
	
	NSDictionary *parameters = @{
		@"chatMsgID"	: chatMessageID
	};
	
	[self.operationManager GET:@"ChatMessages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatMessageXMLParser *parser = [[ChatMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateChatMessages:)])
			{
				[self.delegate updateChatMessages:[parser chatMessages]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem retrieving the Chat Messages.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
			{
				[self.delegate updateChatMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Chat Messages."];
		
		if([self.delegate respondsToSelector:@selector(updateChatMessagesError:)])
		{
			[self.delegate updateChatMessagesError:error];
		}
	}];
}

- (void)deleteChatMessage:(NSNumber *)chatMessageID
{
	// TEMPORARY
	NSLog(@"Delete Chat Message");
	
	[self.delegate deleteChatMessageSuccess];
	
	return;
	
	NSDictionary *parameters = @{
		@"chatMsgID"	: chatMessageID
	};
	
	[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(deleteChatMessageSuccess)])
			{
				[self.delegate deleteChatMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
			{
				[self.delegate deleteChatMessageError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatMessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem deleting the Chat Message."];
		
		if([self.delegate respondsToSelector:@selector(deleteChatMessageError:)])
		{
			[self.delegate deleteChatMessageError:error];
		}
	}];
}

- (void)deleteMultipleChatMessages:(NSArray *)chatMessages
{
	self.failedChatMessageIDs = [[NSMutableArray alloc] init];
	
	if([chatMessages count] < 1)
	{
		return;
	}
	
	// TEMPORARY
	NSLog(@"Delete Multiple Chat Messages");
	
	[self.failedChatMessageIDs addObject:[NSNumber numberWithLong:5133538688706197]];
	[self chatMessageDeleteQueueFinished];
	
	return;
	
	for(ChatMessageModel *chatMessage in chatMessages)
	{
		NSDictionary *parameters = @{
			@"chatMsgID"	: chatMessage.ID
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager DELETE:@"ChatMessages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful Post returns a 204 code with no response
			
			if(operation.response.statusCode != 204)
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem deleting the Chat Message.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"ChatMessageModel Error: %@", error);
				
				// Add Chat Message ID to failed Chat Message IDs
				[self.failedChatMessageIDs addObject:chatMessage.ID];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if(self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self chatMessageDeleteQueueFinished];
			}
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error)
		{
			NSLog(@"ChatMessageModel Error: %@", error);
			
			// Handle device offline error
			if(error.code == NSURLErrorNotConnectedToInternet/* || error.code == NSURLErrorTimedOut*/)
			{
				// Cancel further operations to prevent multiple error messages
				[self.operationManager.operationQueue cancelAllOperations];
				self.queueCancelled = YES;
				
				[self chatMessageDeleteQueueFinished];
				
				return;
			}
			
			// Add Chat Message ID to failed Chat Message IDs
			[self.failedChatMessageIDs addObject:chatMessage.ID];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if(self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self chatMessageDeleteQueueFinished];
			}
		}];
	}
}

- (void)chatMessageDeleteQueueFinished
{
	NSLog(@"Queue Finished: %lu of %d operations failed", (unsigned long)[self.failedChatMessageIDs count], self.totalNumberOfOperations);
	
	// Close Activity Indicator
	[self hideActivityIndicator];
	
	// If a failure occurred while deleting Chat Message
	if([self.failedChatMessageIDs count] > 0)
	{
		if([self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesError:)])
		{
			[self.delegate deleteMultipleChatMessagesError:self.failedChatMessageIDs];
		}
	}
	// If request was not cancelled, then it was successful
	else if( ! self.queueCancelled)
	{
		if([self.delegate respondsToSelector:@selector(deleteMultipleChatMessagesSuccess)])
		{
			[self.delegate deleteMultipleChatMessagesSuccess];
		}
	}
	
	// Reset Queue Variables
	self.totalNumberOfOperations = 0;
	self.numberOfFinishedOperations = 0;
	
	[self.failedChatMessageIDs removeAllObjects];
}

@end
