//
//  MessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageModel.h"
#import "MessageXMLParser.h"

// Define the number of items to load per page
const int MessagesPerPage = 25;

@interface MessageModel()

@property (nonatomic) NSString *messageState;
@property (nonatomic) int totalNumberOfOperations;
@property (nonatomic) int numberOfFinishedOperations;
@property (nonatomic) BOOL queueCancelled;

@end

@implementation MessageModel

- (void)getActiveMessages:(NSInteger)page
{
	[self getActiveMessages:page perPage:MessagesPerPage];
}

- (void)getActiveMessages:(NSInteger)page perPage:(NSInteger)perPage
{
	NSDictionary *parameters = @{
		@"ipp"		: [NSNumber numberWithInteger:perPage],
		@"pn"		: [NSNumber numberWithInteger:page],
		@"state"	: @"active"
	};
	
	[self getMessages:parameters];
}

- (void)getArchivedMessages:(NSInteger)page forAccount:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	// Set default End Date
	if (endDate == nil)
	{
		endDate = [NSDate date];
	}
	
	// Set default Start Date to 7 days ago
	if (startDate == nil)
	{
		startDate = [endDate dateByAddingTimeInterval:60 * 60 * 24 * -7];
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	
	NSMutableDictionary *parameters = [@{
		@"end_utc"		: [dateFormatter stringFromDate:endDate],
		@"ipp"			: [NSNumber numberWithInt:MessagesPerPage],
		@"pn"			: [NSNumber numberWithInteger:page],
		@"start_utc"	: [dateFormatter stringFromDate:startDate],
		@"state"		: @"archived"
	} mutableCopy];
	
	// If using specific Account, alter the URL to include the Account Public Key
	if (accountID.integerValue > 0)
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
        
        /*/ TESTING ONLY (generate test messages)
        #if DEBUG
            int pageNumber = [[parameters objectForKey:@"pn"] intValue];
            int perPage = [[parameters objectForKey:@"ipp"] intValue];
            int startValue = (pageNumber - 1) * MessagesPerPage + 1;
            NSMutableArray *xmlMessages = [NSMutableArray new];
            
            for (int i = startValue; i < startValue + perPage; i++)
            {
                NSString *formattedMessageText = (i == startValue ?
                    @"[A]   Welcome to MyTeleMed.  This welcome message indicates that you’ve successfully registered the App on your phone and you can now receive and send messages. Make sure to update the settings for all your notification types (STAT, Normal, Secure Chat, and Comments). You can find this under your App main menu “Settings” button. If you’d like a training session to learn details of the App, please use the “Contact TeleMed” button on your App main menu to request training session."
                    : [NSString stringWithFormat:@"Message %d", i]
                );
                long ID = 10000000 + i;
                
                NSString *xmlMessage = [NSString stringWithFormat:@"<Message><Account><ID>948</ID><Name>TeleMed</Name><PublicKey>1</PublicKey><TimeZone><Description>EDT</Description><Offset>-4</Offset></TimeZone></Account><FormattedMessageText>%@</FormattedMessageText><MessageID>%ld</MessageID><PatientName></PatientName><Priority>Normal</Priority><SenderContact>800-420-4695</SenderContact><SenderID>10</SenderID><SenderName>TeleMed</SenderName><ID>%ld</ID><MessageDeliveryID>%ld</MessageDeliveryID><State>Unread</State><TimeReceived_LCL>2021-06-23T09:38:23.289</TimeReceived_LCL><TimeReceived_UTC>2021-06-23T13:38:23.288Z</TimeReceived_UTC></Message>",
                    formattedMessageText,
                    ID,
                    ID,
                    ID
                ];
                
                [xmlMessages addObject:xmlMessage];
            }
            
            NSString *xmlString = [NSString stringWithFormat:@"<ArrayOfMessage xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">%@</ArrayOfMessage>", [xmlMessages componentsJoinedByString:@""]];
            xmlParser = [[NSXMLParser alloc] initWithData:[xmlString dataUsingEncoding:NSUnicodeStringEncoding]];
        #endif
        // END TESTING ONLY */
        
		MessageXMLParser *parser = [[MessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateMessages:forPage:)])
			{
				NSArray *messages = [parser.messages copy];
				
				[self.delegate updateMessages:messages forPage:[[parameters objectForKey:@"pn"] integerValue]];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Messages Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateMessagesError:)])
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
		if (self.delegate && [self.delegate respondsToSelector:@selector(updateMessagesError:)])
		{
			[self.delegate updateMessagesError:error];
		}
	}];
}

- (void)getMessageByDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, MessageModel *message, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"mdid"	: messageDeliveryID
	};
	
	[self.operationManager GET:@"Messages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageXMLParser *parser = [[MessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			MessageModel *message = [parser.messages objectAtIndex:0];
			
			// Handle success via callback
			callback(YES, message, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message." andTitle:@"Message Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}

- (void)modifyMessageState:(NSNumber *)messageDeliveryID state:(NSString *)state
{
	// Validate message delivery id
	if (! messageDeliveryID)
	{
		return;
	}
	
	// Validate message state
	if (! [state isEqualToString:@"Read"] && ! [state isEqualToString:@"Unread"] && ! [state isEqualToString:@"Archive"] && ! [state isEqualToString:@"Unarchive"])
	{
		state = @"Read";
	}
	
	// Show activity indicator
	if ([state isEqualToString:@"Archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if ([state isEqualToString:@"Unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	// Add network activity observer
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store state for modifyMessageStatePending:
	self.messageState = state;
	
	NSDictionary *parameters = @{
		@"mdid"		: messageDeliveryID,
		@"method"	: state
	};
	
	[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Successful post returns a 204 code with no response
			if (operation.response.statusCode == 204)
			{
				// Handle success via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMessageStateSuccess:)])
				{
					[self.delegate modifyMessageStateSuccess:state];
				}
			}
			else
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"Message %@ Error", ([state isEqualToString:@"Unarchive"] ? @"Unarchive" : @"Archive")], NSLocalizedFailureReasonErrorKey, [NSString stringWithFormat:@"There was a problem %@ your Message.", ([state isEqualToString:@"Unarchive"] ? @"Unarchiving" : @"Archiving")], NSLocalizedDescriptionKey, nil]];
				
				// Only show error if archiving or unarchiving
				if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
				{
					// Handle error via delegate
					if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
					{
						[self.delegate modifyMessageStateError:error forState:state];
					}
					
					// Show error even if user has navigated to another screen
					[self showError:error withRetryCallback:^
					{
						// Include callback to retry the request
						[self modifyMessageState:messageDeliveryID state:state];
					}];
				}
			}
		}];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageModel Error: %@", error);
		
		// Remove network activity observer
		[NSNotificationCenter.defaultCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:[NSString stringWithFormat:@"There was a problem %@ your Message.", ([state isEqualToString:@"Unarchive"] ? @"Unarchiving" : @"Archiving")] andTitle:[NSString stringWithFormat:@"Message %@ Error", ([state isEqualToString:@"Unarchive"] ? @"Unarchive" : @"Archive")]];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Only show error if archiving or unarchiving
			if ([state isEqualToString:@"Archive"] || [state isEqualToString:@"Unarchive"])
			{
				// Handle error via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMessageStateError:forState:)])
				{
					[self.delegate modifyMessageStateError:error forState:state];
				}
				
				// Show error even if user has navigated to another screen
				[self showError:error withRetryCallback:^
				{
					// Include callback to retry the request
					[self modifyMessageState:messageDeliveryID state:state];
				}];
			}
		}];
	}];
}

- (void)modifyMultipleMessagesState:(NSArray *)messages state:(NSString *)state
{
	if ([messages count] < 1)
	{
		return;
	}
	
	// Initialize failed and successful messages
	NSMutableArray *failedMessages = [[NSMutableArray alloc] init];
	NSMutableArray *successfulMessages = [[NSMutableArray alloc] init];
	
	// Validate message state
	if (! [state isEqualToString:@"Read"] && ! [state isEqualToString:@"Unread"] && ! [state isEqualToString:@"Archive"] && ! [state isEqualToString:@"Unarchive"])
	{
		state = @"Read";
	}
	
	// Show activity indicator
	if ([state isEqualToString:@"Archive"])
	{
		[self showActivityIndicator:@"Archiving..."];
	}
	if ([state isEqualToString:@"Unarchive"])
	{
		[self showActivityIndicator:@"Unarchiving..."];
	}
	
	// Add network activity observer
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store state for modifyMessageStatePending:
	self.messageState = state;
	
	for (MessageModel *message in messages)
	{
		NSDictionary *parameters = @{
			@"mdid"		: message.MessageDeliveryID,
			@"method"	: state
		};
		
		// Increment total number of operations
		self.totalNumberOfOperations++;
		
		[self.operationManager POST:@"Messages" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			// Successful post returns a 204 code with no response
			if (operation.response.statusCode == 204)
			{
				// Add message to successful messages
				[successfulMessages addObject:message];
			}
			else
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Archive Error", NSLocalizedFailureReasonErrorKey, @"There was a problem modifying the Message Status.", NSLocalizedDescriptionKey, nil]];
				
				NSLog(@"MessageModel Error: %@", error);
				
				// Add message to failed messages
				[failedMessages addObject:message];
			}
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state successfulMessages:[successfulMessages copy] failedMessages:[failedMessages copy]];
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
				
				[self messageStateQueueFinished:state successfulMessages:[successfulMessages copy] failedMessages:[failedMessages copy]];
				
				return;
			}
			
			// Add message to failed messages
			[failedMessages addObject:message];
			
			// Increment number of finished operations
			self.numberOfFinishedOperations++;
			
			// Execute queue finished method if all operations have completed
			if (self.numberOfFinishedOperations == self.totalNumberOfOperations)
			{
				[self messageStateQueueFinished:state successfulMessages:[successfulMessages copy] failedMessages:[failedMessages copy]];
			}
		}];
	}
}

- (void)messageStateQueueFinished:(NSString *)state successfulMessages:(NSArray *)successfulMessages failedMessages:(NSArray *)failedMessages
{
	NSLog(@"Queue Finished: %lu of %d operations failed", (unsigned long)[failedMessages count], self.totalNumberOfOperations);
	
	// Remove network activity observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
	[self hideActivityIndicator:^
	{
		// If a failure occurred while modifying message state
		if ([failedMessages count] > 0)
		{
			// Default to all messages failed to archive
			NSString *errorMessage = @"There was a problem archiving your Messages.";
			
			// Only some messages failed to archive
			if ([failedMessages count] < self.totalNumberOfOperations)
			{
				errorMessage = @"There was a problem archiving some of your Messages.";
			}
			
			// Show error message
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Archive Messages Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateError:successfulMessages:forState:)])
			{
				[self.delegate modifyMultipleMessagesStateError:failedMessages successfulMessages:successfulMessages forState:state];
			}
		
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self modifyMultipleMessagesState:failedMessages state:state];
			}];
		}
		// If request was not cancelled, then handle success via delegate
		else if (! self.queueCancelled && self.delegate && [self.delegate respondsToSelector:@selector(modifyMultipleMessagesStateSuccess:forState:)])
		{
			[self.delegate modifyMultipleMessagesStateSuccess:successfulMessages forState:state];
		}
		
		// Reset queue variables
		self.totalNumberOfOperations = 0;
		self.numberOfFinishedOperations = 0;
	}];
}

// Returns an integer hash code for this object. Required for object comparison using isEqual
- (NSUInteger)hash
{
	return [self.MessageDeliveryID hash];
}

// Compare this object with the specified object to determine if they are equal
- (BOOL)isEqual:(id)object
{
	return ([object isKindOfClass:[MessageModel class]] && [self.MessageDeliveryID isEqual:[object MessageDeliveryID]]);
}

// Network request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove network activity observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Close activity indicator
	[self hideActivityIndicator];
	
	// Notify delegate that message state has been sent to server
	if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMessageStatePending:)])
	{
		[self.delegate modifyMessageStatePending:self.messageState];
	}
	// Notify delegate that multiple message states have begun being sent to server
	else if (self.delegate && [self.delegate respondsToSelector:@selector(modifyMultipleMessagesStatePending:)])
	{
		[self.delegate modifyMultipleMessagesStatePending:self.messageState];
	}
}

@end
