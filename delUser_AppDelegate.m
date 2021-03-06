//
//  delUser_AppDelegate.m
//  delUser
//
//  Created by Robert Boone on 9/29/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "delUser_AppDelegate.h"

@implementation delUser_AppDelegate

@synthesize window;

- (void)fetch:(id)sender {
    currentHost = [[hostArrayController selectedObjects] lastObject];
    currentCred = [[credArrayController selectedObjects] lastObject];

    [progress startAnimation:nil];

    if ([[currentHost secure] intValue]) {
        protocal = @"https";
    }
    else {
        protocal = @"http";
    }

    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/xml-api/listaccts", protocal, [currentHost name], [currentHost port]];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:10];

    NSString *remoteAuth            = [NSString stringWithFormat:@"WHM %@:%@", [currentCred username], [currentCred key]];

    [urlRequest addValue:remoteAuth forHTTPHeaderField:@"Authorization"];

    NSError *error;
    NSURLResponse *response;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];

    if (!urlData) {
        [progress stopAnimation:nil];
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }


    NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:urlData
                                                     options:0
                                                       error:&error];

    if (!xml) {
        [progress stopAnimation:nil];
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }

    accounts = [xml nodesForXPath:@"/listaccts/acct" error:&error];

    if (!accounts) {
        [progress stopAnimation:nil];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}

    [accountsTable reloadData];
    [deleteButton setEnabled:YES];
    [fetchButton setTitle:@"Refresh"];
    [progress stopAnimation:nil];
    [status setStringValue:@"Users loaded"];
}

- (void)delete:(id)sender {
    [progress startAnimation:nil];

    NSInteger row = [accountsTable selectedRow];
    if (row < 0) {
        [progress stopAnimation:nil];
        return;
    }

    NSError *error;
    NSArray *node = [[accounts objectAtIndex:row] nodesForXPath:@"user" error:&error];
    
    if (!node) {
        [progress stopAnimation:nil];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}

    NSString *user = [[node objectAtIndex:0] stringValue];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/xml-api/removeacct?user=%@&keepdns=0", protocal, [currentHost name], [currentHost port], user];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:30];
    NSString *remoteAuth            = [NSString stringWithFormat:@"WHM %@:%@", [currentCred username], [currentCred key]];

    [urlRequest addValue:remoteAuth forHTTPHeaderField:@"Authorization"];

    NSURLResponse *response;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                            returningResponse:&response
                                                        error:&error];
    if (urlData) {
        NSString *statusString = [NSString stringWithFormat:@"User '%@' deleted", user];
        [status setStringValue:statusString];
    }
    else {
        [progress stopAnimation:nil];
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }

    [self fetch:self];

}

-(NSString *)stringForPath:(NSString *)xpath ofNode:(NSXMLNode *)node {
	NSError *error;
	NSArray *nodes = [node nodesForXPath:xpath error:&error];
	if (!nodes) {
        [progress stopAnimation:nil];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	if ([nodes count] == 0) {
		return nil;
	} else {
		return [[nodes objectAtIndex:0] stringValue];
	}
}

-(int)numberOfRowsInTableView:(NSTableView*)tableView {
	return [accounts count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSXMLNode *node = [accounts objectAtIndex:row];
	NSString *xPath = [tableColumn identifier];
	return [self stringForPath:xPath ofNode:node];
}


/**
    Returns the support directory for the application, used to store the Core Data
    store file.  This code uses a directory named "delUser" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"delUser"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator) return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
                                                configuration:nil 
                                                URL:url 
                                                options:nil 
                                                error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext) return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];

    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    if (!managedObjectContext) return NSTerminateNow;

    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }

    if (![managedObjectContext hasChanges]) return NSTerminateNow;

    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
    
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.

        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
                
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;

    }

    return NSTerminateNow;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void)dealloc {

    [window release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}


@end
