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
- (void)getMessageRecipients:(NSDictionary *)parameters
{
	[self.operationManager GET:@"MsgRecips" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageRecipientXMLParser *parser = [[MessageRecipientXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Sort message recipients by name (MedToMed: FirstName LastName, MyTeleMed: LastName, FirstName)
			NSArray *messageRecipients = [[parser messageRecipients] sortedArrayUsingComparator:^NSComparisonResult(MessageRecipientModel *messageRecipientModelA, MessageRecipientModel *messageRecipientModelB)
			{
				return [messageRecipientModelA.Name compare:messageRecipientModelB.Name];
			}];
			
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(updateMessageRecipients:)])
			{
				[self.delegate updateMessageRecipients:[messageRecipients mutableCopy]];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Recipients Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Recipients.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
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
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(updateMessageRecipientsError:)])
		{
			[self.delegate updateMessageRecipientsError:error];
		}
	}];
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
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
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED
- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID slotID:(NSNumber *)slotID
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID,
		@"slotID"	: slotID
	};
	
	[self getMessageRecipients:parameters];
}
#endif

@end
