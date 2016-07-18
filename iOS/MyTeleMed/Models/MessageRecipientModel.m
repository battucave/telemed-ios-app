//
//  MessageRecipientModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageRecipientModel.h"
#import "MessageRecipientXMLParser.h"

@implementation MessageRecipientModel

- (void)getNewMessageRecipients:(NSNumber *)accountID
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID
	};
	
	[self getMessageRecipients:parameters];
}

- (void)getForwardMessageRecipients:(NSNumber *)messageID
{
	NSDictionary *parameters = @{
		@"mdid"	: messageID
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
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateMessageRecipients:)])
			{
				[self.delegate updateMessageRecipients:[parser messageRecipients]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem retrieving the Message Recipients.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateMessageRecipientsError:)])
			{
				[self.delegate updateMessageRecipientsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageRecipientModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Recipients."];
		
		if([self.delegate respondsToSelector:@selector(updateMessageRecipientsError:)])
		{
			[self.delegate updateMessageRecipientsError:error];
		}
	}];
}

@end
