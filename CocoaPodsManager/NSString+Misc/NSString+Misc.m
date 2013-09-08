//
//  NSString+Misc.m
//  CocoaPodsManager
//
//  Created by Admin on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSString+Misc.h"

@implementation NSString (Misc)

-(NSString *) trimWhiteSpace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString *) trimWhiteSpaceAndNewline
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *) leftSubstringWithLength: (NSInteger) length
{
    if ([self length] <= length) {
        return self;
    }
    else
    return [self substringWithRange:NSMakeRange(0, length)];
}

-(BOOL) isSameLeftSideWithCaseInsensitive: (NSString *) str
{
    return [[[self leftSubstringWithLength:[str length]] lowercaseString] isEqualToString: [str lowercaseString]];
}

-(NSUInteger) findLeftSideWithItems: (NSArray *) items
{
    __block NSUInteger result = NSNotFound;
    [items enumerateObjectsUsingBlock:^(NSString *stringItem, NSUInteger idx, BOOL *stop) {
        if ([self isSameLeftSideWithCaseInsensitive: stringItem]) {
            result = idx;
            *stop = YES;
        }
    }];
    
    return result;
}

#pragma mark -

-(NSArray *) lines
{
    return [self componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
}

-(NSString *) firstOccurenceOfStringEnclosedWith: (NSString *) str
{
    NSRange range = [self rangeOfString: str];
    if (range.location != NSNotFound) {
        if ([self length] - 1 > range.location + 1) {
            NSString *subString = [self substringFromIndex:range.location + 1];
            return [subString stringByReplacingOccurrencesOfString:@"'" withString:@""];
        }
    }
    return nil;
}

@end
