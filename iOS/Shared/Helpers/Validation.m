//
//  Validation.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/17/19.
//  Copyright © 2019 SolutionBuilt. All rights reserved.
//

#import "Validation.h"

@implementation Validation

/**
 * Validate an email address
 *
 * Copied from https://www.cocoanetics.com/2014/06/e-mail-validation/
 * Simplified using https://stackoverflow.com/questions/42664046/regex-for-email-validation-in-objective-c#answer-42664559
 *
 *
 * Alternative validation method: (RFC 5322 compliant)
 *
 * Copied from https://emailregex.com/
 *
 * NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}";
 * NSPredicate *predicateEmailValidation = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
 *
 * Example: if (! [predicateEmailValidation evaluateWithObject:emailAddress])
 */
+ (BOOL)isEmailAddressValid:(NSString *)emailAddress
{
	NSError *error = nil;
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
	NSRange range = NSMakeRange(0, emailAddress.length);
	
	if (error)
	{
		return NO;
	}
	
	NSTextCheckingResult *result = [detector firstMatchInString:emailAddress options:0 range:range];

	// Result should be a recognized email address
	if (! [result.URL.scheme isEqualToString:@"mailto"])
	{
		return NO;
	}
	
	// Match must include the entire string
	if (! NSEqualRanges(result.range, range))
	{
		return NO;
	}
	
	// Should not have the mailto url scheme
	if ([emailAddress hasPrefix:@"mailto:"])
	{
		return NO;
	}
	
	return YES;
}

@end
