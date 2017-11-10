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
#import "MessageStub.h"

@interface MessageDetailParentViewController : CoreViewController

@property (nonatomic) MessageStub *message;
@property (nonatomic) MessageModel *messageModel;

@property (nonatomic) NSArray *messageEvents;
@property (nonatomic) NSMutableArray *filteredMessageEvents;

@property (weak, nonatomic) IBOutlet UIButton *buttonArchive;
@property (weak, nonatomic) IBOutlet UIButton *buttonForward;
@property (weak, nonatomic) IBOutlet UIButton *buttonReturnCall;
@property (weak, nonatomic) IBOutlet UIView *viewPriority;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonForwardLeadingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonForwardTrailingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonHistoryLeadingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonHistoryTrailingSpace;

@end
