//
//  NSManagedObject+CoreData.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/17/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSManagedObject+CoreData.h"
#import "NSManagedObjectContext+Custom.h"

@implementation NSManagedObject (CoreData)

+ (id) findFirstWithPredicate: (NSPredicate *) predicate
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    [request setFetchLimit: 1];
    
    NSArray *items = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error: nil];
    if ([items count]) {
        return items[0];
    }
    
    return nil;
}

+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: [NSPredicate predicateWithFormat:@"%K == %@", attribute, value]];
    [request setFetchLimit: 1];
    
    NSArray *items = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error: nil];
    if ([items count]) {
        return items[0];
    }
    
    return nil;
}

+ (NSArray *) findAll
{
    NSPredicate *predicate = [NSPredicate predicateWithValue: YES];
    return [self findAllWithPredicate: predicate];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    
    return [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error: nil];
}

+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending
{
    NSString *className = NSStringFromClass(self);
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:param ascending: ascending];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: [NSPredicate predicateWithValue: YES]];
    [request setSortDescriptors:@[sorter]];
    
    return [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error: nil];
}

#pragma mark -

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate
{
    NSString *className = NSStringFromClass(self);

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    [context performBlock:^{
        NSArray *items = [context executeFetchRequest:request error: nil];
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [context deleteObject: obj];
        }];
    }];
}

#pragma mark -

+ (id) createEntityInContext: (NSManagedObjectContext *) context
{
    NSString *className = NSStringFromClass(self);
    NSEntityDescription *entityInfo = [NSEntityDescription entityForName: className
                                                  inManagedObjectContext: context];
    
    NSManagedObject *object = [[NSClassFromString(className) alloc] initWithEntity: entityInfo
                                                    insertIntoManagedObjectContext: context];
    return object;
}

+ (id) createEntity
{
    return [self createEntityInContext: [NSManagedObjectContext contextForCurrentThread]];
}

@end
