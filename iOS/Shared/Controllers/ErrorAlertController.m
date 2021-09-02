//
//  ErrorAlertController.m
//  TeleMed
//
//  Created by Shane Goodwin on 11/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <CallKit/CallKit.h>

#import "ErrorAlertController.h"

@interface ErrorAlertController ()

@property (nonatomic, strong) ErrorAlertController *offlineAlertController;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSMutableArray *windows;
@property (nonatomic, strong) NSDate *dateLastOfflineError;
@property (nonatomic) BOOL isErrorAlertShowing;

@end

@implementation ErrorAlertController

+ (instancetype)sharedInstance
{
	static dispatch_once_t token;
	static ErrorAlertController *sharedAlertInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedAlertInstance = [[self alloc] init];
		
		sharedAlertInstance.windows = [NSMutableArray arrayWithCapacity:0];
	});
	
	return sharedAlertInstance;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove this window from stack
	[ErrorAlertController.sharedInstance.windows removeObject:self.window];
	
	// Set alpha to 1.0 for last alert to make it appear
	[UIView animateWithDuration:0.3 animations:^
	{
		[ErrorAlertController.sharedInstance.windows.lastObject setAlpha:1.0];
	}];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Remove window property
	[self.window setHidden:YES];
	self.window = nil;
}

- (instancetype)show:(NSError *)error
{
	NSLog(@"Show: %@", error.localizedDescription);
	
	// If device offline, show offline message
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
		return [self showOffline];
	}
	
	// Configure alert controller
	ErrorAlertController *alertController = [ErrorAlertController alertControllerWithTitle:error.localizedFailureReason message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	
	[alertController addAction:okAction];
	
	// Show alert
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[alertController presentAlertController:YES completion:nil];
	});
	
	return alertController;
}

- (instancetype)show:(NSError *)error withRetryCallback:(void (^)(void))callback
{
	return [self show:error withRetryCallback:callback cancelCallback:nil];
}

- (instancetype)show:(NSError *)error withRetryCallback:(void (^)(void))retryCallback cancelCallback:(void (^)(void))cancelCallback
{
	NSLog(@"Show withCallback: %@", error.localizedDescription);
	
	NSString *errorMessage = error.localizedDescription;
	
	// If device offline, add offline message
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
		errorMessage = [NSString stringWithFormat:@"%@ %@", errorMessage, [self getOfflineMessage]];
	}
	
	// Configure alert controller
	ErrorAlertController *alertController = [ErrorAlertController alertControllerWithTitle:error.localizedFailureReason message:[NSString stringWithFormat:@"%@\nWould you like to try again?", errorMessage] preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
	{
		// Execute callback
		dispatch_async(dispatch_get_main_queue(), ^
		{
			if (cancelCallback)
			{
				cancelCallback();
			}
		});
	}];
	UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Execute callback
		dispatch_async(dispatch_get_main_queue(), ^
		{
			if (retryCallback)
			{
				retryCallback();
			}
		});
	}];
	
	[alertController addAction:retryAction];
	[alertController addAction:cancelAction];
	
	// Set preferred action
	[alertController setPreferredAction:retryAction];
	
	// Show alert
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[alertController presentAlertController:YES completion:nil];
	});
	
	return alertController;
}

- (instancetype)showOffline
{
	NSString *alertMessage = [self getOfflineMessage];
	
	NSLog(@"Offline Error Message: %@", alertMessage);
	
	// Only show error message if it has never been shown or has been 2+ seconds since last shown
	if (! self.dateLastOfflineError || [[NSDate date] compare:[self.dateLastOfflineError dateByAddingTimeInterval:2.0]] == NSOrderedDescending)
	{
		if (! self.isErrorAlertShowing)
		{
			// Configure alert controller
			self.offlineAlertController = [ErrorAlertController alertControllerWithTitle:@"Data Connection Unavailable" message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				// Toggle error alert to show again
				self.isErrorAlertShowing = NO;
			}];
			
			[self.offlineAlertController addAction:okAction];
			
			// Show alert
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.offlineAlertController presentAlertController:YES completion:nil];
			});
			
			// Toggle error alert to not re-show
			self.isErrorAlertShowing = YES;
		}
		
		// Update last time error message was shown
		self.dateLastOfflineError = [NSDate date];
	}
	
	return self.offlineAlertController;
}

- (void)dismiss
{
	// Only dismiss offline error messages without callbacks
	[self.offlineAlertController dismissViewControllerAnimated:YES completion:nil];
	
	// Toggle error alert to show again
	self.isErrorAlertShowing = NO;
}

- (void)presentAlertController:(BOOL)animated completion:(void (^ _Nullable)(void))completion
{
	// Configure new window from which to present alert
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
	
	[self.window setRootViewController:[[UIViewController alloc] init]];
	[self.window setWindowLevel:topWindow.windowLevel + 1];
	
	// Show alert
	[self.window makeKeyAndVisible];
	[self.window.rootViewController presentViewController:self animated:animated completion:completion];
	
	// Set alpha to 0.0 for last alert to make it appear as though there is only a single alert at one time
	[ErrorAlertController.sharedInstance.windows.lastObject setAlpha:0.0];
	[ErrorAlertController.sharedInstance.windows addObject:self.window];
}

- (NSString *)getOfflineMessage
{
	CXCallObserver *callObserver = [CXCallObserver new];
	NSString *offlineMessage = @"You must connect to a Wi-Fi or cellular data network to continue.";
	
	// Update messaging if a call is currently connected
	for (CXCall *call in callObserver.calls)
	{
		if (! call.hasEnded)
		{
			offlineMessage = @"Your device does not support simultaneous voice and cellular data connections. You must connect to a Wi-Fi network to continue.";
		}
	}
	
	return offlineMessage;
}

@end
