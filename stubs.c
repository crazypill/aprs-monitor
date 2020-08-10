//
//  stubs.c
//  weather-relay
//
//  Created by Alex Lelievre on 7/18/20.
//  Copyright © 2020 Far Out Labs. All rights reserved.
//

#include <stdio.h>
#include <stdarg.h>


void text_color_set( int foo )
{
    
}


void dw_printf( const char* format, ... )
{
    char buf[2048] = {0};
    va_list vaList;
    va_start( vaList, format );
    vsprintf( buf, format, vaList );
    va_end( vaList );
    printf( "%s\n", buf );
}
