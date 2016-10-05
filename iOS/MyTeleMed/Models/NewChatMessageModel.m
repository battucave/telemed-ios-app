//
//  NewChatMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/29/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "NewChatMessageModel.h"

@implementation NewChatMessageModel

- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	NSMutableString *xmlParticipants = [[NSMutableString alloc] init];
	
	for(NSString *chatParticipantID in chatParticipantIDs)
	{
		[xmlParticipants appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", chatParticipantID]];
	}
	
	if([chatParticipantIDs count] == 1)
	{
		isGroupChat = NO;
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewChatMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<IsGroupChat>%@</IsGroupChat>"
			"<Participants xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%@"
			"</Participants>"
			"<Text>%@</Text>"
		"</NewChatMsg>",
		(isGroupChat ? @"true" : @"false"), xmlParticipants, message];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"NewChatMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(sendChatMessageSuccess)])
			{
				[self.delegate sendChatMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(sendChatMessageError:)])
			{
				[self.delegate sendChatMessageError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewChatMessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message."];
		
		if([self.delegate respondsToSelector:@selector(sendChatMessageError:)])
		{
			[self.delegate sendChatMessageError:error];
		}
	}];
}

@end
