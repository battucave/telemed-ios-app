//
//  CoreViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

// IMPORTANT: Only view controllers that are NOT part of the login process (use LoginSSO storyboard) should extend from CoreViewController

#import <UIKit/UIKit.h>

@interface CoreViewController : UIViewController

#ifdef MYTELEMED
- (void)handleRemoteNotification:(NSDictionary *)notificationInfo ofType:(NSString *)notificationType;
#endif

@end
