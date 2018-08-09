//
//  CoreTableViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

// IMPORTANT: Only view controllers that are NOT part of the login process (use LoginSSO storyboard) should extend from CoreTableViewController

#import <UIKit/UIKit.h>

@interface CoreTableViewController : UITableViewController

#ifdef MYTELEMED
- (void)handleRemoteNotification:(NSDictionary *)notification ofType:(NSString *)notificationType;
#endif

@end
