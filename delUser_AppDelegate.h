//
//  delUser_AppDelegate.h
//  delUser
//
//  Created by Robert Boone on 9/29/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface delUser_AppDelegate : NSObject 
{
    NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

    IBOutlet NSArrayController *hostArrayController;
    IBOutlet NSArrayController *credArrayController;
    IBOutlet NSTextField *status;
    IBOutlet NSButton *fetchButton;
    IBOutlet NSButton *deleteButton;
    IBOutlet NSTableView *accountsTable;

    NSManagedObject *currentHost;
    NSManagedObject *currentCred;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)fetch:(id)sender;
- (IBAction)delete:(id)sender;

@end
