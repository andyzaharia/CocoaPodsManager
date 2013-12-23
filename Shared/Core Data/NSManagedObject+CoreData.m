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
    return [self findFirstWithPredicate:predicate inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) findFirstWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    [request setFetchLimit: 1];
    
    NSArray *items = [context executeFetchRequest:request error: nil];
    if ([items count]) {
        return items[0];
    }
    
    return nil;
}

+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value inContext: (NSManagedObjectContext *) context
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: [NSPredicate predicateWithFormat:@"%K == %@", attribute, value]];
    [request setFetchLimit: 1];
    
    NSArray *items = [context executeFetchRequest:request error: nil];
    if ([items count]) {
        return items[0];
    }
    
    return nil;
}

+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value
{
    return [self findFirstByAttribute: attribute withValue: value inContext: [NSManagedObjectContext contextForCurrentThread]];
}


+ (id) findByAttribute:(NSString *) attribute withValue:(id) value
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", attribute, value];
    return [self findAllWithPredicate: predicate];
}

#pragma mark -

+ (NSArray *) findAll
{
    NSPredicate *predicate = [NSPredicate predicateWithValue: YES];
    return [self findAllWithPredicate: predicate];
}

+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context
{
    NSPredicate *predicate = [NSPredicate predicateWithValue: YES];
    return [self findAllWithPredicate:predicate inContext:context];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate
{
    return [self findAllWithPredicate:predicate inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    
    return [context executeFetchRequest:request error: nil];
}

+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending
{
    return [self findAllSortedBy:param ascending:ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
    NSString *className = NSStringFromClass(self);
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:param ascending: ascending];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: [NSPredicate predicateWithValue: YES]];
    [request setSortDescriptors:@[sorter]];
    
    return [context executeFetchRequest:request error: nil];
}

#pragma mark -

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    [self deleteAllMatchingPredicate:predicate inContext:context];
}

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;
{
    NSString *className = NSStringFromClass(self);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: className];
    [request setPredicate: predicate];
    
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

#pragma mark -

+(NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) predicate
{
    return [[self findAllWithPredicate: predicate] count];
}

@end
