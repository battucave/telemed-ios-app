//
//  LoginSSOViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/20/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <objc/runtime.h>

#import "LoginSSOViewController.h"
#import "AppDelegate.h"
#import "AFNetworkReachabilityManager.h"
#import "AuthenticationModel.h"
#import "SSOProviderModel.h"

@interface LoginSSOViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintToolbarBottom;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isRetry;

@end

@implementation LoginSSOViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Hide keyboard accessory view for UIWebView text fields
	[self hideKeyboardAccessoryView:self.webView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	// Initialize web view
	[self initLogin];
	
	// Set is loading to false
	self.isLoading = NO;
	
	// Reset toolbar to bottom of view
	[self.constraintToolbarBottom setConstant:0.0f];
	
	// Dynamically add a width constraint to Login button to resolve iOS 11 issue (if this doesn't work, then replace entire UIToolbar with UIView - see PhoneNumber view)
	[self.buttonLogin.widthAnchor constraintEqualToConstant:62.0].active = YES;
	
	// Add reachability observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWebView:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop web view
	[self.webView stopLoading];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	// Remove reachability observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
}

- (IBAction)doLogin:(id)sender
{
	// Trigger click on web view form's login button
	[self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('loginButton').click();"];
}

- (IBAction)goBackWebView:(id)sender
{
	[self.webView goBack];
}

- (IBAction)refreshWebView:(id)sender
{
	// If web view is loading, let it finish before refreshing again
	if (self.isLoading)
	{
		return;
	}
	
	// Set is loading to true
	self.isLoading = YES;
	
	// If web view is currently showing a blank screen or error message, then redirect to login page
	if ([self.webView.request.URL.absoluteString isEqualToString:@"about:blank"])
	{
		// Show loading screen
		[self updateWebViewLoading:YES];
		
		// Delay is here is required because there is a slight delay between device going back online and requests actually going through
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
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

// Hide keyboard accessory view for UIWebView text fields
 - (void)hideKeyboardAccessoryView:(UIView *)view
{
	for (UIView *subView in view.subviews)
	{
		if ([NSStringFromClass([subView class]) isEqualToString:@"UIWebBrowserView"])
		{
			Method method = class_getInstanceMethod(subView.class, @selector(inputAccessoryView));
			IMP newImp = imp_implementationWithBlock(^(id _s)
			{
				if ([subView respondsToSelector:@selector(inputAssistantItem)])
				{
					UITextInputAssistantItem *inputAssistantItem = [subView inputAssistantItem];
					inputAssistantItem.leadingBarButtonGroups = @[];
					inputAssistantItem.trailingBarButtonGroups = @[];
				}

				return nil;
			});

			method_setImplementation(method, newImp);
		}
		else
		{
			[self hideKeyboardAccessoryView:subView];
		}
	}
}

- (void)initLogin
{
	SSOProviderModel *ssoProviderModel = [[SSOProviderModel alloc] init];
	
	// Set is loading to true
	self.isLoading = YES;
	
	// Remove all cached responses
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	// Remove all cookies of domain to clear the login page's session (otherwise login page will recognize that user is already logged in and automatically log them in again with same credentials)
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for(NSHTTPCookie *cookie in [cookieStorage cookies])
	{
		NSString *baseDomain = [BASE_URL stringByReplacingOccurrencesOfString:@"https://" withString:@""];
		NSRange domainRange = [[cookie domain] rangeOfString:baseDomain];
		
		if (domainRange.length > 0)
		{
			[cookieStorage deleteCookie:cookie];
		}
	}
	
	NSString *fullURL = [NSString stringWithFormat:AUTHENTICATION_BASE_URL @"Authentication?idp=%@&aud=%@",
						 ssoProviderModel.Name,
						 AUTHENTICATION_AUDIENCE];
	
	NSLog(@"Login URL: %@", fullURL);
	
	NSURL *url = [NSURL URLWithString:fullURL];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
	
	// Prevent scrolling in web view for screens taller than 480
	if ([UIScreen mainScreen].bounds.size.height > 480)
	{
		[self.webView.scrollView setScrollEnabled:NO];
	}
	// Prevent horizontal scrolling in web view for screens 480 or less in height
	else
	{
		[self.webView.scrollView setShowsHorizontalScrollIndicator:NO];
	}
	
	[self.webView.scrollView setDelegate:self];
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
	
	// Show loading screen
	[self updateWebViewLoading:YES];
}

// Obtain user data from server and initialize app
- (void)finalizeLogin
{
	NSLog(@"Finalize Login");
	
	// Set is loading to false
	self.isLoading = NO;
}

// Move toolbar above keyboard
- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Animate toolbar above keyboard
	[UIView beginAnimations:@"ToolbarAboveKeyboard" context:nil];
	[UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	
	[self.constraintToolbarBottom setConstant:keyboardFrame.size.height];
	[self.view layoutIfNeeded];
	
	[UIView commitAnimations];
}

// Move toolbar back to bottom of view
- (void)keyboardWillHide:(NSNotification *)notification
{
	// Animate keyboard to bottom of view
	[UIView beginAnimations:@"ToolbarAboveKeyboard" context:nil];
	[UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	
	[self.constraintToolbarBottom setConstant:0.0f];
	[self.view layoutIfNeeded];
	
	[UIView commitAnimations];
	
	// Reset scroll position of webview
	[self.webView.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)updateWebViewLoading:(BOOL)isLoading
{
	// Speed up toggling the loading screen by forcing it to execute in main thread
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Toggle activity indicator
		if (isLoading)
		{
			[self.activityIndicator startAnimating];
		}
		else
		{
			[self.activityIndicator stopAnimating];
		}
		
		// Toggle loading view container
		[self.loadingView setHidden: ! isLoading];
		
		// Toggle web view
		[self.webView setHidden:isLoading];
		
		// Toggle back button
		[self.buttonBack setEnabled:self.webView.canGoBack];
	});
}

// Show
- (void)showWebViewError:(NSString *)errorMessage
{
	// Hide loading screen
	[self updateWebViewLoading:NO];
	
	errorMessage = [NSString stringWithFormat:@"<div style=\"margin: 50px 10px 0; color: #fff; font-size: 16px;\"><p>%@</p><p>Please check your network connection and press the refresh button below to try again.</p></div>", errorMessage];
	
	[self.webView loadHTMLString:errorMessage baseURL:nil];
}


/* ==========================
  UIWEBVIEW DELEGATE METHODS
 ============================ */

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	//NSLog(@"Current URL: %@", request.URL.absoluteString);
	
	NSString *targetURL = AUTHENTICATION_BASE_URL AUTHENTICATION_CALLBACK_PAGE;
	
	// Observe current url of page. If it is the success page, then handle it separately so that the header tokens can be extracted (UIWebView provides no way to extract response headers)
	if ([request.URL.absoluteString hasPrefix:targetURL])
	{
		[NSURLConnection connectionWithRequest:request delegate:self];
		
		return NO;
	}
	
	// All other requests should be loaded by the WebView
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// Show loading screen
	[self updateWebViewLoading:YES];
	
	// Set is loading to true
	self.isLoading = YES;
}

// Observe current url of page.
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	NSString *currentURL = webView.request.URL.absoluteString;
	
	// Success screen will never load here because it is not loaded by web view. Instead it is handled by NSURLConnection didReceiveResponse:.
	
	// URL is the login screen
	if ([currentURL rangeOfString:@"login.aspx?"].location != NSNotFound)
	{
		// Prevent users from being able to go back to about:blank
		[self.buttonBack setEnabled:NO];
		
		// Update background to be transparent and hide login button
		[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor = 'transparent'; document.getElementById('loginButton').style.display = 'none';"];
		
		// Debug mode login shortcuts
		#ifdef DEBUG
			NSString *javascript = [NSString stringWithFormat:@
				"var $loginButton = document.getElementById('loginButton');"
				"var $password = document.getElementById('passwordTextBox');"
				"var $userName = document.getElementById('userNameTextBox');"
				
				// Auto-populate form if value matches shortcut value
				"var autoPopulate = function(event) {"
					"switch ($userName.value) {"
						"case 'b': case 'bturner': $userName.value = 'bturner'; $password.value = 'passw0rd'; break;"
						"case 'j': case 'jhutchison': $userName.value = 'jhutchison'; $password.value = 'passw0rd'; break;"
						"case 'm': case 'mattrogers': $userName.value = 'mattrogers'; $password.value = 'tm4321$$'; break;"
						"case 's': case 'shanegoodwin': $userName.value = 'shanegoodwin'; $password.value = 'tm4321$$'; break;"
					"}"
				"};"
				
				/* Convert input text to a dropdown (not supported until UIWebView converted to WKWebView)
				"const $dataList = document.createElement('datalist'); $dataList.setAttribute('userNameDataList');"
				"['shanegoodwin', 'bturner', 'jhutchison', 'mattrogers'].forEach(function(userName) {"
					"var $option = document.createElement('option');"
					"$option.value = userName;"
					"$dataList.appendChild($option);"
				"});"
				"$userName.setAttribute('userNameDataList');"
				"$userName.parentNode.insertBefore($dataList, $userName.nextSibling);"*/
				
				// Update username placeholder to remind me of shortcut
				"$userName.setAttribute('placeholder', 'User Name 1st Letter');"
				
				// Add event on username to auto-populate form on blur if value matches shortcut value
				"$userName.addEventListener('blur', autoPopulate);"
				
				// Add event on login button to auto-populate form on click if value matches shortcut value
				"var doLogin = $loginButton.onclick;"
				"$loginButton.addEventListener('click', function(event) {"
					"autoPopulate(event);"
					"doLogin(event);"
				"});"
				
				// Add event on username to automatically submit form when enter key pressed
				"$userName.addEventListener('keypress', function(event) {"
					"if (event.code == 'Enter' && $userName.value.length == 1) {"
						"$userName.blur();"
					"}"
				"});"
			];
		
			[self.webView stringByEvaluatingJavaScriptFromString:javascript];
		#endif
	}
	// URL is the forgot password screen
	else if ([currentURL rangeOfString:@"ForgotPassword"].location != NSNotFound)
	{
		// Update background to be transparent
		[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor = 'transparent';"];
	}
	// URL is a blank screen
	else if ([currentURL isEqualToString:@"about:blank"])
	{
		// Prevent users from being able to go back to about:blank
		[self.buttonBack setEnabled:NO];
	}
	
	// Hide loading screen
	[self updateWebViewLoading:NO];
	
	// If url is any page other than about:blank, then reset isRetry
	if (! [currentURL isEqualToString:@"about:blank"])
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
	
	// When login process redirects to success page, the webView:shouldStartLoadWithRequest captures it and prevents the web view from loading it which results in an error with code 102. Don't show an error for this.
	if (error.code == 102)
	{
		return;
	}
	// After a device goes back online, there is an unknown delay until device can access network which causes and error with code -999 to be returned. Retry the request once again if this happens.
	else if (error.code == -999 && ! self.isRetry)
	{
		NSLog(@"Retry Login");
		
		self.isRetry = YES;
		
		[self performSelector:@selector(initLogin) withObject:nil afterDelay:2.0];
		
		return;
	}
	
	[self showWebViewError:[NSString stringWithFormat:@"There was a problem loading the login page:<br>%@", error.localizedDescription]];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// Prevent zooming web view for screens taller than 480
	if ([UIScreen mainScreen].bounds.size.height > 480)
	{
		return nil;
	}
	// Allow zooming web view for screens 480 or less in height
	else
	{
		return self.webView;
	}
}

// Prevent horizontal scroll in web view
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (scrollView.contentOffset.x > 0)
	{
		[scrollView setContentOffset:CGPointMake(0, scrollView.contentOffset.y)];
	}
}


/* ================================
  NSURLCONNECTION DELEGATE METHODS
 ================================== */

// UIWebView provides no way to extract response headers, but we need the access and refresh tokens contained in those headers. webView:shouldStartLoadWithRequest will capture the Success page and create a request that sends its result here where the headers can be extracted.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
		
		// Extract the headers
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		
		// NSLog(@"Response URL: %@", response.URL.absoluteString);
		// NSLog(@"Response Headers: %@", headers);
		
		// Get tokens from header
		NSString *accessToken = [headers valueForKey:@"X-TeleMed-AccessToken"];
		NSString *refreshToken = [headers valueForKey:@"X-TeleMed-RefreshToken"];
		
		if (accessToken && refreshToken)
		{
			[authenticationModel setAccessToken:accessToken];
			[authenticationModel setRefreshToken:refreshToken];
			
			NSLog(@"Access Token: %@", accessToken);
			NSLog(@"Refresh Token: %@", refreshToken);
			
			// Finalize login can occasionally get stuck in background thread, so force it to execute in main thread
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
