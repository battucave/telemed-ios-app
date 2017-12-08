//
//  MessageTeleMedComposeTableViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 5/3/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTableViewController.h"

@protocol MessageTeleMedComposeTableDelegate <NSObject>

@optional
- (void)validateForm:(NSString *)messageText senderEmailAddress:(NSString *)senderEmailAddress;

@end

@interface MessageTeleMedComposeTableViewController : CoreTableViewController <UITextViewDelegate>

@property (weak) id delegate;

@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;
@property (weak, nonatomic) IBOutlet UITextField *textFieldSender;

@property (nonatomic) NSString *textViewMessagePlaceholder;

@end
