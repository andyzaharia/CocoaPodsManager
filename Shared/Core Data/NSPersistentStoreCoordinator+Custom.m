//
//  NSPersistentStoreCoordinator+Custom.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/18/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSPersistentStoreCoordinator+Custom.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

@implementation NSPersistentStoreCoordinator (Custom)

static NSPersistentStoreCoordinator *_sharedPersistentStore = nil;

static NSString *_dataModelName = nil;
static NSString *_storeFileName = nil;
static Class _bundleClass = NULL;

+ (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void) setDataModelName: (NSString *) name withStoreName: (NSString *) storeFileName {
    _dataModelName = name;
    _storeFileName = storeFileName;
}

+ (void) setDataModelName: (NSString *) name withStoreName: (NSString *) storeFileName andBundleClass: (Class) bundleClass {
    _dataModelName = name;
    _storeFileName = storeFileName;
    _bundleClass = bundleClass;
}

+(NSPersistentStoreCoordinator *) sharedPersisntentStoreCoordinator
{
    TODO("Fix database file location.");
    
    NSAssert(_dataModelName, @"Core Data model name has not been set. Use [NSPersistentStoreCoordinator setDataModelName:withStoreName:].");
    
    if (!_sharedPersistentStore) {
        NSString *storePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: _storeFileName];
        NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
        
        NSBundle *bundle = (_bundleClass != NULL) ? [NSBundle bundleForClass: _bundleClass] : [NSBundle mainBundle];
        NSString *resourcePath = [bundle resourcePath];
        NSString *modelFileName = [_dataModelName stringByAppendingPathExtension:@"momd"];
        NSString *modelPath = [resourcePath stringByAppendingPathComponent: modelFileName];
        
        NSURL *modelUrl = [NSURL fileURLWithPath: modelPath];
        
        NSManagedObjectModel *_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelUrl];
        [_managedObjectModel kc_generateOrderedSetAccessors];
        
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                  NSInferMappingModelAutomaticallyOption : @(YES)};
    
        NSError *error;
        _sharedPersistentStore = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: _managedObjectModel];
        if (![_sharedPersistentStore addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _sharedPersistentStore;
}

+ (void) setNewPresistentStore: (NSPersistentStoreCoordinator *) store
{
    _sharedPersistentStore = store;
}

@end
