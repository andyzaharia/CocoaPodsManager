//
//  CPProject+PodFileParser.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 1/17/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import "CPProject+PodFileParser.h"
#import "CPProject+Misc.h"
#import "NSString+Misc.h"
#import "PodLineDependencyParser.h"
#import "CPDependency+Misc.h"

#define kPLATFORM                   @"platform"
#define kPOD                        @"pod"
#define kPOD_VERSION                @"~>"

#define kPOD_INHIBIT_ALL_WARNINGS   @"inhibit_all_warnings!"


@implementation CPProject (PodFileParser)

#pragma mark - Reader

-(BOOL) readPlatformFromLine: (NSString *) platformStr
{
    if ([platformStr length] > [kPLATFORM length]) {
        if ([[[platformStr lowercaseString] substringWithRange:NSMakeRange(0, [kPLATFORM length])] isEqualToString:[kPLATFORM lowercaseString]]) {
            
            NSString *platformContent = [platformStr substringWithRange: NSMakeRange([kPLATFORM length], [platformStr length] - [kPLATFORM length])];
            platformContent = [platformContent trimWhiteSpace];
            
            NSArray *components = [platformContent componentsSeparatedByString:@","];
            for (NSString *component in components) {
                if ([components indexOfObject: component] == 0) {
                    self.platformString = [component trimWhiteSpace];
                    self.platformString = [self.platformString stringByReplacingOccurrencesOfString:@":" withString:@""];
                }
                else
                    if ([components indexOfObject: component] == 1) {
                        self.deploymentString = [component trimWhiteSpace];
                        self.deploymentString = [self.deploymentString stringByReplacingOccurrencesOfString:@"'" withString:@""];
                        self.deploymentString = [self.deploymentString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    }
            }
            return YES;
        }
    }
    return NO;
}

-(void) readPodFile
{
    // Really this parser needs some better code
    NSString *podFilePath = [self podFilePath];
    
    
    if ([podFilePath length]) {
        NSURL *fileURL = [NSURL fileURLWithPath: podFilePath];
        NSString *fileContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error: nil];
        
        fileContent = [fileContent trimWhiteSpaceAndNewline];
        NSMutableArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
        if ([lines count] > 0) {
            if ([self readPlatformFromLine:[lines objectAtIndex:0]]) {
                [lines removeObjectAtIndex: 0];
            }
            
            while ([lines count] > 0) {
                NSString *line = [lines objectAtIndex: 0];
                line = [line trimWhiteSpace];
                if (![[line leftSubstringWithLength:1] isEqualToString:@"#"]) {
                    if ([line length] > 0) {
                        if ([line isSameLeftSideWithCaseInsensitive: kPOD]) {
                            CPDependency *dependency = [PodLineDependencyParser dependencyFromString: line];
                            if (dependency) {
                                dependency.project = self;
                            } else {
                                NSLog(@"Failed to parse line:\n%@", line);
                            }
                        } else
                            if ([line isSameLeftSideWithCaseInsensitive: kPOD_INHIBIT_ALL_WARNINGS]) {
                                self.inhibit_all_warnings = @(YES);
                            }
                    }
                }
                [lines removeObjectAtIndex: 0];
            }
        }
    }
}

#pragma mark - Writer

-(void) writeProjectToPodFile
{
    NSMutableString *podString = [NSMutableString string];
    NSString *platformStr = [NSString stringWithFormat:@"platform :%@", [self.platformString lowercaseString]];
    if ([self.deploymentString length] > 0) {
        platformStr = [platformStr stringByAppendingFormat:@", '%@'", self.deploymentString];
    }
    
    [podString appendFormat:@"%@\n\n", platformStr];
    
    if (self.inhibit_all_warnings) {
        [podString appendFormat:@"%@\n\n", kPOD_INHIBIT_ALL_WARNINGS];
    }
    
    for (CPDependency *dependency in self.items) {
        [podString appendFormat:@"%@\n", [dependency podLineRepresentation]];
    }
    
    NSString *podFilePath = [self podFilePath];
    [podString writeToFile:podFilePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
}


@end
