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

- (void)getMessageEventsForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, NSMutableArray *newMessageEvents, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"mdid"	: messageDeliveryID
	};
	
	[self getMessageEvents:parameters withCallback:callback];
}

- (void)getMessageEventsForMessageID:(NSNumber *)messageID withCallback:(void (^)(BOOL success, NSMutableArray *newMessageEvents, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"mid"	: messageID
	};
	
	[self getMessageEvents:parameters withCallback:callback];
}

- (void)getMessageEvents:(NSDictionary *)parameters withCallback:(void (^)(BOOL success, NSMutableArray *newMessageEvents, NSError *error))callback
{
	[self.operationManager GET:@"MsgEvents" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageEventXMLParser *parser = [[MessageEventXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via callback
			callback(YES, [parser messageEvents], nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Events Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Events.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageEventModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Events." andTitle:@"Message Events Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}

@end
