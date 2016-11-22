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
	//return;
	
	[self.operationManager GET:@"ChatParticipants" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatParticipantXMLParser *parser = [[ChatParticipantXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			// Sort Chat Participants by Last Name, First Name
			NSArray *chatParticipants = [[parser chatParticipants] sortedArrayUsingComparator:^NSComparisonResult(ChatParticipantModel *chatParticipantModelA, ChatParticipantModel *chatParticipantModelB)
			{
				return [chatParticipantModelA.FormattedNameLNF compare:chatParticipantModelB.FormattedNameLNF];
			}];
			
			if([self.delegate respondsToSelector:@selector(updateChatParticipants:)])
			{
				[self.delegate updateChatParticipants:[chatParticipants mutableCopy]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Participants Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Chat Participants.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
			{
				[self.delegate updateChatParticipantsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ChatParticipantModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Chat Participants." andTitle:@"Chat Participants Error"];
		
		// Only handle error if user still on same screen
		if([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
		{
			[self.delegate updateChatParticipantsError:error];
		}
	}];
}

@end
