//
//  CocoaProject.m
//  CocoaPodsManager
//
//  Created by Andy on 08.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CocoaProject.h"
#import "NSString+Misc.h"
#import "PodSpec.h"
#import "PodLineDependencyParser.h"

#define kPODFILE_LOCK               @"Podfile.lock"
#define kPLATFORM                   @"platform"
#define kPOD                        @"pod"
#define kPOD_VERSION                @"~>"

#define kPOD_INHIBIT_ALL_WARNINGS   @"inhibit_all_warnings!"

@interface CocoaProject ()

@end

@implementation CocoaProject

-(id) init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _platformString = @"ios";
    }
    return self;
}


-(id) initWithXCodeProject:(XCodeProject *) proj
{
    self = [self init];
    if (self) {
        _xcodeProject = proj;
        
        _items = [NSMutableArray array];
        [self readPodFile];
    }
    return self;
}

#pragma mark - PodFile  Parser

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
    
    NSString *podFilePath = [self.xcodeProject podFilePath];
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
                            Dependency *dependency = [PodLineDependencyParser dependencyFromString: line];
                            if (dependency) {
                                [self.items addObject: dependency];
                            }
                        }
                        else
                        if ([line isSameLeftSideWithCaseInsensitive: kPOD_INHIBIT_ALL_WARNINGS]) {
                            self.inhibit_all_warnings = YES;
                        }
                    }
                }
                
                [lines removeObjectAtIndex: 0];
            }
        }
    }
}

#pragma mark -

-(BOOL) containsPod: (PodSpec *) pod
{
    for (Dependency *dependency in self.items) {
        if ([dependency.pod isEqual: pod]) {
            return YES;
        }
    }
    return NO;
}

-(Dependency *) dependencyForPod: (PodSpec *) pod {
    
    for (Dependency *dependency in self.items) {
        if (dependency.pod == pod) {
            return dependency;
        }
    }
    return nil;
}

-(BOOL) isSameXCodeProject: (XCodeProject *) xProj
{
    return [self.xcodeProject.projectFilePath isEqualToString: xProj.projectFilePath];
}

#pragma mark -

-(void) writeProjectToPodFile
{
    NSMutableString *podString = [NSMutableString string];
    NSString *platformStr = [NSString stringWithFormat:@"platform :%@", self.platformString];
    if ([self.deploymentString length] > 0) {
        platformStr = [platformStr stringByAppendingFormat:@", '%@'", self.deploymentString];
    }
    
    [podString appendFormat:@"%@\n\n", platformStr];
    
    if (self.inhibit_all_warnings) {
        [podString appendFormat:@"%@\n\n", kPOD_INHIBIT_ALL_WARNINGS];
    }
    
    for (Dependency *dependency in self.items) {
        [podString appendFormat:@"%@\n", [dependency podLineRepresentation]];
    }
    
    NSString *podFilePath = [self.xcodeProject podFilePath];
    [podString writeToFile:podFilePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
}

#pragma mark -

-(void) addPodsFromArray: (NSArray *) items
{
    [items enumerateObjectsUsingBlock:^(PodSpec *pod, NSUInteger idx, BOOL *stop) {
        if (![self containsPod: pod]) {
            [_items addObject: pod];
        }
    }];
}

@end








