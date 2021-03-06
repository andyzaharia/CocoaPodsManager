//
//  PodTaskOperation.m
//  CocoaPodsManager
//
//  Created by Andy on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpecTaskOperation.h"
#import "NSString+Misc.h"
#import "AppConstants.h"
#import "PodSpec+StdOutParser.h"
#import "Plugin.h"
#import "PodSpec+Misc.h"

@interface PodSpecTaskOperation ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end


@implementation PodSpecTaskOperation


-(id) initWithPodNames: (NSArray *) podNames
{
    self = [super init];
    if (self) {
        self.podNameList = podNames;
    }
    return self;
}

-(void) parseCocoaPodsListString: (NSString *) messageString{
    
    NSMutableArray *lines = [messageString componentsSeparatedByString:@"\n"].mutableCopy;
    [lines removeObjectsInRange: NSMakeRange(0, 2)];
    [lines removeObjectsInRange: NSMakeRange([lines count] - 2, 2)];
    
    CGFloat _progress = 0.0;
    
    for (NSString *name in lines) {
        NSString *podName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([podName length] > 0) {
            PodSpec *pod = [PodSpec findFirstWithPredicate:[NSPredicate predicateWithFormat:@"name LIKE[c] %@", podName]];
            if (!pod) {
                pod = [PodSpec createEntity];
            }
            pod.name = podName;
            
            NSString *currentVersion = [[pod versionsArray] objectAtIndex: 0];
            [pod fetchYamlPropertiesWithVersion: currentVersion];
        }
        CGFloat p = (CGFloat)([lines indexOfObject: name] + 1) / (CGFloat)[lines count];
        if (p - _progress > 0.005) {
            _progress = p;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onProgressBlock(_progress);
            });
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onDoneBlock();
    });
}

// used only when self.podNameList is supplied
-(void) fetchPodsProperties
{
    for (NSString *name in self.podNameList) {
        
        if (self.isCancelled) return;
        
        if([name length] > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[c] %@", name];
            PodSpec *pod = [PodSpec findFirstWithPredicate:predicate inContext: self.managedObjectContext];
            if (!pod) {
                pod = [PodSpec createEntityInContext: self.managedObjectContext];
                pod.name = name;
            }
            
            NSArray *versions = [pod versionsArray];
            if ([versions count]) {
                versions = [versions sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                NSString *lastVersion = [versions lastObject];
                [pod fetchYamlPropertiesWithVersion: lastVersion];
            }
        }
    }
}

-(void) main{
    
    @autoreleasepool {
        
        if (self.isCancelled) return;
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/pod"]){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onFailureBlock(PODS_NOT_INSTALLED_MESSAGE);
            });
            
            return;
        }
        
        NSManagedObjectContext *context = [NSManagedObjectContext contextForBackgroundThread];
        self.managedObjectContext = context;
        
        [context performBlockAndWait:^{
            
            [self fetchPodsProperties];
            
            if ([context hasChanges]) {
                [context saveToPersistentStore];
            }
        }];
        
        [NSManagedObjectContext cleanContextsForCurrentThread];
        
        self.managedObjectContext = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onDoneBlock();
        });
    }

}

#pragma mark -

+(void) fetchPodSpecWithName: (NSString *) podName onDone: (OnDone) onDone
{
    //NSLog(@"Fetched PodSpec with Name: %@", podName);
    
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    [context performBlockAndWait:^{
        
        if([podName length] > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[c] %@", podName];
            PodSpec *pod = [PodSpec findFirstWithPredicate:predicate];
            if (!pod) {
                pod = [PodSpec createEntityInContext: context];
                pod.name = podName;
            }
            
            NSArray *versions = [pod versionsArray];
            if ([versions count]) {
                versions = [versions sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                NSString *lastVersion = [versions lastObject];
                [pod fetchYamlPropertiesWithVersion: lastVersion];
            }
        }
        
        if ([context hasChanges]) {
            [context saveToPersistentStore];
        }
        
        if (onDone) {
            onDone();
        }
    }];
}

@end
