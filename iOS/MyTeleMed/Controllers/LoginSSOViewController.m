//
//  LoginSSOViewController.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/20/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "LoginSSOViewController.h"
#import "PhoneNumberViewController.h"
#import "AppDelegate.h"
#import "ELCUIApplication.h"
#import "AuthenticationModel.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"
#import "SSOProviderModel.h"

@interface LoginSSOViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isRetry;

@end

@implementation LoginSSOViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Initialize WebView
	[self initLogin];
	
	// Set is loading to false
	self.isLoading = NO;
	
	// Add Reachability Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWebView:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Stop WebView
	[self.webView stopLoading];
	
	 // Remove Reachability Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
}

// Unwind Segue from PhoneNumberViewController
- (IBAction)unwindFromPhoneNumber:(UIStoryboardSegue *)segue
{
	NSLog(@"unwindFromPhoneNumber");
}

// Unwind Segue from SSOProviderViewController
- (IBAction)unwindFromSSOProvider:(UIStoryboardSegue *)segue
{
	NSLog(@"unwindFromSSOProvider");
}

- (IBAction)goBackWebView:(id)sender
{
	[self.webView goBack];
}

- (IBAction)refreshWebView:(id)sender
{
	// If webview is loading, let it finish before refreshing again
	if(self.isLoading)
	{
		return;
	}
	
	// Set is loading to true
	self.isLoading = YES;
	
	// If webview is currently showing a blank screen or error message, then redirect to login page
	if([self.webView.request.URL.absoluteString isEqualToString:@"about:blank"])
	{
		// Show Loading Screen
		[self updateWebViewLoading:YES];
		
		// Delay is here is required because there is a slight delay between device going back online and requests actually going through
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
			[self initLogin];
		});
	}
	// Reload current page
	else
	{
		[self.webView reload];
	}
}

- (void)initLogin
{
	NSLog(@"initLogin");
	
	SSOProviderModel *ssoProviderModel = [[SSOProviderModel alloc] init];
	
	// Set is loading to true
	self.isLoading = YES;
	
	// Remove all Cached Responses
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	// Remove all Cookies of Domain to clear the login page's session (otherwise login page will recognize that user is already logged in and automatically log them in again with same credentials)
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for(NSHTTPCookie *cookie in [cookieStorage cookies])
	{
		NSRange domainRange = [[cookie domain] rangeOfString:BASE_DOMAIN];
		
		if(domainRange.length > 0)
		{
			[cookieStorage deleteCookie:cookie];
		}
	}
	
	NSString *fullURL = [NSString stringWithFormat:AUTHENTICATION_BASE_URL @"Authentication?idp=%@&aud=%@",
						 ssoProviderModel.Name,
						 @"mytmd"];
	
	NSLog(@"Login URL: %@", fullURL);
	
	NSURL *url = [NSURL URLWithString:fullURL];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
	
	 // Fix for issue that causes UIWebView to shift left when keyboard appears (see viewForZoomingInScrollView)
	[self.webView.scrollView setDelegate:self];
	[self.webView.scrollView setScrollEnabled:NO];
	
	[self.webView loadRequest:urlRequest];
	
	// Alternative method using NSURLSession (doesn't send the correct user agent)
	/*NSURLSessionConfiguration *urlSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfiguration delegate:self delegateQueue:nil];
	 
	NSURLSessionDownloadTask *loginTask = [urlSession downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
	{
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		
		NSLog(@"%@", headers);
		
		[self.webView loadData:[NSData dataWithContentsOfURL:location] MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:nil];
	}];
	
	[loginTask resume];*/
	
	// Show Loading Screen
	[self updateWebViewLoading:YES];
}

// Obtain User Data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize Login");
	
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
	[myProfileModel getWithCallback:^(BOOL success, MyProfileModel *profile, NSError *error)
	{
		if(success)
		{
			RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
			
			// Update Timeout Period to the value sent from Server
			[(ELCUIApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[profile.TimeoutPeriodMins intValue]];
			
			NSLog(@"User ID: %@", myProfileModel.ID);
			NSLog(@"Preferred Account ID: %@", myProfileModel.MyPreferredAccount.ID);
			NSLog(@"Device ID: %@", registeredDeviceModel.ID);
			NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
			
			// Check if device is already registered with TeleMed service
			if(registeredDeviceModel.PhoneNumber.length > 0 && ! [registeredDeviceModel.PhoneNumber isEqualToString:@"000-000-0000"])
			{
				// Phone Number is already registered with Web Service, so we just need to update Device Token (Device Token can change randomly so this keeps it up to date)
				[registeredDeviceModel setShouldRegister:YES];
				
				[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
				{
					// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
					if(registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
					{
						[self showWebViewError:[NSString stringWithFormat:@"There was a problem registering your device on our network:<br>%@", registeredDeviceError.localizedDescription]];
					}
					
					if(success)
					{
						// Go to Main Storyboard
						[(AppDelegate *)[[UIApplication sharedApplication] delegate] showMainScreen];
					}
					// Error updating Device Token so show Phone Number screen so user can register correct phone number
					else
					{
						[self performSegueWithIdentifier:@"showPhoneNumber" sender:self];
					}
				}];
			}
			// Device ID is not yet registered with TeleMed, so show Phone Number screen to register
			else
			{
				[self performSegueWithIdentifier:@"showPhoneNumber" sender:self];
			}
		}
		else
		{
			NSLog(@"LoginSSOViewController Error: %@", error);
			
			// Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
			[self showWebViewError:[NSString stringWithFormat:@"There was a problem completing the login process:<br>%@", error.localizedDescription]];
		}
	}];
	
	// Set is loading to false
	self.isLoading = NO;
}

- (void)updateWebViewLoading:(BOOL)isLoading
{
	// Speed up toggling the loading screen by forcing it to execute in main thread
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Toggle Activity Indicator
		if(isLoading)
		{
			[self.activityIndicator startAnimating];
		}
		else
		{
			[self.activityIndicator stopAnimating];
		}
		
		// Toggle Loading View Container
		[self.loadingView setHidden: ! isLoading];
		
		// Toggle Web View
		[self.webView setHidden:isLoading];
		
		// Toggle Back Button
		[self.backButton setEnabled:self.webView.canGoBack];
	});
}

// Show
- (void)showWebViewError:(NSString *)errorMessage
{
	// Hide Loading Screen
	[self updateWebViewLoading:NO];
	
	errorMessage = [NSString stringWithFormat:@"<div style=\"margin: 50px 10px 0; color: #fff; font-size: 16px;\"><p>%@</p><p>Please check your network connection and press the refresh button below to try again.</p></div>", errorMessage];
	
	[self.webView loadHTMLString:errorMessage baseURL:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showPhoneNumber"])
	{
		PhoneNumberViewController *phoneNumberViewController = segue.destinationViewController;
		
		// Set delegate
		[phoneNumberViewController setDelegate:self];
	}
}


/* ==========================
  UIWEBVIEW DELEGATE METHODS
 ============================ */

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	//NSLog(@"Current URL: %@", request.URL.absoluteString);
	
	NSString *targetURL = AUTHENTICATION_BASE_URL AUTHENTICATION_CALLBACK_PAGE;
	
	// Observe current URL of page. If it is the Success page, then handle it separately so that the header tokens can be extracted (UIWebView provides no way to extract response headers)
	if([request.URL.absoluteString hasPrefix:targetURL])
	{
		[NSURLConnection connectionWithRequest:request delegate:self];
		
		return NO;
	}
	
	// All other requests should be loaded by the WebView
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// Show Loading Screen
	[self updateWebViewLoading:YES];
	
	// Set is loading to true
	self.isLoading = YES;
}

// Observe current URL of page.
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	NSString *currentURL = webView.request.URL.absoluteString;
	
	// Success screen will never load here because it is not loaded by WebView. Instead it is handled by NSURLConnection didReceiveResponse method.
	
	// URL is the Login screen
	if([currentURL rangeOfString:@"login.aspx?"].location != NSNotFound)
	{
		// Prevent users from being able to go back to about:blank
		[self.backButton setEnabled:NO];
		
		// Update background to be transparent
		[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor = 'transparent';"];
		
		#if defined(DEBUG)
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('userNameTextBox').value = 'shanegoodwin'; document.getElementById('passwordTextBox').value = 'SBpassw0rd';"];
			//[self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('userNameTextBox').value = 'mattrogers'; document.getElementById('passwordTextBox').value = 'tm4321$$';"];
			//[self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('userNameTextBox').value = 'bturner'; document.getElementById('passwordTextBox').value = 'passw0rd';"];
			//[self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('userNameTextBox').value = 'jhutchison'; document.getElementById('passwordTextBox').value = 'passw0rd';"];
		#endif
	}
	// URL is the Forgot Password screen
	else if([currentURL rangeOfString:@"ForgotPassword"].location != NSNotFound)
	{
		// Update background to be transparent
		[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor = 'transparent';"];
	}
	// URL is a blank screen
	else if([currentURL isEqualToString:@"about:blank"])
	{
		// Prevent users from being able to go back to about:blank
		[self.backButton setEnabled:NO];
	}
	
	// Hide Loading Screen
	[self updateWebViewLoading:NO];
	
	// If url is any page other than about:blank, then reset isRetry
	if( ! [currentURL isEqualToString:@"about:blank"])
	{
		self.isRetry = NO;
	}
	
	// Set is loading to false
	self.isLoading = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"LoginSSOViewController Error: %@", error);
	
	// Set is loading to false
	self.isLoading = NO;
	
	// When login process redirects to Success page, the webView:shouldStartLoadWithRequest captures it and prevents the WebView from loading it which results in an error with code 102. Don't show an error for this.
	if(error.code == 102)
	{
		return;
	}
	// After a device goes back online, there is an unknown delay until device can access network which causes and error with code -999 to be returned. Retry the request once again if this happens.
	else if(error.code == -999 && ! self.isRetry)
	{
		NSLog(@"Retry Login");
		
		self.isRetry = YES;
		
		[self performSelector:@selector(initLogin) withObject:nil afterDelay:2.0];
		
		return;
	}
	
	[self showWebViewError:[NSString stringWithFormat:@"There was a problem loading the login page:<br>%@", error.localizedDescription]];
}

// Fix for issue that causes UIWebView to shift left when keyboard appears
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return nil;
}


/* ================================
  NSURLCONNECTION DELEGATE METHODS
 ================================== */

// UIWebView provides no way to extract response headers, but we need the Access and Refresh Tokens contained in those headers. webView:shouldStartLoadWithRequest will capture the Success page and create a request that sends its result here where the headers can be extracted.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
		
		// Extract the headers
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		
		//NSLog(@"@@@ Response URL: %@", response.URL.absoluteString);
		//NSLog(@"@@@ Response Headers: %@", headers);
		
		// Get tokens from header
		NSString *accessToken = [headers valueForKey:@"X-TeleMed-AccessToken"];
		NSString *refreshToken = [headers valueForKey:@"X-TeleMed-RefreshToken"];
		
		if(accessToken && refreshToken)
		{
			[authenticationModel setAccessToken:accessToken];
			[authenticationModel setRefreshToken:refreshToken];
			
			NSLog(@"Access Token: %@", accessToken);
			NSLog(@"Refresh Token: %@", refreshToken);
			
			// Finalize Login can occasionally get stuck in background thread, so force it to execute in main thread
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self finalizeLogin];
			});
			
			return;
		}
		
		[self showWebViewError:@"There was a problem completing the login process."];
	}
	// Response should always be of type NSHTTPURLResponse, but show an error here just in case
	else
	{
		[self showWebViewError:@"There was a problem completing the login process."];
	}
}

/*- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"Did Receive Data");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Did Receive Finish Loading");
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
