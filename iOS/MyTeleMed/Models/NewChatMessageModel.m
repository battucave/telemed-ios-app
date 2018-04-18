//
//  NewChatMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/29/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "NewChatMessageModel.h"
#import "NSString+XML.h"

@interface NewChatMessageModel ()

@property (nonatomic) NSString *chatMessage;
@property (nonatomic) NSNumber *pendingID;
//@property (nonatomic) BOOL pendingComplete;

@end

@implementation NewChatMessageModel

- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat withPendingID:(NSNumber *)pendingID
{
	// Validate max length
	if ([[message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] length] > 1000)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"Message field cannot exceed 1000 characters.", NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		/*/ Not needed here
		if ([self.delegate respondsToSelector:@selector(sendChatMessageError:withPendingID:)])
		{
			[self.delegate sendChatMessageError:error withPendingID:pendingID];
		}*/
		
		return;
	}
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store message and ID for sendChatMessagePending method
	self.chatMessage = message;
	self.pendingID = pendingID;
	
	NSMutableString *xmlParticipants = [[NSMutableString alloc] init];
	
	for(NSString *chatParticipantID in chatParticipantIDs)
	{
		[xmlParticipants appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", chatParticipantID]];
	}
	
	if ([chatParticipantIDs count] == 1)
	{
		isGroupChat = NO;
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewChatMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<IsGroupChat>%@</IsGroupChat>"
			"<Participants xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%@"
			"</Participants>"
			"<Text>%@</Text>"
		"</NewChatMsg>",
		(isGroupChat ? @"true" : @"false"), xmlParticipants, [message escapeXML]];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"NewChatMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(sendChatMessageSuccess:withPendingID:)])
			{
				[self.delegate sendChatMessageSuccess:message withPendingID:pendingID];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Chat Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Chat Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self sendNewChatMessage:message chatParticipantIDs:chatParticipantIDs isGroupChat:isGroupChat withPendingID:pendingID];
			}];
			
			// Handle error via delegate
			if ([self.delegate respondsToSelector:@selector(sendChatMessageError:withPendingID:)])
			{
				[self.delegate sendChatMessageError:error withPendingID:pendingID];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewChatMessageModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(sendChatMessageError:withPendingID:)])
		{
			// Close activity indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate sendChatMessageError:error withPendingID:pendingID];
			}];
		}
		else
		{
			// Close activity indicator
			[self hideActivityIndicator];
		}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Chat Message." andTitle:@"Chat Message Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self sendNewChatMessage:message chatParticipantIDs:chatParticipantIDs isGroupChat:isGroupChat withPendingID:pendingID];
		}];
	}];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Chat Message has been sent to server
	if (/* ! self.pendingComplete &&*/ [self.delegate respondsToSelector:@selector(sendChatMessagePending:withPendingID:)])
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate sendChatMessagePending:self.chatMessage withPendingID:self.pendingID];
		}];
	}
	else
	{
		// Close activity indicator
		[self hideActivityIndicator];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	//self.pendingComplete = YES;
}

@end
