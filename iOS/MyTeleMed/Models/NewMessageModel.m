//
//  NewMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NewMessageModel.h"
#import "RegisteredDeviceModel.h"
#import "NSString+XML.h"

@implementation NewMessageModel

- (void)sendNewMessage:(NSString *)message accountID:(NSNumber *)accountID messageRecipientIDs:(NSArray *)messageRecipientIDs
{
	RegisteredDeviceModel *registeredDeviceModel = RegisteredDeviceModel.sharedInstance;
	NSMutableString *xmlRecipients = [[NSMutableString alloc] init];
	
	for (NSString *messageRecipientID in messageRecipientIDs)
	{
		[xmlRecipients appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", messageRecipientID]];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<AccountID>%@</AccountID>"
			"<DoChase>false</DoChase>"
			"<MessageRecipients xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%@"
			"</MessageRecipients>"
			"<MessageText>%@</MessageText>"
			"<SenderDeviceID>%@</SenderDeviceID>"
		"</NewMsg>",
		
		accountID,
		xmlRecipients,
		[message escapeXML],
		registeredDeviceModel.ID
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	// Notify delegate that message is pending server response
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendNewMessagePending)])
    {
        [self.delegate sendNewMessagePending];
    }
    // Show activity indicator
    else
    {
        [self showActivityIndicator];
    }
	
	[self.operationManager POST:@"NewMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
        // Close activity indicator with callback
        [self hideActivityIndicator:^
        {
            // Successful post returns a 204 code with no response
            if (operation.response.statusCode == 204)
            {
                // Handle success via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(sendNewMessageSuccess)])
                {
                    [self.delegate sendNewMessageSuccess];
                }
            }
            else
            {
                NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"New Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
                
                // Handle error via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(sendNewMessageError:)])
                {
                    [self.delegate sendNewMessageError:error];
                }
                            
                // Show error even if user has navigated to another screen
                [self showError:error withRetryCallback:^
                {
                    // Include callback to retry the request
                    [self sendNewMessage:message accountID:accountID messageRecipientIDs:messageRecipientIDs];
                }];
            }
        }];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewMessageModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"New Message Error"];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(sendNewMessageError:)])
			{
				[self.delegate sendNewMessageError:error];
			}
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self sendNewMessage:message accountID:accountID messageRecipientIDs:messageRecipientIDs];
			}];
		}];
	}];
}

@end
