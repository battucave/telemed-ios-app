//
//  TeleMedHTTPRequestOperationManager.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/28/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "TeleMedHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "AFNetworkActivityLogger.h"
#import "AuthenticationModel.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

typedef void(^SuccessMainThread)(AFHTTPRequestOperation *operation, id responseObject);
typedef void(^FailureMainThread)(AFHTTPRequestOperation *operation, NSError *error);

@interface TeleMedHTTPRequestOperationManager()

@property (nonatomic) AuthenticationModel *authenticationModel;
@property (nonatomic) NSMutableArray *pendingOperations;

@end

@implementation TeleMedHTTPRequestOperationManager

+ (TeleMedHTTPRequestOperationManager *)sharedInstance
{
	static TeleMedHTTPRequestOperationManager *_sharedInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^
	{
		_sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:API_BASE_URL]];
	});
	
	return _sharedInstance;
}

- (NSUInteger)operationCount
{
	return (self.operationQueue.operationCount + [self.pendingOperations count]);
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
	if (self = [super initWithBaseURL:url])
	{
		__weak typeof(self) weakSelf = self;
		
		// Initialize AuthenticationModel
		self.authenticationModel = [AuthenticationModel sharedInstance];
		
		self.pendingOperations = [[NSMutableArray alloc] init];
		
		// Initialize Request and Response Serializers
		self.requestSerializer = [AFHTTPRequestSerializer serializer];
		self.responseSerializer = [AFXMLParserResponseSerializer serializer];
		
		// Customize Request Serializer
		[self.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringCacheData];
		[self.requestSerializer setTimeoutInterval:NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL];
		
		// Set required XML Request Headers
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
		
		// Force all HTTP methods to pass parameters in URI
		[self.requestSerializer setHTTPMethodsEncodingParametersInURI:[NSSet setWithArray:[NSArray arrayWithObjects:@"GET", @"HEAD", @"POST", @"PUT", @"PATCH", @"DELETE", nil]]];
		
		// Disable attempts to automatically respond to authentication challenge
		self.shouldUseCredentialStorage = NO;
		
		// Set up Reachability to handle offline errors
		[self.operationQueue setSuspended:YES];
		
		[self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
		{
			NSLog(@"Reachability Changed");
			
			// Suspend/Resume Queue conditionally based on Reachability
			[weakSelf.operationQueue setSuspended: ! weakSelf.reachabilityManager.isReachable];
			
			// If status changed to isReachable and any operations are queued, then refresh Access Token and execute the Queue
			if (weakSelf.reachabilityManager.isReachable)
			{
				// Delay here is required because there is a slight delay between device going back online and requests actually going through
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
				{
					[weakSelf refreshTokens];
				});
			}
		}];
		
		// Start monitoring changes in connection status
		[self.reachabilityManager startMonitoring];
		
		// Initialize Activity Logger
		#ifdef DEBUG
			[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
			//[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
			[[AFNetworkActivityLogger sharedLogger] startLogging];
		#endif
	}
	
	return self;
}

// Reset operation queue (fired when user is logged out)
- (void)doReset
{
	[self.pendingOperations removeAllObjects];
	[self.operationQueue cancelAllOperations];
	[self.operationQueue setSuspended:NO];
}

// Set Authorization Header with Access Token
- (void)setAuthorizationHeader
{
	[self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.authenticationModel.AccessToken] forHTTPHeaderField:@"Authorization"];
}

// SolutionBuilt custom method to create an authenticated request
- (NSMutableURLRequest *)HTTPRequestWithHTTPMethod:(NSString *)method
										 URLString:(NSString *)URLString
										parameters:(id)parameters
										   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Set Authorization Header before creating operation request
	[self setAuthorizationHeader];
	
	NSError *serializationError = nil;
	NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
	
	if (serializationError)
	{
		if (failure)
		{
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Wgnu"
			dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^
			{
				failure(nil, serializationError);
			});
			#pragma clang diagnostic pop
		}

		return nil;
	}

	return request;
}

// SolutionBuilt custom method to create an authenticated request with form data block
- (NSMutableURLRequest *)HTTPRequestWithHTTPMethod:(NSString *)method
										 URLString:(NSString *)URLString
										parameters:(id)parameters
						 constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
										   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Set Authorization Header before creating operation request
	[self setAuthorizationHeader];
	
	NSError *serializationError = nil;
	NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
	
	if (serializationError)
	{
		if (failure)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
			dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^
			{
				failure(nil, serializationError);
			});
#pragma clang diagnostic pop
		}

		return nil;
	}

	return request;
}

// SolutionBuilt custom method to create an authenticated request with xml body
- (NSMutableURLRequest *)HTTPRequestWithHTTPMethod:(NSString *)method
										 URLString:(NSString *)URLString
										parameters:(id)parameters
						   constructingBodyWithXML:(NSString *)xmlBody
										   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Set Authorization Header before creating operation request
	[self setAuthorizationHeader];
	
	NSError *serializationError = nil;
	NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
	
	[request setHTTPBody:[xmlBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (serializationError)
	{
		if (failure)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
			dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^
			{
				failure(nil, serializationError);
			});
#pragma clang diagnostic pop
		}
		
		return nil;
	}

	return request;
}

// Override GET method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)GET:(NSString *)URLString
					 parameters:(id)parameters
						success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Shorten timeout for GET requests
	if (self.requestSerializer.timeoutInterval == NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL)
	{
		[self.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"GET" URLString:URLString parameters:parameters failure:failure];
	
	// Restore timeout interval to default
	[self.requestSerializer setTimeoutInterval:NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}

// Override HEAD method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)HEAD:(NSString *)URLString
					  parameters:(id)parameters
						 success:(void (^)(AFHTTPRequestOperation *operation))success
						 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Shorten timeout for HEAD requests
	if (self.requestSerializer.timeoutInterval == NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL)
	{
		[self.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"HEAD" URLString:URLString parameters:parameters failure:failure];
	
	// Restore timeout interval to default
	[self.requestSerializer setTimeoutInterval:NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL];
	
	return [self addAuthenticatedRequest:request success:^(AFHTTPRequestOperation *requestOperation, __unused id responseObject)
	{
		if (success)
		{
			success(requestOperation);
		}
	} failure:failure];
}


// Override POST method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)POST:(NSString *)URLString
					  parameters:(id)parameters
						 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"POST" URLString:URLString parameters:parameters failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}


// Override POST constructingBodyWithBlock method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)POST:(NSString *)URLString
					  parameters:(id)parameters
	   constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
						 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"POST" URLString:URLString parameters:parameters constructingBodyWithBlock:block failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}

// SolutionBuilt custom method to POST with an XML string as body
- (AFHTTPRequestOperation *)POST:(NSString *)URLString
					  parameters:(id)parameters
		constructingBodyWithXML:(NSString *)xmlBody
						 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"POST" URLString:URLString parameters:parameters constructingBodyWithXML:xmlBody failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}

// Override PUT method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
					 parameters:(id)parameters
						success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"PUT" URLString:URLString parameters:parameters failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}


// Override PATCH method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)PATCH:(NSString *)URLString
					   parameters:(id)parameters
						  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"PATCH" URLString:URLString parameters:parameters failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}


// Override DELETE method to authenticate with token before adding to queue
- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString
						parameters:(id)parameters
						   success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
						   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// Prevent request if device is offline
	if (! self.reachabilityManager.isReachable)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"The device is currently offline.", NSLocalizedDescriptionKey, nil]];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			failure(nil, error);
		});
		
		return nil;
	}
	
	NSMutableURLRequest *request = [self HTTPRequestWithHTTPMethod:@"DELETE" URLString:URLString parameters:parameters failure:failure];
	
	return [self addAuthenticatedRequest:request success:success failure:failure];
}

- (SuccessMainThread)wrapSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
{
	// Automatically update success callback to run on main thread
	return ^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Add all Pending Operations to the Queue
		[self processPendingOperations];
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			success(operation, responseObject);
		});
	};
}

- (FailureMainThread)wrapFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success isRetry:(BOOL)isRetry
{
	return ^(AFHTTPRequestOperation *operation, NSError *error)
	{
		// Re-wrap failure callback with additional logic for 401 Not Authorized and device connection issues and put it in main queue
		FailureMainThread wrappedFailure = [self wrapFailure:failure success:success isRetry:YES];
		
		// Create new operation with updated authorization header
		AFHTTPRequestOperation *newOperation = [self duplicateOperation:operation success:success failure:wrappedFailure];
		
		// If response returned 401 Not Authorized Error
		if (operation.response.statusCode == 401)
		{
			// Request has already been retried so refresh token is now invalid. Redirect to login to re-authenticate
			if (isRetry)
			{
				NSLog(@"Redirect to LoginSSO");
				
				dispatch_async(dispatch_get_main_queue(), ^
				{
					AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
					
					// Clear stored authentication data
					[self.authenticationModel doLogout];
					
					// Go to login screen
					[appDelegate goToLoginScreen];
				});
			}
			// Attempt to obtain a new Access Token and retry the operation
			else
			{
				NSLog(@"Refresh Token and Retry Operation");
				
				[self.authenticationModel setAccessToken:nil];
				
				[self addAuthenticatedOperation:newOperation success:success failure:wrappedFailure];
			}
		}
		// If the operation failed because device is definitely offline, then retry the operation after a short delay (NSURLErrorNotConnectedToInternet sometimes mistakenly occurs immediately after device goes back online)
		else if (error.code == NSURLErrorNotConnectedToInternet && ! isRetry)
		{
			NSLog(@"Retry Operation");
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
				[self addAuthenticatedOperation:newOperation success:success failure:wrappedFailure];
			});
		}
		else
		{
			// If device is definitely offline even after a retry, then set offline error (do not show on NSURLErrorTimedOut)
			if (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorNetworkConnectionLost/* || error.code == NSURLErrorTimedOut*/)
			{
				NSLog(@"Offline Error - Add to Pending Operations");
				
				// Add stored operation to pending operations to be executed after user re-establishes connection
				[self addPendingOperation:newOperation success:success failure:failure];
				
				// Control offline errors by setting them to a standard code
				error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:error.userInfo];
			}
			
			// Execute original failure block
			dispatch_async(dispatch_get_main_queue(), ^
			{
				failure(operation, error);
			});
		}
	};
}

- (AFHTTPRequestOperation *)addAuthenticatedRequest:(NSMutableURLRequest *)request success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSLog(@"Add Authenticated Request: %@", [[request URL] absoluteString]);
	
	// Wrap success callback to put it in main queue
	SuccessMainThread wrappedSuccess = [self wrapSuccess:success];
	
	// Wrap failure callback with additional logic for 401 Not Authorized and device connection issues and put it in main queue
	FailureMainThread wrappedFailure = [self wrapFailure:failure success:success isRetry:NO];
	
	// Create new operation from request
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:wrappedSuccess failure:wrappedFailure];
	
	[self addAuthenticatedOperation:operation success:wrappedSuccess failure:failure];
	
	return operation;
}

// Add valid Authentication Bearer Token to operation before adding it to the Queue
- (void)addAuthenticatedOperation:operation success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	// If Access Token is still valid, immediately execute the request operation
	if (self.authenticationModel.accessTokenIsValid)
	{
		NSLog(@"Access Token still valid");
		
		[self.operationQueue addOperation:operation];
		
		return;
	}
	
	// Pause the queue while refreshing Tokens
	[self.operationQueue setSuspended:YES];
	
	// Add stored operation to pending operations to be executed after user re-establishes authentication
	[self addPendingOperation:operation success:success failure:failure];
	
	NSLog(@"Obtain new Access Token");
	
	[self refreshTokens];
}

- (void)addPendingOperation:(AFHTTPRequestOperation *)operation success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = operation.request;
	
	// Verify whether the request has already been added as a Pending Operation
	if ([self.pendingOperations count] > 0)
	{
		for (NSDictionary *pendingOperation in self.pendingOperations)
		{
			// If the request already exists, don't add it to Pending Operations
			if ([[request.URL absoluteString] isEqualToString:(NSString *)[pendingOperation objectForKey:@"url"]])
			{
				return;
			}
		}
	}
	
	NSLog(@"Add to Pending Operations: %@", [[request URL] absoluteString]);
	
	// Store operation with its success and failure callbacks for future execution (have to do it this way because there is no way to modify headers of an already created AFHTTPOperation)
	NSDictionary *pendingOperation = @{
		@"operation"	: operation,
		@"url"			: [request.URL absoluteString],
		@"success"		: success,
		@"failure"		: failure
	};
	
	// Add stored operation to pending operations to be executed after user re-establishes authentication
	[self.pendingOperations addObject:pendingOperation];
}

- (AFHTTPRequestOperation *)duplicateOperation:(AFHTTPRequestOperation *)originalOperation success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSMutableURLRequest *request = [originalOperation.request mutableCopy];
	
	[request setValue:[NSString stringWithFormat:@"Bearer %@", self.authenticationModel.AccessToken] forHTTPHeaderField:@"Authorization"];
	
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
	
	// Add any dependencies from original operation to new operation
	if ([originalOperation.dependencies count] > 0)
	{
		for (NSOperation *dependency in originalOperation.dependencies)
		{
			[operation addDependency:dependency];
		}
	}
	
	return operation;
}

- (void)refreshTokens
{
	// Create a success callback that sets the Authorization Header with new Access Token and executes the original request(s)
	void (^authenticationSuccess)(void) = ^
	{
		// Set Authorization Header with new Access Token
		[self setAuthorizationHeader];
		
		// Resume the queue
		[self.operationQueue setSuspended:NO];
		
		// Add all Pending Operations to the Queue
		[self processPendingOperations];
		
		// Turn off AuthenticationModel's isWorking only after everything is done
		self.authenticationModel.isWorking = NO;
	};
	
	// Create a failure callback that runs the failure method of each pending operation
	void (^authenticationFailure)(NSError *error) = ^(NSError *error)
	{
		// Active operations will automatically execute their failure block when they are cancelled so no need to attempt to do this manually
		
		// Pending operations need to have their failure block executed manually. Note that we only cancel POST, PUT, PATCH, and DELETE operations - GET and HEAD operations will still fire when tokens are refreshed. But we are firing off it's failure block to allow the delegate to execute any necessary activities.
		[self processPendingFailures:error];
		
		// Resume Operation Queue after a delay (if operation simply timed out rather than it being offline, then Operation Queue will never get reset otherwise)
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			[self.operationQueue setSuspended:NO];
			
			// Turn off AuthenticationModel's isWorking only after everything is done
			self.authenticationModel.isWorking = NO;
		});
	};
	
	// If there are pending operations and AuthenticationModel is not already in the process of refreshing tokens, then refresh tokens using our Refresh Token
	if ([self.pendingOperations count] > 0 && ! self.authenticationModel.isWorking)
	{
		[self.authenticationModel getNewTokensWithSuccess:authenticationSuccess failure:authenticationFailure];
	}
	else if (self.authenticationModel.isWorking)
	{
		// Dispatch AFNetworkingOperationDidStartNotification as shortcut to force models to execute pending callbacks
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];
		});
	}
}

- (void)processPendingOperations
{
	// Add all Pending Operations to the Queue (have to do it this way because there is no way to modify headers of an already created AFHTTPOperation)
	if ([self.pendingOperations count] > 0)
	{
		NSLog(@"Authentication Success Pending Operations: %lu", (unsigned long)[self.pendingOperations count]);
		
		for (NSDictionary *pendingOperation in self.pendingOperations)
		{
			// Recreate the AFHTTPRequestOperation with an updated NSURLRequest that includes a new Authorization Header with new Access Token
			AFHTTPRequestOperation *newOperation = [self duplicateOperation:(AFHTTPRequestOperation *)[pendingOperation objectForKey:@"operation"] success:[pendingOperation objectForKey:@"success"] failure:[pendingOperation objectForKey:@"failure"]];
			
			[self.operationQueue addOperation:newOperation];
		}
		
		[self.pendingOperations removeAllObjects];
	}
}

- (void)processPendingFailures:(NSError *)error
{
	// Pending operations need to have their failure block executed manually. Note that we are not cancelling the operation - it will still fire when tokens are refreshed. But we are firing off it's failure block to allow the delegate to execute any necessary activities.
	if ([self.pendingOperations count] > 0)
	{
		NSLog(@"Authentication Failure Pending Operations: %lu", (unsigned long)[self.pendingOperations count]);
		
		NSMutableArray *deletePendingOperations = [[NSMutableArray alloc] init];
		
		// for (NSDictionary *pendingOperation in self.pendingOperations) // Have to do it with regular for loop to avoid "NSArray was mutated while being enumerated" error
		for (int i = 0; i < [self.pendingOperations count]; i++)
		{
			NSDictionary *pendingOperation = self.pendingOperations[i];
			
			AFHTTPRequestOperation *operation = [pendingOperation objectForKey:@"operation"];
			void (^pendingFailure)(AFHTTPRequestOperation *operation, NSError *error) = [pendingOperation objectForKey:@"failure"];
			
			pendingFailure([pendingOperation objectForKey:@"operation"], error);
			
			// If operation is a POST, PUT, PATCH, or DELETE request, then remove it from pending operations
			if (! [operation.request.HTTPMethod isEqualToString:@"GET"] && ! [operation.request.HTTPMethod isEqualToString:@"HEAD"])
			{
				[deletePendingOperations addObject:pendingOperation];
			}
		}
		
		// Remove POST, PUT, PATCH, and DELETE requests from pending operations
		if ([deletePendingOperations count] > 0)
		{
			[self.pendingOperations removeObjectsInArray:deletePendingOperations];
		}
	}
}

@end
