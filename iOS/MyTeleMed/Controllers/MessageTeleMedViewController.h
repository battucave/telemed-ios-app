//
//  MessageTeleMedViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 2/4/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "MessageProtocol.h"

@interface MessageTeleMedViewController : CoreViewController

@property (nonatomic) id <MessageProtocol> message;

@end
