//
//  MessageRedirectInfoModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/09/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import "MessageRedirectInfoModel.h"
#import "OnCallSlotModel.h"
#import "MessageRedirectInfoXMLParser.h"

#import "MessageRecipientModel.h"
#import "OnCallSlotModel.h"

@implementation MessageRedirectInfoModel

- (void)getMessageRedirectInfoForMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	[self getMessageRedirectInfoForMessageDeliveryID:messageDeliveryID withCallback:nil];
}

- (void)getMessageRedirectInfoForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, MessageRedirectInfoModel *messageRedirectInfo, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"deliveryId"	: messageDeliveryID
	};
	
	// Show activity indicator
	[self showActivityIndicator:@"Checking Options..."];
	
	[self.operationManager GET:@"MsgRedirectInfo" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		
		MessageRedirectInfoXMLParser *parser = [[MessageRedirectInfoXMLParser alloc] init];
		
		[parser setMessageRedirectInfo:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Close activity indicator with callback
			[self hideActivityIndicator:^
			{
				// Handle success via callback
				callback(YES, self, nil);
			}];
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Redirect Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Redirect information.", NSLocalizedDescriptionKey, nil]];
			
			// Close activity indicator with callback
			[self hideActivityIndicator:^
			{
				// Handle error via callback
				callback(NO, nil, error);
			}];
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Redirect information." andTitle:@"Message Redirect Error"];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Close activity indicator with callback
			[self hideActivityIndicator:^
			{
				// Handle error via callback
				callback(NO, nil, error);
			}];
		}];
	}];
}

@end
