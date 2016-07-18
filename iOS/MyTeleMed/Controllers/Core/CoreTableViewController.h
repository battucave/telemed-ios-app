//
//  CoreTableViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTableViewController : UITableViewController

- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withDeliveryID:(NSNumber *)deliveryID;

@end