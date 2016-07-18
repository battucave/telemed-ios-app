//
//  MessageForwardViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "MessageModel.h"

@interface MessageForwardViewController : CoreViewController

@property (nonatomic) MessageModel *message;

- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end