//
//  ChatParticipantModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatParticipantModel.h"
#import "ChatParticipantXMLParser.h"

@implementation ChatParticipantModel

- (void)getChatParticipants
{
	// TEMPORARY
	NSLog(@"Get Chat Participants");
	return;
	
	[self.operationManager GET:@"ChatParticipants" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatParticipantXMLParser *parser = [[ChatParticipantXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateChatParticipants:)])
			{
				[self.delegate updateChatParticipants:[parser chatParticipants]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem retrieving the Chat Participants.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
			{
				[self.delegate updateChatParticipantsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatParticipantModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Chat Participants."];
		
		if([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
		{
			[self.delegate updateChatParticipantsError:error];
		}
	}];
}

@end
