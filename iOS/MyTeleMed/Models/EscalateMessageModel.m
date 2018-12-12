//
//  EscalateMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 12/11/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "EscalateMessageModel.h"

@interface EscalateMessageModel ()

@property BOOL pendingComplete;

@end

@implementation EscalateMessageModel

- (void)escalateMessage:(id <MessageProtocol>)message
{
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<MessageRedirectionRequest xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<DeliveryID>%@</DeliveryID>"
			"<UseSlotEscalation>true</UseSlotEscalation>"
		"</MessageRedirectionRequest>",
		
		message.MessageDeliveryID
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"MsgRedirectionRequests" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 200 || operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(escalateMessageSuccess)])
			{
				[self.delegate escalateMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Escalate Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem escalating your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self escalateMessage:message];
			}];
			
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(escalateMessageError:)])
			{
				[self.delegate escalateMessageError:error];
			} */
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"EscalateMessageModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem escalating your Message." andTitle:@"Escalate Message Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(escalateMessageError:)])
			{
				[self.delegate escalateMessageError:error];
				}];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self escalateMessage:message];
			}];
		}];
	}];
}

// Network request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove network activity observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Close activity indicator with callback
	[self hideActivityIndicator:^
	{
		// Notify delegate that message has been sent to server
		if (! self.pendingComplete && self.delegate && [self.delegate respondsToSelector:@selector(escalateMessagePending)])
		{
			[self.delegate escalateMessagePending];
		}
		
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

@end
