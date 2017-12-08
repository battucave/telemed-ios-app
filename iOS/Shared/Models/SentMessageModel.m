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
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateSentMessages:)])
			{
				[self.delegate updateSentMessages:[parser sentMessages]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Sent Messages Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Sent Messages.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if([self.delegate respondsToSelector:@selector(updateSentMessagesError:)])
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
		
		// Only handle error if user still on same screen
		if([self.delegate respondsToSelector:@selector(updateSentMessagesError:)])
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
		
		// Parse the XML file
		if([xmlParser parse])
		{
			// Handle Success
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Sent Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Sent Message.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"Sent MessageModel Error: %@", error);
		
		// Only handle error if user still on same screen
	}];
}*/

@end
