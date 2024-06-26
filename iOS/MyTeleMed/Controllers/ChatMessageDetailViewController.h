//
//  ChatMessageDetailViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/5/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "CoreViewController.h"

@interface ChatMessageDetailViewController : CoreViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic) BOOL isNewChat;
@property (nonatomic) NSNumber *conversationID;
@property (nonatomic) NSArray *conversations;

@end
