//
//  AuthenticationXMLParser.h
//  TeleMed
//
//  Created by SolutionBuilt on 5/29/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthenticationModel.h"

@interface AuthenticationXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) AuthenticationModel *authentication;

@end
