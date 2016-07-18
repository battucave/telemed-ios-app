//
//  AccountXMLParser.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 8/16/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountModel.h"

@class AccountModel;

@interface AccountXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) AccountModel *account;
@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) NSMutableString *currentElementValue;

@end