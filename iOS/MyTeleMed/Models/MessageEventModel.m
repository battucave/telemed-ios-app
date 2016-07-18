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

- (void)getMessageEvents:(NSNumber *)messageID
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getMessageEvents:) object:messageID];
	
	NSDictionary *parameters = @{
		@"mdid"	: messageID
	};
	
	[self.operationManager GET:@"MsgEvents" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MessageEventXMLParser *parser = [[MessageEventXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateMessageEvents:)])
			{
				[self.delegate updateMessageEvents:[parser messageEvents]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing Message Events.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateMessageEventsError:)])
			{
				[self.delegate updateMessageEventsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageEventModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Events."];
		
		if([self.delegate respondsToSelector:@selector(updateMessageEventsError:)])
		{
			[self.delegate updateMessageEventsError:error];
		}
	}];
}

@end
