//
//  CommentModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CommentModel.h"

@implementation CommentModel

- (void)addMessageComment:(NSNumber *)messageID comment:(NSString *)comment
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<Comment xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<CommentText>%@</CommentText>"
			"<MessageDeliveryID>%@</MessageDeliveryID>"
		"</Comment>",
		comment, messageID];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"Comments" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(saveCommentSuccess:)])
			{
				[self.delegate saveCommentSuccess:comment];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem adding your Comment.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(saveCommentError:)])
			{
				[self.delegate saveCommentError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CommentModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem adding your Comment."];
		
		if([self.delegate respondsToSelector:@selector(saveCommentError:)])
		{
			[self.delegate saveCommentError:error];
		}
	}];
}

@end
