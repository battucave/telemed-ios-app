//
//  AuthenticationModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/22/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AuthenticationModel.h"
#import "AppDelegate.h"
#import "AuthenticationHTTPSessionManager.h"
#import "KeychainItemWrapper.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "ProfileProtocol.h"
#import "AuthenticationXMLParser.h"

#ifdef MYTELEMED
	#import "MyProfileModel.h"
#endif

#ifdef MED2MED
	#import "UserProfileModel.h"
#endif

@interface AuthenticationModel()

@property (nonatomic) NSDate *AccessTokenExpiration;

@end

@implementation AuthenticationModel

@synthesize AccessToken = _AccessToken;
@synthesize RefreshToken = _RefreshToken;

@synthesize AccessTokenExpiration = _AccessTokenExpiration;

+ (instancetype)sharedInstance
{
	static dispatch_once_t token;
	static AuthenticationModel *sharedAuthenticationInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedAuthenticationInstance = [[self alloc] init];
	});
	
	return sharedAuthenticationInstance;
}

- (id)init
{
	if (self = [super init])
	{
		// TEMPORARY: (Version 3.3) - Remove old login keychain items - This logic can be removed in a future update
		KeychainItemWrapper *keyChainLogin = [[KeychainItemWrapper alloc] initWithIdentifier:@"Login" accessGroup:nil];
		
		[keyChainLogin resetKeychainItem];
	}
	
	return self;
}

// Override RefreshToken getter
- (NSString *)RefreshToken
{
	// If refresh token is not already set, check keychain
	if (! _RefreshToken)
	{
		KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
		
		_RefreshToken = [keyChainRefreshToken objectForKey:(__bridge id)kSecValueData];
		
		if ([_RefreshToken isEqualToString:@""])
		{
			_RefreshToken = nil;
		}
	}
	
	return _RefreshToken;
}

// Override AccessToken setter to also store access token's expiration
- (void)setAccessToken:(NSString *)newAccessToken
{
	if (_AccessToken != newAccessToken)
	{
		_AccessTokenExpiration = nil;
		
		if (newAccessToken != nil)
		{
			_AccessTokenExpiration = [[NSDate date] dateByAddingTimeInterval:ACCESS_TOKEN_EXPIRATION_TIME];
		}
		
		_AccessToken = newAccessToken;
	}
}

// Override RefreshToken setter to store value in keychain
- (void)setRefreshToken:(NSString *)newRefreshToken
{
	if (_RefreshToken != newRefreshToken)
	{
		KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
		
		[keyChainRefreshToken setObject:newRefreshToken forKey:(__bridge id)(kSecValueData)];
		[keyChainRefreshToken setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
		
		_RefreshToken = newRefreshToken;
	}
}

// Public method
- (void)getNewTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
	[self getNewTokensWithSuccess:success failure:failure isRetry:NO];
}

// Private method with internal retry mechanism
- (void)getNewTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure isRetry:(BOOL)isRetry
{
	// If no refresh token found, then tokens cannot be refreshed
	if (! self.RefreshToken)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self doLogout];
		});
		
		return;
	}
	
	AuthenticationHTTPSessionManager *authenticationManager = [AuthenticationHTTPSessionManager sharedInstance];
	
	// Turn on isWorking
	self.isWorking = YES;
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<AuthNToken xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/AuthZ.Models\">"
			"<AccessToken>%@</AccessToken>"
			"<RefreshToken>%@</RefreshToken>"
		"</AuthNToken>",
		
		(self.AccessToken ?: @""),
		self.RefreshToken
	];
	
	NSLog(@"Get New Access and Refresh Tokens");
	//NSLog(@"XML Body: %@", xmlBody);
	
	[authenticationManager PUT:@"AuthN" parameters:nil constructingBodyWithXML:xmlBody success:^(__unused NSURLSessionDataTask *task, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		AuthenticationXMLParser *parser = [[AuthenticationXMLParser alloc] init];
		
		[parser setAuthentication:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Set tokens if found in response
			if (! [self.AccessToken isEqualToString:@""] && ! [self.RefreshToken isEqualToString:@""])
			{
				NSLog(@"New Access Token: %@", self.AccessToken);
				NSLog(@"New Refresh Token: %@", self.RefreshToken);
				
				// Run success callback
				return success();
			}
		}
		
		// Tokens not found in response or error parsing the xml file
		NSLog(@"Error Refreshing Tokens");
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			// Turn off isWorking
			self.isWorking = NO;
			
			[self doLogout];
		});
	}
	failure:^(__unused NSURLSessionDataTask *task, NSError *error)
	{
		AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		UIStoryboard *currentStoryboard = appDelegate.window.rootViewController.storyboard;
		NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
		
		NSData *data = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
		
		NSLog(@"Refresh Tokens Error %ld: %@", (long)error.code, [[NSString alloc] initWithData:[NSData dataWithData:data] encoding:NSUTF8StringEncoding]);
		
		// First retry the operation again after a delay
		if (! isRetry)
		{
			NSLog(@"Retry Refreshing Tokens");
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
				[self getNewTokensWithSuccess:success failure:failure isRetry:YES];
			});
		}
		// Handle timeout issues differently if not in login sso storyboard
		else if (! [currentStoryboardName isEqualToString:@"LoginSSO"] && (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorTimedOut))
		{
			NSLog(@"Refreshing Tokens Timed Out: %@", error);
			
			// Turn off isWorking
			self.isWorking = NO;
			
			// Control timeout errors by setting them to a standard code (except for NSURLErrorTimedOut)
			if (error.code != NSURLErrorTimedOut)
			{
				error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorNotConnectedToInternet userInfo:error.userInfo];
			}
			
			failure(error);
		}
		// If error is not related to device being offline, then refresh token is no longer valid so force the user to login again
		else
		{
			NSLog(@"Error Refreshing Tokens: %@", error);
			
			dispatch_async(dispatch_get_main_queue(), ^
			{
				// Turn off isWorking
				self.isWorking = NO;
				
				[self doLogout];
			});
		}
	}];
	
	// Dispatch AFNetworkingOperationDidStartNotification as shortcut to force models to execute pending callbacks
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];
	});
}

- (BOOL)accessTokenIsValid
{
	return self.AccessToken && [[NSDate date] compare:self.AccessTokenExpiration] == NSOrderedAscending;
}

- (void)doLogout
{
	KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	TeleMedHTTPRequestOperationManager *operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	
	// Reset refresh token in keychain
	[keyChainRefreshToken resetKeychainItem];
	
	// Reset operation manager
	[operationManager doReset];
	
	// Reset tokens in app
	self.AccessToken = nil;
	self.AccessTokenExpiration = nil;
	self.RefreshToken = nil;
	
	// Update profile's authenticated flag
	#ifdef MYTELEMED
		[[MyProfileModel sharedInstance] setIsAuthenticated:NO];

	#elif defined MED2MED
		[[UserProfileModel sharedInstance] setIsAuthenticated:NO];
	#endif
	
	// Go to LoginSSOViewController
	[appDelegate goToNextScreen];
}

@end
