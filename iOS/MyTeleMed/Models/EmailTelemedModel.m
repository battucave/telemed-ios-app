//
//  MessageTelemedModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "EmailTelemedModel.h"
#import "Validation.h"
#import "NSString+XML.h"

@implementation EmailTelemedModel

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress
{
	[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:nil];
}

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress withMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	// Validate email address
	if (! [Validation isEmailAddressValid:fromEmailAddress])
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message TeleMed Error", NSLocalizedFailureReasonErrorKey, @"From field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(emailTeleMedMessageError:)])
		{
			[self.delegate emailTeleMedMessageError:error];
		}
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		return;
	}
	
    // Add message identifier if a message delivery id exists (exists for MessageTelemedViewController, doesn't exist for ContactEmailViewController)
	NSString *messageIdentifier = (messageDeliveryID ? [NSString stringWithFormat:@"<MessageDeliveryID>%@</MessageDeliveryID>", messageDeliveryID] : @"");
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<EmailToTelemed xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<BodyText>%@</BodyText>"
			"<FromAddress>%@</FromAddress>"
			"%@"
		"</EmailToTelemed>",
		
		[message escapeXML],
		[fromEmailAddress escapeXML],
		messageIdentifier
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	// Notify delegate that message is pending server response
	if (self.delegate && [self.delegate respondsToSelector:@selector(emailTeleMedMessagePending)])
	{
		[self.delegate emailTeleMedMessagePending];
	}
    else
    {
        // Show activity indicator
        [self showActivityIndicator];
    }
	
	[self.operationManager POST:@"EmailToTelemed" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
            // Successful post returns a 204 code with no response
            if (operation.response.statusCode == 204)
            {
                // Handle success via delegate (not currently used)
                if (self.delegate && [self.delegate respondsToSelector:@selector(emailTeleMedMessageSuccess)])
                {
                    [self.delegate emailTeleMedMessageSuccess];
                }
            }
            else
            {
                NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
                
                // Handle error via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(emailTeleMedMessageError:)])
                {
                    [self.delegate emailTeleMedMessageError:error];
                }
                
                // Show error even if user has navigated to another screen
                [self showError:error withRetryCallback:^
                {
                    // Include callback to retry the request
                    [self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:messageDeliveryID];
                }];
            }
        }];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"EmailTelemed Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"Message TeleMed Error"];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(emailTeleMedMessageError:)])
			{
				[self.delegate emailTeleMedMessageError:error];
			}
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:messageDeliveryID];
			}];
		}];
	}];
}

@end
