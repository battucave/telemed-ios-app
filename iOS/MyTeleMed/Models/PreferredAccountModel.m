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
	// Initialize My Profile Model
	[self setMyProfileModel:[MyProfileModel sharedInstance]];
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Store Preferred Account to be used when network request is sent
	[self setPreferredAccount:account];
	
	NSDictionary *parameters = @{
		@"accountID"	: account.ID,
	};
	
	[self.operationManager POST:@"PreferredAcct" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Not currently used
			if ([self.delegate respondsToSelector:@selector(savePreferredAccountSuccess)])
			{
				[self.delegate savePreferredAccountSuccess];
			}
		}
		else
		{
			// Roll back My Profile Model's MyPreferredAccount to previous value
			[self.myProfileModel restoreMyPreferredAccount];
			
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Preferred Account Error", NSLocalizedFailureReasonErrorKey, @"There was a problem changing your Preferred Account.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^(void)
			{
				// Include callback to retry the request
				[self savePreferredAccount:account];
			}];
			
			/*if ([self.delegate respondsToSelector:@selector(changePasswordError:)])
			{
				[self.delegate changePasswordError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"PasswordChangeModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Roll back My Profile Model's MyPreferredAccount to previous value
		[self.myProfileModel restoreMyPreferredAccount];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem changing your Preferred Account." andTitle:@"Preferred Account Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^(void)
		{
			// Include callback to retry the request
			[self savePreferredAccount:account];
		}];
		
		/*if ([self.delegate respondsToSelector:@selector(changePasswordError:)])
		{
			[self.delegate changePasswordError:error];
		}*/
	}];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Close Activity Indicator
	[self hideActivityIndicator];
	
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Save Preferred Account to My Profile Model (assume success so save it immediately and then roll back if error occurs)
	[self.myProfileModel setMyPreferredAccount:self.preferredAccount];
	
	// Notify delegate that Message has been sent to server
	if ( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(savePreferredAccountPending)])
	{
		[self.delegate savePreferredAccountPending];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
