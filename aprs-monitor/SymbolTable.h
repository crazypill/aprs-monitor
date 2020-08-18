//
//  SymbolTable.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/12/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#ifndef SymbolTable_h
#define SymbolTable_h

#import <UIKit/UIKit.h>


typedef struct
{
    NSString* symbol;
    NSString* name;
    NSString* glyph;
    bool      tint;     // this indicatates that the glyph image needs to be colorized
    bool      emoji;    // this indicatates that the glyph is not a name but an actual emoji
    float     red;
    float     grn;
    float     blu;
    float     alpha;
} SymbolEntry;


const SymbolEntry* getSymbolEntry( NSString* symbol );
NSString*          getGlyphForSymbol( NSString* symbol );
NSString*          getNameForSymbol( NSString* symbol );
UIImage*           emojiToImage( NSString* emoji );

#endif /* SymbolTable_h */
