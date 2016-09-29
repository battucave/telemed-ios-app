//
//  MessageComposeTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MessageComposeTableDelegate <NSObject>

@required
- (void)performSegueToMessageRecipientPicker:(id)sender;

@optional
- (void)validateForm:(NSString *)messageText;

@end

@interface MessageComposeTableViewController : UITableViewController <UITextViewDelegate>

@property (weak) id delegate;
@property (weak, nonatomic) IBOutlet UIButton *buttonMessageRecipient;
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;
@property (nonatomic) NSString *textViewMessagePlaceholder;
@property (nonatomic) CGFloat cellMessageHeight;

- (void)updateSelectedMessageRecipients:(NSArray *)messageRecipients;

@end
