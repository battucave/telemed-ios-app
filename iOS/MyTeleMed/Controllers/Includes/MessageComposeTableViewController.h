//
//  MessageComposeTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTableViewController.h"

@protocol MessageComposeTableDelegate <NSObject>

@required
- (void)performSegueToMessageRecipientPicker:(id)sender;

@optional
- (void)validateForm:(NSString *)messageText;

@end

@interface MessageComposeTableViewController : CoreTableViewController <UITextViewDelegate>

@property (weak) id delegate;
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;
@property (nonatomic) NSString *textViewMessagePlaceholder;
@property (nonatomic) CGFloat cellMessageHeight;

- (void)updateSelectedMessageRecipients:(NSArray *)messageRecipients;

@end
