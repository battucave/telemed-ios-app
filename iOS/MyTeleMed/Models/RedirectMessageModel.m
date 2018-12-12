//
//  RedirectMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 12/11/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "RedirectMessageModel.h"

@interface RedirectMessageModel ()

@property BOOL pendingComplete;

@end

@implementation RedirectMessageModel

- (void)redirectMessage:(id <MessageProtocol>)message messageRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot
{
	// Verify that a message recipient or on call slot exists
	if (! messageRecipient && ! onCallSlot)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Redirect Message Error", NSLocalizedFailureReasonErrorKey, @"Redirect requires a message recipient or an on call slot.", NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		return;
	}
	
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSString *xmlMessageRecipient = @"";
	NSString *xmlOnCallSlot = @"";
	
	// Add message recipient to xml if it exists
	if (messageRecipient)
	{
		xmlMessageRecipient = [NSString stringWithFormat:
			@"<RedirectRecipient>"
				"<ID>%@</ID>"
				"<Name>%@</Name>"
				"<Type>%@</Type>"
			"</RedirectRecipient>",
			
			messageRecipient.ID,
			messageRecipient.Name,
			messageRecipient.Type
		];
	}
	
	// Add on call slot to xml if it exists
	if (onCallSlot)
	{
		xmlOnCallSlot = [NSString stringWithFormat:
			@"<RedirectSlot>"
				"<CurrentOncall>%@</CurrentOncall>"
				"<CurrentOncallEntryTypeID>%@</CurrentOncallEntryTypeID>"
				"<Description>%@</Description>"
				"<Header>%@</Header>"
				"<ID>%@</ID>"
				"<IsEscalationSlot>%@</IsEscalationSlot>"
				"<Name>%@</Name>"
				"<SelectRecipient>%@</SelectRecipient>"
			"</RedirectSlot>",
			
			onCallSlot.CurrentOncall,
			onCallSlot.CurrentOncallEntryTypeID,
			onCallSlot.Description, onCallSlot.Header,
			onCallSlot.ID,
			(onCallSlot.IsEscalationSlot ? @"true" : @"false"),
			onCallSlot.Name,
			(onCallSlot.SelectRecipient ? @"true" : @"false")
		];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<MessageRedirectionRequest xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<DeliveryID>%@</DeliveryID>"
			"%@"
			"%@"
		"</MessageRedirectionRequest>",
		
		message.MessageDeliveryID,
		xmlMessageRecipient,
		xmlOnCallSlot
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"MsgRedirectionRequests" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 200 || operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageSuccess)])
			{
				[self.delegate redirectMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Redirect Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem redirecting your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self redirectMessage:message messageRecipient:messageRecipient onCallSlot:onCallSlot];
			}];
			
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageError:)])
			{
				[self.delegate redirectMessageError:error];
			} */
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"RedirectMessageModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem redirecting your Message." andTitle:@"Redirect Message Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageError:)])
			{
				[self.delegate redirectMessageError:error];
				}];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self redirectMessage:message messageRecipient:messageRecipient onCallSlot:onCallSlot];
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
		if (! self.pendingComplete && self.delegate && [self.delegate respondsToSelector:@selector(redirectMessagePending)])
		{
			[self.delegate redirectMessagePending];
		}
		
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

@end
