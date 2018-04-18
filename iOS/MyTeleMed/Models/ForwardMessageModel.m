//
//  ForwardMessageModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "ForwardMessageModel.h"
#import "MessageProtocol.h"
#import "CommentModel.h"

@interface ForwardMessageModel ()

@property (nonatomic) BOOL pendingComplete;

@end

@implementation ForwardMessageModel

- (void)forwardMessage:(id <MessageProtocol>)message messageRecipientIDs:(NSArray *)messageRecipientIDs withComment:(NSString *)comment
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSMutableString *xmlRecipients = [[NSMutableString alloc] init];
	
	for(NSString *messageRecipientID in messageRecipientIDs)
	{
		[xmlRecipients appendString:[NSString stringWithFormat:@"<d2p1:long>%@</d2p1:long>", messageRecipientID]];
	}
	
	NSString *xmlBody = @"<FwdMsg xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<%1$@>%2$@</%1$@>"
			"<MessageRecipients xmlns:d2p1=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
				"%3$@"
			"</MessageRecipients>"
		"</FwdMsg>";
	
	// Forward with Message Delivery ID
	if ([message respondsToSelector:@selector(MessageDeliveryID)] && message.MessageDeliveryID)
	{
		xmlBody = [NSString stringWithFormat:xmlBody, @"MessageDeliveryID", message.MessageDeliveryID, xmlRecipients];
	}
	// Forward with Message ID
	else if (message.MessageID)
	{
		xmlBody = [NSString stringWithFormat:xmlBody, @"MessageID", message.MessageID, xmlRecipients];
	}
	// Message must contain either MessageDeliveryID or MessageID
	else
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Forward Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem forwarding your Message.", NSLocalizedDescriptionKey, nil]];
			
		// Show error (user cannot have navigated to another screen at this point)
		[self showError:error];
	}
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"FwdMsgs" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Add comment if present
			if ( ! [comment isEqualToString:@""])
			{
				CommentModel *commentModel = [[CommentModel alloc] init];
				
				[commentModel addMessageComment:message comment:comment toForwardMessage:YES];
			}
			
			// Handle success via delegate (not currently used)
			if ([self.delegate respondsToSelector:@selector(sendMessageSuccess)])
			{
				[self.delegate sendMessageSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Forward Message Error", NSLocalizedFailureReasonErrorKey, @"There was a problem forwarding your Message.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self forwardMessage:message messageRecipientIDs:messageRecipientIDs withComment:comment];
			}];
			
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
			{
				[self.delegate sendMessageError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"ForwardMessageModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Handle error via delegate
		/* if ([self.delegate respondsToSelector:@selector(sendMessageError:)])
		{
			// Close activity indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate sendMessageError:error];
			}];
		}
		else
		{*/
			// Close activity indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem forwarding your Message." andTitle:@"Forward Message Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self forwardMessage:message messageRecipientIDs:messageRecipientIDs withComment:comment];
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
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate sendMessagePending];
		}];
	}
	else
	{
		// Close activity indicator
		[self hideActivityIndicator];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
