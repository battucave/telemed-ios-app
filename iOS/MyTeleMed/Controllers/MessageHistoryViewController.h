//
//  MessageHistoryViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 1/21/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageDetailParentViewController.h"

@interface MessageHistoryViewController : MessageDetailParentViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BOOL isArchived;
@property (nonatomic) BOOL canForward;

@end
