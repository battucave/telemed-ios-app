//
//  ForwardMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "ForwardMessageModel.h"

@implementation ForwardMessageModel

- (void)forwardMessage:(NSNumber *)messageID messageRecipientIDs:(NSArray *)messageRecipientIDs
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	NSMutableString *xmlRecipients = [[NSMutableString alloc] init];
	
	for(NSString *messageRecipientID in messageRecipientIDs)
	{
		[xmlRecipients appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", messageRecipientID]];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<FwdMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<MessageDeliveryID>%@</MessageDeliveryID>"
			"<MessageRecipients xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%@"
			"</MessageRecipients>"
		"</FwdMsg>",
		messageID, xmlRecipients];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"FwdMsgs" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
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
		NSLog(@"ForwardMessageModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem forwarding your Message."];
		
		if([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			[self.delegate sendMessageError:error];
		}
	}];
}

@end
