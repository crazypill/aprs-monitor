//
//  PacketManager.h
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@interface ArrayDocument : UIDocument
@property NSMutableArray* items;
@end




@interface PacketManager : NSObject

@property (nonatomic, strong) NSMutableArray*   _Nullable items;
@property (nonatomic, strong) ArrayDocument*    _Nullable document;
@property (atomic)            BOOL                        fileOpInProgress;
@property (nonatomic)         BOOL                        documentOpen;

@property (nonatomic, copy) void (^documentUpdatedBlock)( void );

+ (PacketManager*)shared;
+ (NSString*)applicationDocumentsDirectory;

// required overrides
- (NSString*)documentFileName;
- (NSString*)documentPath;
- (NSString*)documentType;

- (void)openDocument;
- (void)clearDocument;  // used when user logs out (wipes out the file)

- (void)markItemEdited:(id __nullable)entry;
- (void)addItem:(id)showitem;
- (void)removeItemAtIndex:(NSInteger)index andNotify:(BOOL)notify;

@end

NS_ASSUME_NONNULL_END
