//
//  PreferredAccountModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "PreferredAccountModel.h"
#import "AccountModel.h"
#import "MyProfileModel.h"

@interface PreferredAccountModel ()

@property (nonatomic) MyProfileModel *myProfileModel;

@property (nonatomic) AccountModel *preferredAccount;
@property (nonatomic) BOOL pendingComplete;

@end

@implementation PreferredAccountModel

- (void)savePreferredAccount:(AccountModel *)account
{
	// Initialize MyProfileModel
	[self setMyProfileModel:[MyProfileModel sharedInstance]];
	
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store preferred account to be used when network request is sent
	[self setPreferredAccount:account];
	
	NSDictionary *parameters = @{
		@"accountID"	: account.ID,
	};
	
	[self.operationManager POST:@"PreferredAcct" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountSuccess)])
			{
				[self.delegate savePreferredAccountSuccess];
			}
		}
		else
		{
			// Roll back MyProfileModel's my preferred account to previous value
			[self.myProfileModel restoreMyPreferredAccount];
			
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Preferred Account Error", NSLocalizedFailureReasonErrorKey, @"There was a problem changing your Preferred Account.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self savePreferredAccount:account];
			}];
			
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountError:)])
			{
				[self.delegate savePreferredAccountError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"PasswordChangeModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem changing your Preferred Account." andTitle:@"Preferred Account Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Roll back MyProfileModel's MyPreferredAccount to previous value
			[self.myProfileModel restoreMyPreferredAccount];
			
			// Handle error via delegate
			/* if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountError:)])
			{
				[self.delegate savePreferredAccountError:error];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self savePreferredAccount:account];
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
		// Save preferred account to MyProfileModel (assume success so save it immediately and then roll back if error occurs)
		[self.myProfileModel setMyPreferredAccount:self.preferredAccount];
		
		// Notify delegate that message has been sent to server
		if (! self.pendingComplete && self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountPending)])
		{
			[self.delegate savePreferredAccountPending];
		};
		
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

@end
