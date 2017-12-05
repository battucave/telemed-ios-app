//
//  AuthenticationXMLParser.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/29/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthenticationModel.h"

@interface AuthenticationXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) AuthenticationModel *authentication;
@property (nonatomic) NSMutableString *currentElementValue;

@end