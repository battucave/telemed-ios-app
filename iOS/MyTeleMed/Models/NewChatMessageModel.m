//
//  NewChatMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/29/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "NewChatMessageModel.h"

@interface NewChatMessageModel ()

@property BOOL pendingComplete;

@end

@implementation NewChatMessageModel

- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
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
	
	return;
	
	[self.operationManager POST:@"NewChatMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed on AFNetworkingOperationDidStartNotification
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			// Still used to begin listening to replies if user remained on screen
			if([self.delegate respondsToSelector:@selector(sendChatMessageSuccess)])
			{
				[self.delegate sendChatMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Chat Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^(void)
			{
				// Include callback to retry the request
				[self sendNewChatMessage:message chatParticipantIDs:chatParticipantIDs isGroupChat:isGroupChat];
			}];
			
			/*if([self.delegate respondsToSelector:@selector(sendChatMessageError:)])
			{
				[self.delegate sendChatMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewChatMessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Chat Message." andTitle:@"Chat Message Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^(void)
		{
			// Include callback to retry the request
			[self sendNewChatMessage:message chatParticipantIDs:chatParticipantIDs isGroupChat:isGroupChat];
		}];
		
		/*if([self.delegate respondsToSelector:@selector(sendChatMessageError:)])
		{
			[self.delegate sendChatMessageError:error];
		}*/
	}];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Close Activity Indicator
	[self hideActivityIndicator];
	
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Chat Message has been sent to server
	if( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(sendChatMessagePending)])
	{
		[self.delegate sendChatMessagePending];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
