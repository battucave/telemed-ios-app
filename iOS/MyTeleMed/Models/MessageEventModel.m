//
//  MessageEventModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageEventModel.h"
#import "MessageEventXMLParser.h"

@implementation MessageEventModel

- (void)getMessageEventsForMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	NSDictionary *parameters = @{
		@"mdid"	: messageDeliveryID
	};
	
	[self getMessageEvents:parameters];
}

- (void)getMessageEventsForMessageID:(NSNumber *)messageID
{
	NSDictionary *parameters = @{
		@"mid"	: messageID
	};
	
	[self getMessageEvents:parameters];
}

- (void)getMessageEvents:(NSDictionary *)parameters
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getMessageEvents:) object:parameters];
	
	[self.operationManager GET:@"MsgEvents" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageEventXMLParser *parser = [[MessageEventXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			if ([self.delegate respondsToSelector:@selector(updateMessageEvents:)])
			{
				[self.delegate updateMessageEvents:[parser messageEvents]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Events Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Events.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if ([self.delegate respondsToSelector:@selector(updateMessageEventsError:)])
			{
				[self.delegate updateMessageEventsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageEventModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Events." andTitle:@"Message Events Error"];
		
		// Only handle error if user still on same screen
		if ([self.delegate respondsToSelector:@selector(updateMessageEventsError:)])
		{
			[self.delegate updateMessageEventsError:error];
		}
	}];
}

@end
