//
//  MessageDetailParentViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/21/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "MessageModel.h"

@interface MessageDetailParentViewController : CoreViewController

@property (nonatomic) MessageModel *message;
@property (nonatomic) MessageModel *messageModel;

@property (nonatomic) NSArray *messageEvents;
@property (nonatomic) NSMutableArray *filteredMessageEvents;

@property (weak, nonatomic) IBOutlet UIButton *buttonArchive;
@property (weak, nonatomic) IBOutlet UIButton *buttonForward;

- (void)modifyMessageStateSuccess:(NSString *)state;
- (void)modifyMessageStateError:(NSError *)error forState:(NSString *)state;
- (void)callSenderSuccess;
- (void)callSenderError:(NSError *)error;

@end
