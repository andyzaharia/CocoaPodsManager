//
//  PodFileParser.m
//  CocoaPodsManager
//
//  Created by Andy on 01.03.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodLineDependencyParser.h"
#import "CPDependency+Misc.h"
#import "NSString+Misc.h"
#import "PodSpec+Misc.h"
#import "PodSpecTaskOperation.h"

#define kPODFILE_LOCK @"Podfile.lock"
#define kPLATFORM @"platform"
#define kPOD @"pod"

#define kPOD_VERSION    @"~>"
#define kPOD_GIT        @":git"
#define kPOD_COMMIT     @":commit"
#define kPOD_LOCAL      @":local"
#define kPOD_PODSPEC    @":podspec"
#define kPOD_HEAD       @":head"

@implementation PodLineDependencyParser

+(NSString *) versionFromString: (NSString *) versionStr
{
    NSArray *versionOperators = @[@">", @">=", @"<", @"<=", @"~>"]; // Optimized ? -> No way :-)
    
    NSString *firstStringEnclosed = [versionStr firstOccurenceOfStringEnclosedWith:@"'"];
    if ([firstStringEnclosed length]) {
        NSUInteger versionOperatorIdx = [firstStringEnclosed findLeftSideWithItems: versionOperators];
        if (versionOperatorIdx != NSNotFound) {
            NSString *operator = [versionOperators objectAtIndex: versionOperatorIdx];
            NSString *version = [[firstStringEnclosed stringByReplacingOccurrencesOfString:operator withString:@""] trimWhiteSpace];            
            //NSLog(@"Version operator: %@", operator);
            return version;
        }
        else {
            // NO operator
            return firstStringEnclosed;
        }
    }
    return nil;
}

+(void) parseComponents: (NSArray *) components forDependency: (CPDependency *) dependency
{
    NSMutableArray *mComponents = components.mutableCopy;
    [mComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        NSString *trimmedComponent = [component trimWhiteSpace];
        
        if ([trimmedComponent isSameLeftSideWithCaseInsensitive: kPOD_GIT]) {
            dependency.gitSource = [trimmedComponent firstOccurenceOfStringEnclosedWith: @"'"];
        }
        else
        if ([trimmedComponent isSameLeftSideWithCaseInsensitive: kPOD_LOCAL]) {
            dependency.local = [trimmedComponent firstOccurenceOfStringEnclosedWith: @"'"];
        }
        else
        if ([trimmedComponent isSameLeftSideWithCaseInsensitive: kPOD_PODSPEC]) {
            dependency.customPodSpec = [trimmedComponent firstOccurenceOfStringEnclosedWith: @"'"];
        }
        else
        if ([trimmedComponent isSameLeftSideWithCaseInsensitive: kPOD_HEAD]) {
            dependency.head = @(YES);
        }
        else
        if ([trimmedComponent isSameLeftSideWithCaseInsensitive: kPOD_COMMIT]) {
            dependency.commit = [trimmedComponent firstOccurenceOfStringEnclosedWith: @"'"];
        }
        else
        {
            if (idx == 0) {
                // Possible version string
                NSString *versionStr = [PodLineDependencyParser versionFromString: trimmedComponent];
                if ([versionStr length]) {
                    dependency.versionStr = versionStr;
                }
            }
        }
    }];
    
    
    
    if ([mComponents count] > 1) {
        NSString *_secondParam = [[mComponents objectAtIndex:1] trimWhiteSpace];
        
        // check for version string
        if ([[_secondParam substringWithRange:NSMakeRange(0, [kPOD_VERSION length])] isEqualToString: kPOD_VERSION]) {
            // We have a version specified
            dependency.versionStr = [[_secondParam stringByReplacingOccurrencesOfString:kPOD_VERSION withString:@""] trimWhiteSpace];
        }
        
        TODO("Add support for other params...");
    }
}

+(CPDependency *) dependencyFromString: (NSString *) podLine
{
    __block CPDependency *dependency = [CPDependency createEntity];
    
    if ([podLine length] > [kPOD length]) {
        NSString *line = [[podLine substringWithRange:NSMakeRange([kPOD length], [podLine length] - [kPOD length])] trimWhiteSpace];
        NSMutableArray *components = [line componentsSeparatedByString:@","].mutableCopy;
        if ([components count] > 0) {
            // Pod Name
            NSString *name = [[[components objectAtIndex: 0] trimWhiteSpace] firstOccurenceOfStringEnclosedWith:@"'"];
            if ([name length] > 0) { // Lets be paranoic here
                
                PodSpec *pod = [PodSpec findFirstByAttribute:@"name" withValue:name];
                
                if (!pod) {
                    [PodSpecTaskOperation fetchPodSpecWithName:name onDone: nil];
                    pod = [PodSpec findFirstByAttribute:@"name" withValue:name];
                }
                
                if (pod) {
                    dependency.pod = pod;
            
                    [components removeObjectAtIndex: 0]; // Remove the Pod Name object
                    [PodLineDependencyParser parseComponents:components forDependency: dependency];
                } else {
                    TODO("Warn our user that we where not able to find that specific pod in our pod list");
                    
//                    NSAlert* msgBox1 = [[NSAlert alloc] init];
//                    [msgBox1 setMessageText: [NSString stringWithFormat: @"Cant find pod entry with name %@.", name]];
//                    [msgBox1 addButtonWithTitle: @"OK"];
//                    [msgBox1 runModal];
                    
                    return nil;
                }
            }
        }
    }
    
    return dependency;
}

@end