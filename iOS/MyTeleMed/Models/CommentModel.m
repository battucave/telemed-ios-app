//
//  CommentModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CommentModel.h"
#import "MessageProtocol.h"
#import "NSString+XML.h"

@interface CommentModel ()

@property (nonatomic) NSString *comment;
@property (nonatomic) NSNumber *pendingID;
//@property (nonatomic) BOOL pendingComplete;

@end

@implementation CommentModel

- (void)addMessageComment:(id <MessageProtocol>)message comment:(NSString *)comment withPendingID:(NSNumber *)pendingID
{
	[self addMessageComment:message comment:comment withPendingID:pendingID toForwardMessage:NO];
}

- (void)addMessageComment:(id <MessageProtocol>)message comment:(NSString *)comment toForwardMessage:(BOOL)toForwardMessage
{
	[self addMessageComment:message comment:comment withPendingID:nil toForwardMessage:toForwardMessage];
}

- (void)addMessageComment:(id <MessageProtocol>)message comment:(NSString *)comment withPendingID:(NSNumber *)pendingID toForwardMessage:(BOOL)toForwardMessage
{
	// Show Activity Indicator only if not being added with Forward Message
	if ( ! toForwardMessage)
	{
		[self showActivityIndicator];
	}
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store comment and ID for saveCommentPending method
	self.comment = comment;
	self.pendingID = pendingID;
	
	NSString *xmlBody = @"<Comment xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<CommentText>%1$@</CommentText>"
			"<%2$@>%3$@</%2$@>"
		"</Comment>";
	
	// Comment with Message Delivery ID
	if ([message respondsToSelector:@selector(MessageDeliveryID)] && message.MessageDeliveryID)
	{
		xmlBody = [NSString stringWithFormat: xmlBody, [comment escapeXML], @"MessageDeliveryID", message.MessageDeliveryID];
	}
	// Comment with Message ID
	else if (message.MessageID)
	{
		xmlBody = [NSString stringWithFormat: xmlBody, [comment escapeXML], @"MessageID", message.MessageID];
	}
	// Message must contain either MessageDeliveryID or MessageID
	else
	{
		NSString *errorMessage = (toForwardMessage ? @"Message forward successfully, but there was a problem adding your comment. Please retry your comment on the Message Detail screen." : @"There was a problem adding your Comment.");
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Add Comment Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
		
		// Show error (user cannot have navigated to another screen at this point)
		[self showError:error];
		
		// Still being used
		if ([self.delegate respondsToSelector:@selector(saveCommentError:withPendingID:)])
		{
			[self.delegate saveCommentError:error withPendingID:pendingID];
		}
	}
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"Comments" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Still being used
			if ([self.delegate respondsToSelector:@selector(saveCommentSuccess:withPendingID:)])
			{
				[self.delegate saveCommentSuccess:comment withPendingID:pendingID];
			}
		}
		else
		{
			NSString *errorMessage = (toForwardMessage ? @"Message forwarded successfully, but there was a problem adding your comment. Please retry your comment on the Message Detail screen." : @"There was a problem adding your Comment.");
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Add Comment Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self addMessageComment:message comment:comment withPendingID:pendingID toForwardMessage:toForwardMessage];
			}];
			
			// Still being used
			if ([self.delegate respondsToSelector:@selector(saveCommentError:withPendingID:)])
			{
				[self.delegate saveCommentError:error withPendingID:pendingID];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CommentModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Still being used
		if ([self.delegate respondsToSelector:@selector(saveCommentError:withPendingID:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate saveCommentError:error withPendingID:pendingID];
			}];
		}
		else
		{
			// Close Activity Indicator
			[self hideActivityIndicator];
		}
	
		// Build a generic error message
		NSString *errorMessage = (toForwardMessage ? @"Message forwarded successfully, but there was a problem adding your comment. Please retry your comment on the Message Detail screen." : @"There was a problem adding your Comment.");
		error = [self buildError:error usingData:operation.responseData withGenericMessage:errorMessage andTitle:@"Add Comment Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self addMessageComment:message comment:comment withPendingID:pendingID toForwardMessage:toForwardMessage];
		}];
	}];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Comment has been sent to server
	if (/* ! self.pendingComplete &&*/ [self.delegate respondsToSelector:@selector(saveCommentPending:withPendingID:)])
	{
		// Close Activity Indicator with callback
		[self hideActivityIndicator:^
		{
			[self.delegate saveCommentPending:self.comment withPendingID:self.pendingID];
		}];
	}
	else
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	//self.pendingComplete = YES;
}

@end
