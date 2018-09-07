//
//  AccountXMLParser.h
//  TeleMed
//
//  Created by SolutionBuilt on 8/16/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AccountModel.h"

@class AccountModel;

@interface AccountXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSMutableArray *accounts;

@end
