//
//  CoreTableViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTableViewController : UITableViewController

#ifdef MYTELEMED
- (void)handleRemoteNotification:(NSMutableDictionary *)notification ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction;
#endif

@end
