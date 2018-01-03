//
//  NewMessageModel.m
//  MedToMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NewMessageModel.h"

@interface NewMessageModel ()

@property BOOL pendingComplete;

@end

@implementation NewMessageModel

- (void)sendNewMessage:(NSDictionary *)messageData withOrder:(NSArray *)sortedKeys
{
	NSArray *parameters = @[@"AccountID", @"CallbackName", @"CallbackNumber", @"HospitalID", @"MessageText", @"PatientFirstName", @"PatientLastName", @"Priority"];
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Sort dictionary keys alphabetically (if custom order is required, utilize the "sortedKeys" method parameter)
	// NSArray *sortedKeys = [[messageData allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *messageText = [NSMutableArray array];
	
	// Add optional fields to message text array
	for (NSString *key in sortedKeys)
	{
		// Exclude explicitly added parameters
		if ([messageData objectForKey:key] && ! [parameters containsObject:key])
		{
			[messageText addObject:[NSString stringWithFormat:@"%@: %@", key, [messageData valueForKey:key]]];
		}
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<AccountID>%@</AccountID>"
			"<CallbackName>%@</CallbackName>"
			"<CallbackNumber>%@</CallbackNumber>"
			"<HospitalID>%@</HospitalID>"
			"<MessageText>%@</MessageText>"
			"<PatientFirstName>%@</PatientFirstName>"
			"<PatientLastName>%@</PatientLastName>"
			"<Priority>%@</Priority>"
		"</NewMsg>",
		[messageData valueForKey:@"AccountID"], [messageData valueForKey:@"CallbackName"], [messageData valueForKey:@"CallbackNumber"], [messageData valueForKey:@"HospitalID"], [messageText componentsJoinedByString:@"\n"], [messageData valueForKey:@"PatientFirstName"], [messageData valueForKey:@"PatientLastName"], [messageData valueForKey:@"Priority"]];
	
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
				[self sendNewMessage:messageData withOrder:sortedKeys];
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
			[self sendNewMessage:messageData withOrder:sortedKeys];
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
