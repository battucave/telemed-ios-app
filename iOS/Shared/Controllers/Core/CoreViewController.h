//
//  CoreViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreViewController : UIViewController

#ifdef MYTELEMED
- (void)handleRemoteNotification:(NSMutableDictionary *)notificationInfo ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction;
#endif

@end
