//
//  MessageDetailViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageDetailParentViewController.h"

@interface MessageDetailViewController : MessageDetailParentViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

- (void)updateMessageRecipients:(NSMutableArray *)newRecipients;
- (void)updateMessageRecipientsError:(NSError *)error;

@end
