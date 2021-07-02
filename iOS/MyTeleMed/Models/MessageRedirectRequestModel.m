//
//  MessageRedirectRequestModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 12/11/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "MessageRedirectRequestModel.h"

@implementation MessageRedirectRequestModel

- (void)escalateMessage:(id <MessageProtocol>)message
{
	[self escalateMessage:message withMessageRecipient:nil];
}

- (void)escalateMessage:(id <MessageProtocol>)message withMessageRecipient:(MessageRecipientModel *)messageRecipient
{
	[self redirectMessage:message messageRecipient:messageRecipient onCallSlot:nil useSlotEscalation:YES];
}

- (void)redirectMessage:(id <MessageProtocol>)message messageRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot
{
	// Verify that a message recipient or on call slot exists
	if (! messageRecipient && ! onCallSlot)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Redirect Message Error", NSLocalizedFailureReasonErrorKey, @"Redirect requires a message recipient or an on call slot.", NSLocalizedDescriptionKey, nil]];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageError:)])
		{
			[self.delegate redirectMessageError:error];
		}
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		return;
	}
	
	[self redirectMessage:message messageRecipient:messageRecipient onCallSlot:onCallSlot useSlotEscalation:NO];
}

- (void)redirectMessage:(id <MessageProtocol>)message messageRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot useSlotEscalation:(BOOL)useSlotEscalation
{
	NSString *errorMessage = [NSString stringWithFormat:@"There was a problem %@ your Message.", (useSlotEscalation ? @"escalating" : @"redirecting")];
	NSString *errorTitle = [NSString stringWithFormat:@"%@ Message Error", (useSlotEscalation ? @"Escalate" : @"Redirect")];
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
			"<UseSlotEscalation>%@</UseSlotEscalation>"
		"</MessageRedirectionRequest>",
		
		message.MessageDeliveryID,
		xmlMessageRecipient,
		xmlOnCallSlot,
		useSlotEscalation ? @"true" : @"false"
	];
	
	NSLog(@"XML Body: %@", xmlBody);
 
    // Notify delegate that message is pending server response
	if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessagePending)])
	{
		[self.delegate redirectMessagePending];
	}
    // Show activity indicator
    else
    {
        [self showActivityIndicator];
    }
	
	[self.operationManager POST:@"MsgRedirectionRequests" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
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
                NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:errorTitle, NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
                
                // Handle error via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageError:)])
                {
                    [self.delegate redirectMessageError:error];
                }
                
                // Show error even if user has navigated to another screen
                [self showError:error withRetryCallback:^
                {
                    // Include callback to retry the request
                    [self redirectMessage:message messageRecipient:messageRecipient onCallSlot:onCallSlot useSlotEscalation:useSlotEscalation];
                }];
            }
        }];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageRedirectRequestModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:errorMessage andTitle:errorTitle];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageError:)])
			{
				[self.delegate redirectMessageError:error];
			}
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self redirectMessage:message messageRecipient:messageRecipient onCallSlot:onCallSlot useSlotEscalation:useSlotEscalation];
			}];
		}];
	}];
}

@end
