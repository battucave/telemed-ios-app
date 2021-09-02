//
//  MessageRecipientModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageRecipientModel.h"
#import "MessageRecipientXMLParser.h"

@implementation MessageRecipientModel

// Private method shared by getNewMessageRecipients and getForwardMessageRecipients
- (void)getMessageRecipients:(NSDictionary *)parameters withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback
{
	[self.operationManager GET:@"MsgRecips" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageRecipientXMLParser *parser = [[MessageRecipientXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Sort message recipients by name (Med2Med: FirstName LastName, MyTeleMed: LastName, FirstName)
			NSArray *messageRecipients = [parser.messageRecipients sortedArrayUsingComparator:^NSComparisonResult(MessageRecipientModel *messageRecipientModelA, MessageRecipientModel *messageRecipientModelB)
			{
				return [messageRecipientModelA.Name compare:messageRecipientModelB.Name];
			}];
			
			// Handle success via callback
			callback(YES, messageRecipients, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Recipients Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Recipients.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Recipients." andTitle:@"Message Recipients Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}


#pragma mark - MyTeleMed

#if MYTELEMED
- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID
	};
	
	[self getMessageRecipients:parameters withCallback:callback];
}

- (void)getMessageRecipientsForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"mdid"	: messageDeliveryID
	};
	
	[self getMessageRecipients:parameters withCallback:callback];
}

- (void)getMessageRecipientsForMessageID:(NSNumber *)messageID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"mid"	: messageID
	};
	
	[self getMessageRecipients:parameters withCallback:callback];
}
#endif


#pragma mark - Med2Med

#if MED2MED
- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID slotID:(NSNumber *)slotID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID,
		@"slotID"	: slotID
	};
	
	[self getMessageRecipients:parameters withCallback:callback];
}
#endif

@end
