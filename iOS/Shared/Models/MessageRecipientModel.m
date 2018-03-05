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

- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID
	};
	
	[self getMessageRecipients:parameters];
}

- (void)getMessageRecipientsForMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	NSDictionary *parameters = @{
		@"mdid"	: messageDeliveryID
	};
	
	[self getMessageRecipients:parameters];
}

- (void)getMessageRecipientsForMessageID:(NSNumber *)messageID
{
	NSDictionary *parameters = @{
		@"mid"	: messageID
	};
	
	[self getMessageRecipients:parameters];
}

// Private method shared by getNewMessageRecipients and getForwardMessageRecipients
- (void)getMessageRecipients:(NSDictionary *)parameters
{
	[self.operationManager GET:@"MsgRecips" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageRecipientXMLParser *parser = [[MessageRecipientXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			// Sort Message Recipients by Last Name, First Name
			NSArray *messageRecipients = [[parser messageRecipients] sortedArrayUsingComparator:^NSComparisonResult(MessageRecipientModel *messageRecipientModelA, MessageRecipientModel *messageRecipientModelB)
			{
				return [messageRecipientModelA.Name compare:messageRecipientModelB.Name];
			}];
			
			if ([self.delegate respondsToSelector:@selector(updateMessageRecipients:)])
			{
				[self.delegate updateMessageRecipients:[messageRecipients mutableCopy]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Recipients Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Recipients.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if ([self.delegate respondsToSelector:@selector(updateMessageRecipientsError:)])
			{
				[self.delegate updateMessageRecipientsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageRecipientModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Recipients." andTitle:@"Message Recipients Error"];
		
		// Only handle error if user still on same screen
		if ([self.delegate respondsToSelector:@selector(updateMessageRecipientsError:)])
		{
			[self.delegate updateMessageRecipientsError:error];
		}
	}];
}

@end
