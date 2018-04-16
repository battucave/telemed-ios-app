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

@property (nonatomic) NSString *messageState;
@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) NSMutableArray *failedMessages;
@property (nonatomic) BOOL queueCancelled;
@property (nonatomic) BOOL pendingComplete;

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
	if (endDate == nil)
	{
		endDate = [NSDate date];
	}
	
	// Set Default Start Date
	if (startDate == nil)
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
	if (accountID > 0)
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
		if ([xmlParser parse])
		{
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(updateMessages:)])
			{
				[self.delegate updateMessages:[parser messages]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Messages Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if ([self.delegate respondsToSelector:@selector(updateMessagesError:)])
			{
				[self.delegate updateMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Messages." andTitle:@"Messages Error"];
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(updateMessagesError:)])
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
		if ([xmlParser parse])
		{
			// Handle success via delegate
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Handle error via delegate
	}];
}*/

- (void)modifyMessageState:(NSNumber *)messageID state:(NSString *)state
{
	// Validate message state
	if ( ! [state isEqualToString:@"Read"] && ! [state isEqualToString:@"Unread"] && ! [state isEqualToString:@"Archive"] && ! [state isEqualToString:@"Unarchive"])
	{
		state = @"Read";
	}
	
	// Show Activity Indicator
	if ([state isEqualToString:@"Archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if ([state isEqualToString:@"Unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	// Add Network Activity Observer (not currently used because client noticed "bug" when on a slow network connection - the message will still show in Messages list until the archive process completes)
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store state for modifyMessageStatePending method
	self.messageState = state;
	
	NSDictionary *parameters = @{
		@"mdid"		: messageID,
		@"method"	: state
	};
	
	[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(modifyMessageStateSuccess:)])
			{
				// Close Activity Indicator with callback
				[self hideActivityIndicator:^
				{
					[self.delegate modifyMessageStateSuccess:state];
				}];
			}
			else
			{
				// Close Activity Indicator
				[self hideActivityIndicator];
			}
		}
		else
		{
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
			{
				// Close Activity Indicator with callback
				[self hideActivityIndicator:^
				{
					[self.delegate modifyMessageStateError:error forState:state];
				}];
			}
			else
			{*/
				// Close Activity Indicator
				[self hideActivityIndicator];
			//}
		
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"Message %@ Error", ([state isEqualToString:@"Unarchive"] ? @"Unarchive" : @"Archive")], NSLocalizedFailureReasonErrorKey, [NSString stringWithFormat:@"There was a problem %@ your Message.", ([state isEqualToString:@"Unarchive"] ? @"Unarchiving" : @"Archiving")], NSLocalizedDescriptionKey, nil]];
			
			// Only show error if Archiving or Unarchiving
			if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
			{
				// Show error even if user has navigated to another screen
				[self showError:error withCallback:^
				{
					// Include callback to retry the request
					[self modifyMessageState:messageID state:state];
				}];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Handle error via delegate
		/* if ([self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate modifyMessageStateError:error forState:state];
			}];
		}
		else
		{*/
			// Close Activity Indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:[NSString stringWithFormat:@"There was a problem %@ your Message.", ([state isEqualToString:@"Unarchive"] ? @"Unarchiving" : @"Archiving")] andTitle:[NSString stringWithFormat:@"Message %@ Error", ([state isEqualToString:@"Unarchive"] ? @"Unarchive" : @"Archive")]];
		
		// Only show error if Archiving or Unarchiving
		if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
		{
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self modifyMessageState:messageID state:state];
			}];
		}
	}];
}

- (void)modifyMultipleMessagesState:(NSArray *)messages state:(NSString *)state
{
	self.failedMessages = [[NSMutableArray alloc] init];
	
	if ([messages count] < 1)
	{
		return;
	}
	
	// Validate message state
	if ( ! [state isEqualToString:@"Read"] && ! [state isEqualToString:@"Unread"] && ! [state isEqualToString:@"Archive"] && ! [state isEqualToString:@"Unarchive"])
	{
		state = @"Read";
	}
	
	// Show Activity Indicator
	if ([state isEqualToString:@"Archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if ([state isEqualToString:@"Unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store state for modifyMessageStatePending method
	self.messageState = state;
	
	for(MessageModel *message in messages)
	{
		NSDictionary *parameters = @{
			@"mdid"		: message.MessageDeliveryID,
			@"method"	: state
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful Post returns a 204 code with no response
			if (operation.response.statusCode != 204)
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Archive Error", NSLocalizedFailureReasonErrorKey, @"There was a problem modifying the Message Status.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"MessageModel Error: %@", error);
				
				// Add Message to failed Messages
				[self.failedMessages addObject:message];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state];
			}
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error)
		{
			NSLog(@"MessageModel Error: %@", error);
			
			// Handle device offline error
			if (error.code == NSURLErrorNotConnectedToInternet)
			{
				// Cancel further operations to prevent multiple error messages
				[self.operationManager.operationQueue cancelAllOperations];
				self.queueCancelled = YES;
				
				[self messageStateQueueFinished:state];
				
				return;
			}
			
			// Add Message to failed Messages
			[self.failedMessages addObject:message];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute Queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state];
			}
		}];
	}
}

- (void)messageStateQueueFinished:(NSString *)state
{
	NSLog(@"Queue Finished: %lu of %d operations failed", (unsigned long)[self.failedMessages count], self.totalNumberOfOperations);
	
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// If a failure occurred while modifying Message state
	if ([self.failedMessages count] > 0)
	{
		NSArray *failedMessages = [self.failedMessages copy];
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateError:forState:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate modifyMultipleMessagesStateError:failedMessages forState:state];
			}];
		}
		else
		{
			// Close Activity Indicator
			[self hideActivityIndicator];
		}
	
		// Default to all Messages failed to archive
		NSString *errorMessage = @"There was a problem archiving your Messages.";
		
		// Only some Messages failed to archive
		if ([failedMessages count] != self.totalNumberOfOperations)
		{
			errorMessage = @"There was a problem archiving some of your Messages.";
		}
		
		// Show error message
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Archive Messages Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self modifyMultipleMessagesState:failedMessages state:state];
		}];
	}
	// If request was not cancelled, then handle success via delegate (still being used)
	else if ( ! self.queueCancelled && [self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateSuccess:)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate modifyMultipleMessagesStateSuccess:state];
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
	
	[self.failedMessages removeAllObjects];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Message State has been sent to server
	if ( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(modifyMessageStatePending:)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate modifyMessageStatePending:self.messageState];
		}];
	}
	// Notify delegate that Multiple Message States have begun being sent to server (should always run multiple times if needed)
	else if ([self.delegate respondsToSelector:@selector(modifyMultipleMessagesStatePending:)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate modifyMultipleMessagesStatePending:self.messageState];
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
