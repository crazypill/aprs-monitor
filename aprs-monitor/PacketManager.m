//
//  PacketManager.m
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "PacketManager.h"
#import "ErrorController.h"

#define kDocType @"Packet Log"


@implementation ArrayDocument

- (BOOL)loadFromContents:(id)contents ofType:(nullable NSString *)typeName error:(NSError **)outError
{

//    _items = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[ShowItem class], [NSMutableArray class]]] fromData:contents error:outError];
    _items = [NSKeyedUnarchiver unarchiveObjectWithData:contents];
    if( *outError )
    {
        [[ErrorController shared] showError:[*outError localizedDescription] withTitle:kDocType inWindow:nil];
        NSLog( @"loadFromContents: %@, err: %@, items: %@\n", typeName, *outError, _items );
    }
    return YES;
}


- (nullable id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    NSData* data =  [NSKeyedArchiver archivedDataWithRootObject:_items requiringSecureCoding:NO error:outError];
    if( *outError )
    {
        [[ErrorController shared] showError:[*outError localizedDescription] withTitle:kDocType inWindow:nil];
        NSLog( @"contentsForType: %@, err: %@, items: %@\n", typeName, *outError, _items );
    }
    return data;
}

@end



#pragma mark -


@implementation PacketManager


static PacketManager* s_shared = NULL;


+ (PacketManager*)shared
{
    if( !s_shared )
        s_shared = [[PacketManager alloc] init];
    
    return s_shared;
}


+ (NSString*)applicationDocumentsDirectory
{
    NSArray*  paths    = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (id)init
{
    self = [super init];
    [self openDocument];
    return self;
}


- (void)openDocument
{
    __weak PacketManager* weakself = self;

    if( [[NSFileManager defaultManager] fileExistsAtPath:[self documentPath]] )
        [self openDocument:^( BOOL success ) {
            if( !success )
                [[ErrorController shared] showError:@"Problem Opening Document" withTitle:[self documentType] inWindow:nil];

            if( weakself.documentUpdatedBlock )
                weakself.documentUpdatedBlock();
        }];
    else
    {
        [self createEmptyDocument:^( BOOL success ) {
            if( !success )
                [[ErrorController shared] showError:@"Problem Creating Document" withTitle:[self documentType] inWindow:nil];

            if( weakself.documentUpdatedBlock )
                weakself.documentUpdatedBlock();
        }];
    }
}


- (void)clearDocument
{
    if( _documentOpen )
    {
        [_document closeWithCompletionHandler:^( BOOL success ) {
            [[NSFileManager defaultManager] removeItemAtPath:[self documentPath] error:nil];
        }];
    }
}



- (void)openDocument:(void (^ __nullable)(BOOL success))completionHandler
{
    if( !_document )
       _document = [[ArrayDocument alloc] initWithFileURL:[NSURL fileURLWithPath:[self documentPath]]];

    __weak PacketManager* weakself = self;
    if( _document.documentState & UIDocumentStateClosed )
    {
        _fileOpInProgress = YES;
        [_document openWithCompletionHandler:^( BOOL success )
        {
            if( success )
                weakself.items = weakself.document.items;
            else
                NSLog( @"openDocument:openWithCompletionHandler failed: %@\n", weakself.document.fileURL );

            if( !weakself.items )
            {
                weakself.items = [[NSMutableArray alloc] init];
                weakself.document.items = weakself.items;
            }

            weakself.fileOpInProgress = NO;
            weakself.documentOpen = success;

            if( completionHandler )
                completionHandler( success );
        }];
    }
}


- (void)createEmptyDocument:(void (^ __nullable)(BOOL success))completionHandler
{
    if( !_document )
       _document = [[ArrayDocument alloc] initWithFileURL:[NSURL fileURLWithPath:[self documentPath]]];

    __weak PacketManager* weakself = self;
    _fileOpInProgress = YES;
    [_document saveToURL:_document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^( BOOL success )
    {
        if( !success )
            NSLog( @"createEmptyDocument:saveToURL failed: %@\n", weakself.document.fileURL );
            
        weakself.items         = [[NSMutableArray alloc] init];
        weakself.document.items = weakself.items; // also let the history point to the new array
        
        weakself.fileOpInProgress = NO;
        weakself.documentOpen = success;

        if( completionHandler )
            completionHandler( success );
    }];
}


#pragma mark -
#pragma mark Required overrides


- (NSString*)documentFileName
{
    return @"PacketList";
}


- (NSString*)documentPath
{
    return [[PacketManager applicationDocumentsDirectory] stringByAppendingString:@"/RawPacket.log"];
}


- (NSString*)documentType
{
    return kDocType;
}



#pragma mark -


- (void)markItemEdited:(id)entry
{
    [_document updateChangeCount:UIDocumentChangeDone];
    
    if( _documentUpdatedBlock )
        _documentUpdatedBlock();
}


- (void)addItem:(id)entry
{
    if( !entry )
        return;
    
    [_items insertObject:entry atIndex:0];  // insert in the front
    [_document updateChangeCount:UIDocumentChangeDone];
    
    if( _documentUpdatedBlock )
        _documentUpdatedBlock();
}


- (void)removeItemAtIndex:(NSInteger)index andNotify:(BOOL)notify
{
    if( index < 0 || index > _items.count )
        return;
    
    [_items removeObjectAtIndex:index];
    [_document updateChangeCount:UIDocumentChangeDone];
    
    if( notify && _documentUpdatedBlock )
        _documentUpdatedBlock();
}


- (void)removeAllItemsAndNotify:(BOOL)notify
{
    [_items removeAllObjects];
    [_document updateChangeCount:UIDocumentChangeDone];
    
    if( notify && _documentUpdatedBlock )
        _documentUpdatedBlock();
}


@end

// EOF

