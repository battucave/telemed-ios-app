//
//  MessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageModel.h"
#import "MessageXMLParser.h"

@interface MessageModel()

@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) NSMutableArray *failedMessageIDs;
@property BOOL queueCancelled;

@end

@implementation MessageModel

- (void)getActiveMessages
{
	NSDictionary *parameters = @{
		@"state"	: @"active"
	};
	
	[self getMessages:parameters];
}

- (void)getArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	// Set Default End Date
	if(endDate == nil)
	{
		endDate = [NSDate date];
	}
	
	// Set Default Start Date
	if(startDate == nil)
	{
		startDate = [endDate dateByAddingTimeInterval:60 * 60 * 24 * -7];
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	
	NSMutableDictionary *parameters = [@{
		@"state"		: @"archived",
		@"start_utc"	: [dateFormatter stringFromDate:startDate],
		@"end_utc"		: [dateFormatter stringFromDate:endDate]
	} mutableCopy];
	
	// If using specific Account, alter the URL to include the Account Public Key
	if(accountID > 0)
	{
		[parameters setValue:accountID forKey:@"acctID"];
	}
	
	[self getMessages:parameters];
}

// Private method shared by getActiveMessages and getArchivedMessages
- (void)getMessages:(NSDictionary *)parameters
{
	[self.operationManager GET:@"Messages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageXMLParser *parser = [[MessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateMessages:)])
			{
				[self.delegate updateMessages:[parser messages]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem retrieving the Messages.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateMessagesError:)])
			{
				[self.delegate updateMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Messages."];
		
		if([self.delegate respondsToSelector:@selector(updateMessagesError:)])
		{
			[self.delegate updateMessagesError:error];
		}
	}];
}

/*- (void)getMessageByID:(NSNumber *)messageID
{
	NSDictionary *parameters = @{
		@"mdid"	: messageID
	};
	
	[self GET:@"Messages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageXMLParser *parser = [[MessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			// Handle Success
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing messages", NSLocalizedDescriptionKey, nil]];
			
			// Handle Error
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Handle Error
	}];
}*/

- (void)modifyMessageState:(NSNumber *)messageID state:(NSString *)state
{
	// State must be one of the following: read, unread, archive, unarchive
	if( ! [state isEqualToString:@"read"] && ! [state isEqualToString:@"unread"] && ! [state isEqualToString:@"archive"] && ! [state isEqualToString:@"unarchive"])
	{
		state = @"read";
	}
	
	// Show Activity Indicator
	if([state isEqualToString:@"archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if([state isEqualToString:@"unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	NSDictionary *parameters = @{
		@"mdid"		: messageID,
		@"method"	: state
	};
	
	[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(modifyMessageStateSuccess:)])
			{
				[self.delegate modifyMessageStateSuccess:state];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem modifying the Message Status.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
			{
				[self.delegate modifyMessageStateError:error forState:state];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem modifying the Message Status."];
		
		if([self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
		{
			[self.delegate modifyMessageStateError:error forState:state];
		}
	}];
}

- (void)modifyMultipleMessagesState:(NSArray *)messages state:(NSString *)state
{
	self.failedMessageIDs = [[NSMutableArray alloc] init];
	
	// State must be one of the following: read, unread, archive, unarchive
	if( ! [state isEqualToString:@"read"] && ! [state isEqualToString:@"unread"] && ! [state isEqualToString:@"archive"] && ! [state isEqualToString:@"unarchive"])
	{
		state = @"read";
	}
	
	// Show Activity Indicator
	if([state isEqualToString:@"archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if([state isEqualToString:@"unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	if([messages count] < 1)
	{
		return;
	}
	
	for(MessageModel *message in messages)
	{
		NSDictionary *parameters = @{
			@"mdid"		: message.ID,
			@"method"	: state
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful Post returns a 204 code with no response
			
			if(operation.response.statusCode != 204)
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem modifying the Message Status.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"MessageModel Error: %@", error);
				
				// Add Message ID to failed Message IDs
				[self.failedMessageIDs addObject:message.ID];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if(self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state];
			}
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error)
		{
			NSLog(@"MessageModel Error: %@", error);
			
			// Handle device offline error
			if(error.code == NSURLErrorNotConnectedToInternet/* || error.code == NSURLErrorTimedOut*/)
			{
				// Cancel further operations to prevent multiple error messages
				[self.operationManager.operationQueue cancelAllOperations];
				self.queueCancelled = YES;
				
				[self messageStateQueueFinished:state];
				
				return;
			}
			
			// Add Message ID to failed Message IDs
			[self.failedMessageIDs addObject:message.ID];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if(self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state];
			}
		}];
	}
}

- (void)messageStateQueueFinished:(NSString *)state
{
	NSLog(@"Queue Finished: %lu of %d operations failed", (unsigned long)[self.failedMessageIDs count], self.totalNumberOfOperations);
	
	// Close Activity Indicator
	[self hideActivityIndicator];
	
	// If a failure occurred while modifying Message state
	if([self.failedMessageIDs count] > 0)
	{
		if([self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateError:forState:)])
		{
			[self.delegate modifyMultipleMessagesStateError:self.failedMessageIDs forState:state];
		}
	}
	// If request was not cancelled, then it was successful
	else if( ! self.queueCancelled)
	{
		if([self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateSuccess:)])
		{
			[self.delegate modifyMultipleMessagesStateSuccess:state];
		}
	}
	
	// Reset Queue Variables
	self.totalNumberOfOperations = 0;
	self.numberOfFinishedOperations = 0;
	
	[self.failedMessageIDs removeAllObjects];
}

@end
