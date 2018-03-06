//
//  MessageTelemedModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "EmailTelemedModel.h"
#import "NSString+XML.h"

@interface EmailTelemedModel ()

@property (nonatomic) BOOL pendingComplete;

@end

@implementation EmailTelemedModel

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress
{
	[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:nil];
}

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress withMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	// Validate email address
	if ( ! [self isValidEmailAddress:fromEmailAddress])
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message TeleMed Error", NSLocalizedFailureReasonErrorKey, @"From field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
		}*/
		
		return;
	}
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Add Message Identifier if a Message Delivery ID exists (exists for MessageTeleMedViewController, doesn't exist for ContactEmailViewController)
	NSString *messageIdentifier = (messageDeliveryID ? [NSString stringWithFormat:@"<MessageDeliveryID>%@</MessageDeliveryID>", messageDeliveryID] : @"");
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<EmailToTelemed xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<BodyText>%@</BodyText>"
			"<FromAddress>%@</FromAddress>"
			"%@"
		"</EmailToTelemed>",
		[message escapeXML], [fromEmailAddress escapeXML], messageIdentifier];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"EmailToTelemed" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
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
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:messageDeliveryID];
			}];
			
			/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"EmailTelemed Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate sendMessageError:error];
			}];
		}
		else
		{*/
			// Close Activity Indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"Message TeleMed Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:messageDeliveryID];
		}];
	}];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Message has been sent to server
	if ( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(sendMessagePending)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate sendMessagePending];
		}];
	}
	else
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

- (BOOL)isValidEmailAddress:(NSString *)emailAddress
{
	if ( ! [emailAddress length])
	{
		return NO;
	}
 
	NSRange entireRange = NSMakeRange(0, [emailAddress length]);
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	NSArray *matches = [detector matchesInString:emailAddress options:0 range:entireRange];
 
	// should only a single match
	if ([matches count] != 1)
	{
		return NO;
	}
 
	NSTextCheckingResult *result = [matches firstObject];
 
	// result should be a link
	if (result.resultType != NSTextCheckingTypeLink)
	{
		return NO;
	}
 
	// result should be a recognized mail address
	if ( ! [result.URL.scheme isEqualToString:@"mailto"])
	{
		return NO;
	}
 
	// match must be entire string
	if ( ! NSEqualRanges(result.range, entireRange))
	{
		return NO;
	}
 
	// but schould not have the mail URL scheme
	if ([emailAddress hasPrefix:@"mailto:"])
	{
		return NO;
	}
 
	// no complaints, string is valid email address
	return YES;
}

@end
