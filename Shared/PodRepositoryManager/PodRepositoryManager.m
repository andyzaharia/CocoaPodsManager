//
//  PodManager.m
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodRepositoryManager.h"
#import "TAppDelegate.h"
#import "PodSpecTaskOperation.h"
#import "AppConstants.h"
#import "Plugin.h"

@interface PodRepositoryManager()
{
    NSOperationQueue    *_operationQueue;
    NSInteger           _workingOperations;
}

@end

@implementation PodRepositoryManager

-(id) init{
    self = [super init];
    if(self){
        _workingOperations = 0;
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount: 1];
    
    }
    return self;
}

+ (id)sharedPodSpecManager {
    
    static dispatch_once_t onceQueue;
    static PodRepositoryManager *podSpecManager = nil;
    
    dispatch_once(&onceQueue, ^{ podSpecManager = [[self alloc] init]; });
    return podSpecManager;
}

-(NSArray *) getPodNameListFromMasterDirectory {
    
    __block NSMutableArray *podNames = [NSMutableArray array];
    
    NSError *error = nil;
    NSString *masterFolderPath = [NSHomeDirectory() stringByAppendingPathComponent: PODS_MASTER_FOLDER];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *items = [fileManager contentsOfDirectoryAtPath:masterFolderPath error: &error];
    [items enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
        BOOL isDirectory = NO;
        if ([fileManager fileExistsAtPath:[masterFolderPath stringByAppendingPathComponent:path] isDirectory:&isDirectory]) {
            if ((isDirectory) && ([path rangeOfString:@"."].location == NSNotFound)) {
                [podNames addObject: path];
            }
        }
    }];
    
    if (error) {
        NSLog(@"Error: %@", error);
    }
    return podNames;
}

-(void) addFetchDetailOperationsWithPodNames: (NSArray *) items onAllDone: (OnDone) onDone {
    
    _workingOperations ++;
    
    __weak PodRepositoryManager *weakSelf = self;
    PodSpecTaskOperation *operation = [[PodSpecTaskOperation alloc] initWithPodNames: items];
    [operation setOnDoneBlock: ^{
        [weakSelf operationDidFinish: nil];
    }];
    
    [operation setOnFailureBlock: ^(NSString *errorMessage){
        NSError *error = [NSError errorWithDomain:errorMessage code:1 userInfo:nil];
        [weakSelf operationDidFailed:nil withError: error];
    }];
    
    [_operationQueue addOperation: operation];
}

-(void) splitAndPushFetchDescriptionOperations: (NSArray *) podNames onDone: (OnDone) onDone {
    
    NSInteger operations = 7;
    NSInteger currentLocation = 0;
    NSInteger arrayLength = [podNames count] / operations;
    
    for (int i = 0; i < operations; i++) {
        NSRange range = NSMakeRange(currentLocation, arrayLength);
        if (i == operations - 1) {
            range.length += [podNames count] % operations;
        }
        
        if (range.length > 0) {
            NSArray *subArray = [podNames subarrayWithRange: range];
            
            [self addFetchDetailOperationsWithPodNames: subArray onAllDone:^{
                
            }];
        }
        currentLocation += arrayLength;
    }
}

-(NSArray *) fetchAllLocalItemsWithoutProperties
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fetchedDetails == NO"];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending: YES];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"PodSpec"];
    [request setPredicate: predicate];
    [request setSortDescriptors:@[sorter]];
        
    return [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest: request error: nil];
}

-(void) fetchAndGeneratePodEntities: (OnDone) oneDone
{
    __weak PodRepositoryManager *weakSelf = self;
    
    NSManagedObjectContext *backgroundContext = [NSManagedObjectContext contextForBackgroundThread];
    [backgroundContext performBlock:^{
        __block NSMutableArray *_podNameListToFetchDetails = [weakSelf getPodNameListFromMasterDirectory].mutableCopy;
        NSArray *_names = [_podNameListToFetchDetails copy];
        [_names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            if([name length] > 0) {
                PodSpec *pod = [PodSpec findFirstByAttribute:@"name" withValue: name inContext: backgroundContext];
                if (!pod) {
                    pod = [PodSpec createEntityInContext: backgroundContext];
                    pod.name = name;
                    pod.fetchedDetails = @NO;
                }
                
                if ([pod.fetchedDetails boolValue]) {
                    [_podNameListToFetchDetails removeObject: name];
                }
            }
        }];
        
        if ([backgroundContext hasChanges]) {
            [backgroundContext saveToPersistentStore];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // Launch operations for fetching properties for these pods
            [weakSelf splitAndPushFetchDescriptionOperations: _podNameListToFetchDetails onDone: nil];
            
            if ([weakSelf.delegate respondsToSelector:@selector(podManagerUpdateCompleted:)]) {
                [weakSelf.delegate podManagerUpdateCompleted: weakSelf];
            }
        });
    }];
}

-(void) updateAllPodProperties: (OnDone) onDone {
    
    [_operationQueue cancelAllOperations];
    
    [self fetchAndGeneratePodEntities:^{
        if (onDone) {
            onDone();
        }
    }];
}

-(void) cancelUpdate{
    
    [_operationQueue cancelAllOperations];
}

#pragma mark -

-(void) operationDidFinish: (PodSpecTaskOperation *) operation{
    
    _workingOperations--;
    
    if (_workingOperations == 0) {
        [_delegate podManagerUpdateCompleted: self];
    }
}

-(void) operationDidFailed: (PodSpecTaskOperation *) operation withError: (NSError *) error{
    
    _workingOperations--;
    [_delegate podManager:self didFailedWithError: error];
    
    if (_workingOperations == 0) {
        [_delegate podManagerUpdateCompleted: self];
    }
}

#pragma mark -

-(void) fetchPropertiesForPodSpec: (PodSpec *) pod
                           onDone: (OnDone) onDone
                        onFailure: (OnFailure) onFailure{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });
}

#pragma mark -

-(void) loadPodSpecRepository: (OnDone) onDone
{
    __weak PodRepositoryManager *weakSelf = self;
    
    NSManagedObjectContext *backgroundContext = [NSManagedObjectContext contextForBackgroundThread];
    [backgroundContext performBlock:^{
        __block NSMutableArray *podNameList = [weakSelf getPodNameListFromMasterDirectory].mutableCopy;
        [podNameList enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            if([name length] > 0) {
                PodSpec *pod = [PodSpec findFirstByAttribute:@"name" withValue: name inContext: backgroundContext];
                if (!pod) {
                    pod = [PodSpec createEntityInContext: backgroundContext];
                    pod.name = name;
                    pod.fetchedDetails = @NO;
                }
            }
        }];
        
        if ([backgroundContext hasChanges]) {
            [backgroundContext save: nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (onDone) {
                onDone();
            }
        });
    }];
}

@end
