//
//  ChatParticipantModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatParticipantModel.h"
#import "ChatParticipantXMLParser.h"

@interface ChatParticipantModel()

@property (nonatomic) ChatParticipantModel *chatParticipant;
@property (nonatomic) NSMutableString *currentElementValue;

@end

@implementation ChatParticipantModel

- (void)getChatParticipants
{
	[self.operationManager GET:@"ChatParticipants" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		ChatParticipantXMLParser *parser = [[ChatParticipantXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Sort chat participants by last name, first name
			NSArray *chatParticipants = [[parser chatParticipants] sortedArrayUsingComparator:^NSComparisonResult(ChatParticipantModel *chatParticipantModelA, ChatParticipantModel *chatParticipantModelB)
			{
				return [chatParticipantModelA.FormattedNameLNF compare:chatParticipantModelB.FormattedNameLNF];
			}];
			
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(updateChatParticipants:)])
			{
				[self.delegate updateChatParticipants:chatParticipants];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Participants Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Chat Participants.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if ([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
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
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(updateChatParticipantsError:)])
		{
			[self.delegate updateChatParticipantsError:error];
		}
	}];
}

@end
