//
//  PhoneCallViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/9/19.
//  Copyright © 2019 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreViewController.h"
#import "MessageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhoneCallViewController : CoreViewController

@property (nonatomic) id <MessageProtocol> message;

@end

NS_ASSUME_NONNULL_END
