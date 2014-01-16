//
//  NSManagedObjectContext+Custom.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/18/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSManagedObjectContext+Custom.h"

@implementation NSManagedObjectContext (Custom)

static NSManagedObjectContext   *_masterPrivateContext = nil;
static NSMutableDictionary      *_managedObjectContextsDictionary = nil;

+ (NSString *) generateGUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *) uuidStringRef];
    CFRelease(uuidStringRef);
    return uuid;
}

+ (NSManagedObjectContext *) masterWriterPrivateContext
{
    if (!_masterPrivateContext) {
        _masterPrivateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        _masterPrivateContext.persistentStoreCoordinator = [NSPersistentStoreCoordinator sharedPersisntentStoreCoordinator];
    }
    
    return _masterPrivateContext;
}

+ (NSManagedObjectContext *) contextForMainThread
{
    if (!_managedObjectContextsDictionary) {
        _managedObjectContextsDictionary = [[NSMutableDictionary alloc] init];
    }
    
    NSThread *thread = [NSThread mainThread];
    if (![[thread name] length]) {
        [thread setName: [NSManagedObjectContext generateGUID]];
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        context.parentContext = [NSManagedObjectContext masterWriterPrivateContext];
        [_managedObjectContextsDictionary setObject:context forKey: [thread name]];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserverForName:NSManagedObjectContextDidSaveNotification
                                        object:context
                                         queue:nil
                                    usingBlock:^(NSNotification *note) {
                                        NSManagedObjectContext *savedContext = [note object];
                                        if (savedContext == context) {
                                            return;
                                        }
                                        
                                        dispatch_sync(dispatch_get_main_queue(), ^{
                                            [context performBlock:^{
                                                [context mergeChangesFromContextDidSaveNotification: note];
                                            }];
                                        });

        }];
        return context;
    } else {
        return [_managedObjectContextsDictionary objectForKey: [thread name]];
    }
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
    if (!_managedObjectContextsDictionary) {
        _managedObjectContextsDictionary = [[NSMutableDictionary alloc] init];
    }
    
    // Force the return of the main thread context.
    if ([NSThread isMainThread]) {
        return [NSManagedObjectContext contextForMainThread];
    }

    NSThread *currentThread = [NSThread currentThread];
    if (![[currentThread name] length]) {
        [currentThread setName: [NSManagedObjectContext generateGUID]];
        
        NSManagedObjectContextConcurrencyType contextType = ([currentThread isMainThread]) ? NSMainQueueConcurrencyType : NSPrivateQueueConcurrencyType;
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: contextType];
        context.parentContext = [NSManagedObjectContext masterWriterPrivateContext];
        [_managedObjectContextsDictionary setObject:context forKey: [currentThread name]];
        
        return context;
    } else {
        return [_managedObjectContextsDictionary objectForKey: [currentThread name]];
    }
}

+ (void) cleanContextsForCurrentThread
{
    if (_managedObjectContextsDictionary) {
        NSThread *currentThread = [NSThread currentThread];
        if ([[currentThread name] length]) {
            [_managedObjectContextsDictionary removeObjectForKey: [currentThread name]];
        }
    }
}

+ (NSManagedObjectContext *) contextForBackgroundThread
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = [NSManagedObjectContext masterWriterPrivateContext];
    return backgroundContext;
}

#pragma mark -

-(void) saveToPersistentStore
{
    [self save: nil];
    
    NSManagedObjectContext *parentContext = self.parentContext;
    if (parentContext) {
        NSManagedObjectContext *parentContext = self.parentContext;
        if (parentContext) {
            [parentContext performBlock:^{
                if ([parentContext hasChanges]) {
                    [parentContext save: nil];
                }
            }];
        }
    }
}

@end
