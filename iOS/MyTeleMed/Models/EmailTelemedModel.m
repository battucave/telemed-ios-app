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
	if (! [self isValidEmailAddress:fromEmailAddress])
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message TeleMed Error", NSLocalizedFailureReasonErrorKey, @"From field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
		// Show error even if user has navigated to another screen
		[self showError:error];
		
		// Handle error via delegate
		/* if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
		}*/
		
		return;
	}
	
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Add message identifier if a message delivery id exists (exists for MessageTelemedViewController, doesn't exist for ContactEmailViewController)
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
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessageSuccess)])
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
			
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"EmailTelemed Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"Message TeleMed Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress withMessageDeliveryID:messageDeliveryID];
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
		if (! self.pendingComplete && self.delegate && [self.delegate respondsToSelector:@selector(sendMessagePending)])
		{
			[self.delegate sendMessagePending];
		}
	
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

- (BOOL)isValidEmailAddress:(NSString *)emailAddress
{
	if (! emailAddress.length)
	{
		return NO;
	}

	NSRange entireRange = NSMakeRange(0, emailAddress.length);
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	NSArray *matches = [detector matchesInString:emailAddress options:0 range:entireRange];
 
	// Should be only a single match
	if ([matches count] != 1)
	{
		return NO;
	}
 
	NSTextCheckingResult *result = [matches firstObject];
 
	// Result should be a link type
	if (result.resultType != NSTextCheckingTypeLink)
	{
		return NO;
	}
 
	// Result should be a recognized email address
	if (! [result.URL.scheme isEqualToString:@"mailto"])
	{
		return NO;
	}
 
	// Match must include the entire string
	if (! NSEqualRanges(result.range, entireRange))
	{
		return NO;
	}
 
	// Should not have the mailto url scheme
	if ([emailAddress hasPrefix:@"mailto:"])
	{
		return NO;
	}
 
	return YES;
}

@end
