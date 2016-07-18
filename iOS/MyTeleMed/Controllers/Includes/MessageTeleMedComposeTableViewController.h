//
//  MessageTeleMedComposeTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/3/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageComposeTableViewController.h"

@protocol MessageTeleMedComposeTableDelegate <NSObject>

@optional
- (void)validateForm:(NSString *)messageText senderEmailAddress:(NSString *)senderEmailAddress;

@end

@interface MessageTeleMedComposeTableViewController : MessageComposeTableViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textFieldSender;

@end
