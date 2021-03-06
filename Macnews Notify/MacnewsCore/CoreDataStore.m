//
//  CoreDataStore.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 19..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//
#import "CoreDataStore.h"

@interface NSManagedObjectContext (managedObjectContextDidSave)
- (void)managedObjectContextDidSave:(NSNotification *)notification;
@end

@implementation CoreDataStore

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

//NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Macnews_Notify" withExtension:@"momd"];
- (NSURL *)managedObjectModelURL {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}
- (NSManagedObjectModel *)managedObjectModel {
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[self managedObjectModelURL]];
}
/*
 NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Macnews_Notify.sqlite"];
 
 NSURL *directory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.kr.smoon.ios.macnews"];
 NSURL *storeURL = [directory URLByAppendingPathComponent:@"Macnews_Notify.sqlite"];
 */
- (NSURL *)storeURL {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}
- (NSDictionary *)persistentStoreCoordinatorOptions {
    return nil;
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) return _persistentStoreCoordinator;
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self storeURL] options:[self persistentStoreCoordinatorOptions] error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)newManagedObjectContext {
    return [self newManagedObjectContext:NO];
}

- (NSManagedObjectContext *)newManagedObjectContext:(BOOL)autoMerge {
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    if (autoMerge) {
        [[NSNotificationCenter defaultCenter] addObserver:managedObjectContext selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return managedObjectContext;
}

@synthesize managedObjectContext=_managedObjectContext;
- (NSManagedObjectContext *)managedObjectContext {
    assert([NSThread isMainThread]);
    if (_managedObjectContext != nil) return _managedObjectContext;
    return _managedObjectContext = [self newManagedObjectContext:YES];
}

- (void)deleteAllEntities:(NSString *)entityName from:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        [context deleteObject:object];
    }
    
    error = nil;
    [context save:&error];
}
@end


@implementation NSManagedObjectContext (managedObjectContextDidSave)

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *savedContext = [notification object];
        // ignore change notifications for the main MOC
        if (self == savedContext) return;
        
        // that's another database
        if (self.persistentStoreCoordinator != savedContext.persistentStoreCoordinator) return;
        
        NSLog(@"managedObjectContextDidSave:%@", notification);
        [self mergeChangesFromContextDidSaveNotification:notification];
    });
}

@end
