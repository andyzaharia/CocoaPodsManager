//
//  CPDependency+Misc.m
//  CocoaPodsManager
//
//  Created by Andy on 19.12.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CPDependency+Misc.h"
#import "PodSpec+Misc.h"
#import "NSString+Misc.h"

@implementation CPDependency (Misc)

+(CPDependency *) dependencyWithPod: (PodSpec *) pod
{
    CPDependency *d = [CPDependency createEntityInContext: pod.managedObjectContext];
    [d setPod: pod];
    return d;
}

-(NSString *) podLineRepresentation
{
    NSMutableString *mutableString = [NSMutableString string];
    
    // Pod Name
    [mutableString appendFormat: @"pod '%@', ", self.pod.name];
    mutableString = [mutableString stringByAddingSpacesToPosition: 35].mutableCopy;
    
    // Pod Version
    if ([self.versionStr length]) {
        NSString *operator = @"";
        if([self.versionOperator length])
        {
            operator = [NSString stringWithFormat:@"%@ ", self.versionOperator];
        }
        
        [mutableString appendFormat: @"'%@%@', ", operator, self.versionStr];
    }
    
    if (self.head) {
        [mutableString appendString:@":head, "];
    }
    
    if ([self.gitSource length]) {
        [mutableString appendFormat: @":git => '%@', ", self.gitSource];
    }
    
    if ([self.commit length]) {
        [mutableString appendFormat: @":commit => '%@', ", self.commit];
    }
    
    if ([self.local length]) {
        [mutableString appendFormat: @":local => '%@', ", self.local];
    }
    
    if ([self.customPodSpec length]) {
        [mutableString appendFormat: @":podspec => '%@', ", self.customPodSpec];
    }
    
    NSString *trimmedStr = [mutableString trimWhiteSpace];
    return [trimmedStr substringToIndex:[trimmedStr length] - 1];
}

@end
