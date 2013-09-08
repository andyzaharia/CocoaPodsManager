//
//  NSString+Misc.h
//  CocoaPodsManager
//
//  Created by Admin on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Misc)

-(NSString *) trimWhiteSpace;
-(NSString *) trimWhiteSpaceAndNewline;

-(NSString *) leftSubstringWithLength: (NSInteger) length;

-(BOOL) isSameLeftSideWithCaseInsensitive: (NSString *) str;

// Its really hard to explain with this method does
// Takes an array of strings, and compares the left side of self with each one of them, if it finds one that matches,
// then it will return the index of the matched string, else it will return NSNotFound
-(NSUInteger) findLeftSideWithItems: (NSArray *) items;


-(NSArray *) lines;

-(NSString *) firstOccurenceOfStringEnclosedWith: (NSString *) str;

@end
