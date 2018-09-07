//
//  SentMessageModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import "SentMessageModel.h"
#import "SentMessageXMLParser.h"

@interface SentMessageModel()

@end

@implementation SentMessageModel

- (void)getSentMessages
{
	[self.operationManager GET:@"SentMsgs" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		SentMessageXMLParser *parser = [[SentMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(updateSentMessages:)])
			{
				[self.delegate updateSentMessages:[parser sentMessages]];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Sent Messages Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Sent Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if ([self.delegate respondsToSelector:@selector(updateSentMessagesError:)])
			{
				[self.delegate updateSentMessagesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"SentMessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Sent Messages." andTitle:@"Sent Messages Error"];
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(updateSentMessagesError:)])
		{
			[self.delegate updateSentMessagesError:error];
		}
	}];
}

/*- (void)getSentMessageByID:(NSNumber *)sentMessageID
{
	NSDictionary *parameters = @{
		@"msgid"	: messageID
	};
	
	[self GET:@"SentMessages" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		SentMessageXMLParser *parser = [[SentMessageXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via delegate
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Sent Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Sent Message.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"Sent MessageModel Error: %@", error);
		
		// Handle error via delegate
	}];
}*/

@end
