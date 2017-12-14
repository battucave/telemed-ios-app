//
//  NewMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NewMessageModel.h"

@interface NewMessageModel ()

@property BOOL pendingComplete;

@end

@implementation NewMessageModel

- (void)sendNewMessage:(NSDictionary *)messageData
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Sort dictionary keys alphabetically
	NSArray *sortedKeys = [[messageData allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableData *xmlData = [[NSMutableData alloc] init];
	
	for (NSString *key in sortedKeys)
	{
		[xmlData appendData:[[NSString stringWithFormat:@"<%@>%@</%@>", key, [messageData valueForKey:key], key] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"%@"
		"</NewMsg>",
		[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding]];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	// TEMPORARY (remove when NewMsg web service completed)
	[self networkRequestDidStart:nil];
	
	return;
	// END TEMPORARY
	
	[self.operationManager POST:@"NewMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed on AFNetworkingOperationDidStartNotification
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Not currently used
			if ([self.delegate respondsToSelector:@selector(sendMessageSuccess)])
			{
				[self.delegate sendMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"New Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^(void)
			{
				// Include callback to retry the request
				[self sendNewMessage:messageData];
			}];
			
			/*if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewMessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"New Message Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^(void)
		{
			// Include callback to retry the request
			[self sendNewMessage:messageData];
		}];
		
		/*if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
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
	
	// Notify delegate that Message has been sent to server
	if ( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(sendMessagePending)])
	{
		[self.delegate sendMessagePending];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
