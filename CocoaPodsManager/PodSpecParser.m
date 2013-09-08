//
//  PodSpecParser.m
//  CocoaPodsManager
//
//  Created by Andy on 18.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpecParser.h"
#import "NSString+Misc.h"

static NSString *kPodSpecDeclaration = @"Pod::Spec.new";



@interface PodSpecParser (){
    NSString *_filePath;
}

@end

@implementation PodSpecParser

-(id) initWithFilePath: (NSString *) path{
    self = [super init];
    if (self) {
        _filePath = path;
        
        [self parse];
    }
    return self;
}

-(void) parse{
    
    NSString *content = [[NSString stringWithContentsOfFile:_filePath encoding:NSASCIIStringEncoding error: nil] trimWhiteSpaceAndNewline];
    NSArray *lines = [content lines];
    for (NSString *line in lines) {
        NSString *l = [line stringByReplacingOccurrencesOfString:@" " withString: @""];
        if ([l isSameLeftSideWithCaseInsensitive: kPodSpecDeclaration]) {
            
        }
    }
}

@end
