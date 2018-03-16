//
//  NewMessageModel.m
//  MedToMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NewMessageModel.h"
#import "MessageRecipientModel.h"
#import "NSString+XML.h"

@interface NewMessageModel ()

@property BOOL pendingComplete;

@end

@implementation NewMessageModel

- (void)sendNewMessage:(NSDictionary *)messageData withOrder:(NSArray *)sortedKeys
{
	NSArray *parameters = @[@"AccountID", @"CallbackFirstName", @"CallbackLastName", @"CallbackPhoneNumber", @"CallbackTitle", @"HospitalID", @"MessageRecipients", @"MessageText", @"PatientFirstName", @"PatientLastName", @"STAT"];
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Strip any non-numeric characters from phone number
	NSString *callbackPhoneNumber = [NSString stringWithString:[[[messageData valueForKey:@"CallbackPhoneNumber"] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]];
	
	/*/ Set callback title xml if it is present in message data (NOTE: client requested that this be required, but I suspect that will change in the future so logic is still here to allow it to be optional)
	NSString *callbackTitle = @"";
	
	if ([messageData objectForKey:@"CallbackTitle"])
	{
		callbackTitle = [NSString stringWithFormat:@"<CallbackTitle>%@</CallbackTitle>", [[messageData valueForKey:@"CallbackTitle"] escapeXML]];
	}*/
	
	NSMutableArray *messageRecipients = (NSMutableArray *)[messageData objectForKey:@"MessageRecipients"];
	NSMutableString *xmlRecipients = [[NSMutableString alloc] init];
	
	for(MessageRecipientModel *messageRecipient in messageRecipients)
	{
		[xmlRecipients appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", messageRecipient.ID]];
	}
	
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
	
	// If message text array is empty, then include a default message to prevent validation error
	if ([messageText count] == 0)
	{
		[messageText addObject:@"No additional information provided."];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NewMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<AccountID>%@</AccountID>"
			"<CallbackFirstName>%@</CallbackFirstName>"
			"<CallbackLastName>%@</CallbackLastName>"
			"<CallbackPhone>%@</CallbackPhone>"
			"<CallbackTitle>%@</CallbackTitle>"
			"<HospitalID>%@</HospitalID>"
			"<MessageRecipients xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%@"
			"</MessageRecipients>"
			"<MessageText>%@</MessageText>"
			"<PatientFirstName>%@</PatientFirstName>"
			"<PatientLastName>%@</PatientLastName>"
			"<STAT>%@</STAT>"
		"</NewMsg>",
		
		[messageData valueForKey:@"AccountID"],
		[[messageData valueForKey:@"CallbackFirstName"] escapeXML],
		[[messageData valueForKey:@"CallbackLastName"] escapeXML],
		callbackPhoneNumber,
		[[messageData valueForKey:@"CallbackTitle"] escapeXML],
		[messageData valueForKey:@"HospitalID"],
		xmlRecipients,
		[[messageText componentsJoinedByString:@"\n"] escapeXML],
		[[messageData valueForKey:@"PatientFirstName"] escapeXML],
		[[messageData valueForKey:@"PatientLastName"] escapeXML],
		[messageData valueForKey:@"STAT"]
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"NewMsg" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
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
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"New Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem sending your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self sendNewMessage:messageData withOrder:sortedKeys];
			}];
			
			/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NewMessageModel Error: %@", error);
		
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
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem sending your Message." andTitle:@"New Message Error"];
		
		// If error is related to the callback number, then handle it separately
		if ([error.localizedDescription rangeOfString:@"CallbackPhone"].location != NSNotFound)
		{
			if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				// Close Activity Indicator with callback
				[self hideActivityIndicator:^
				{
					[self.delegate sendMessageError:error];
				}];
				
				return;
			}
		}
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self sendNewMessage:messageData withOrder:sortedKeys];
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

@end
