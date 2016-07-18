//
//  ChatMessageDetailViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/5/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"

@interface ChatMessageDetailViewController : CoreViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic) NSNumber *conversationID;

@end