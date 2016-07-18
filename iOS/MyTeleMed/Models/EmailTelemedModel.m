//
//  MessageTelemedModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "EmailTelemedModel.h"

@implementation EmailTelemedModel

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress
{
	[self sendTelemedMessage:message fromEmailAddress:fromEmailAddress messageID:nil];
}

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress messageID:(NSNumber *)messageID
{
	// Validate email address
	if( ! [self isValidEmailAddress:fromEmailAddress])
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"From field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
		if([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
		}
		
		return;
	}
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Create Message Delivery ID if a Message ID exists (exists for MessageTeleMedViewController, doesn't exist for ContactEmailViewController)
	NSString *messageDeliveryID = (messageID ? [NSString stringWithFormat:@"<MessageDeliveryID>%@</MessageDeliveryID>", messageID] : @"");
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<EmailToTelemed xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<BodyText>%@</BodyText>"
			"<FromAddress>%@</FromAddress>"
			"%@"
		"</EmailToTelemed>",
		message, fromEmailAddress, messageDeliveryID];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"EmailToTelemed" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(sendMessageSuccess)])
			{
				[self.delegate sendMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem forwarding your Message.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"EmailTelemed Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message."];
		
		if([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
		}
	}];
}

- (BOOL)isValidEmailAddress:(NSString *)emailAddress
{
	if( ! [emailAddress length])
	{
		return NO;
	}
 
	NSRange entireRange = NSMakeRange(0, [emailAddress length]);
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	NSArray *matches = [detector matchesInString:emailAddress options:0 range:entireRange];
 
	// should only a single match
	if([matches count] != 1)
	{
		return NO;
	}
 
	NSTextCheckingResult *result = [matches firstObject];
 
	// result should be a link
	if(result.resultType != NSTextCheckingTypeLink)
	{
		return NO;
	}
 
	// result should be a recognized mail address
	if( ! [result.URL.scheme isEqualToString:@"mailto"])
	{
		return NO;
	}
 
	// match must be entire string
	if( ! NSEqualRanges(result.range, entireRange))
	{
		return NO;
	}
 
	// but schould not have the mail URL scheme
	if([emailAddress hasPrefix:@"mailto:"])
	{
		return NO;
	}
 
	// no complaints, string is valid email address
	return YES;
}

@end
