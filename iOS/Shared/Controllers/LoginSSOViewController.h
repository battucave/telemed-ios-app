//
//  LoginSSOViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/20/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginSSOViewController : UIViewController <UIScrollViewDelegate, UIWebViewDelegate>

- (void)finalizeLogin;
- (void)showWebViewError:(NSString *)errorMessage;

@end
