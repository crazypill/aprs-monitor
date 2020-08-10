//
//  wx_thread.c
//  weather-relay
//
//  Created by Alex Lelievre on 7/19/20.
//  Copyright © 2020 Far Out Labs. All rights reserved.
//


#include "wx_thread.h"
#include "main.h"

#include <stdlib.h>
#include <stdio.h>


#ifdef WIN32
#include <errno.h>


wx_thread_t wx_create_thread_detached( wx_thread_entry routine, void* args )
{
    return wx_create_thread( routine, args );   // no difference on Windows !!@
}


wx_thread_t wx_create_thread( wx_thread_entry routine, void* args )
{
    wx_thread_t thd = _beginthread(routine, 0, args);
    if( thd == -1L )
        log_error("%s, _beginthread failed with %d\n", __FUNCTION__, errno);

    return thd;
}

void wx_thread_join( wx_thread_t thread )
{
    // !!@ test this and add error handling
    WaitForSingleObject( thread, INFINITE );
}


wx_thread_t wx_thread_self()
{
    return GetCurrentThread();
}


int wx_thread_equal( wx_thread_t a, wx_thread_t b )
{
    return a == b;
}


wx_mutex_t wx_create_mutex()
{
    return CreateMutex( NULL, false, NULL );
}


void wx_destroy_mutex( wx_mutex_t mutex )
{
    CloseHandle( mutex );
}


void wx_lock_mutex( wx_mutex_t mutex )
{
    WaitForSingleObject( mutex, INFINITE );
}


void wx_unlock_mutex( wx_mutex_t mutex )
{
    ReleaseMutex( mutex );
}




#pragma mark -
#else

wx_thread_t wx_create_thread_detached( wx_thread_entry routine, void* args )
{
    pthread_t id = 0;
    pthread_attr_t attributes;

    pthread_attr_init(&attributes);
    pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_DETACHED);

    int ret = pthread_create(&id, &attributes, routine, args);
    if( ret != 0 )
        log_error("%s, pthread_create failed with %d\n", __FUNCTION__, ret);

    return id;
}


wx_thread_t wx_create_thread( wx_thread_entry routine, void* args )
{
    pthread_t id = 0;
    pthread_attr_t attributes;

    pthread_attr_init(&attributes);
    pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_JOINABLE);

    int ret = pthread_create(&id, &attributes, routine, args);
    if( ret != 0 )
        log_error("%s, pthread_create failed with %d\n", __FUNCTION__, ret);

    return id;
}


void wx_thread_join( wx_thread_t thread )
{
    int ret = pthread_join(thread, NULL);
    if( ret != 0 )
        log_error("%s, pthread_join failed with %d\n", __FUNCTION__, ret);
}


wx_thread_t wx_thread_self()
{
    return pthread_self();
}


int wx_thread_equal( wx_thread_t a, wx_thread_t b )
{
    return pthread_equal( a, b );
}


wx_mutex_t wx_create_mutex( void )
{
    pthread_mutex_t* mutex = (pthread_mutex_t*)malloc( sizeof( pthread_mutex_t ) );
    pthread_mutex_init( mutex, NULL );
    return mutex;
}


void wx_destroy_mutex( wx_mutex_t mutex )
{
    pthread_mutex_destroy( mutex );
    free( mutex );
}


void wx_lock_mutex( wx_mutex_t mutex )
{
    int ret = pthread_mutex_lock( mutex );
    if( ret != 0 )
        log_error("%s failed with %d\n", __FUNCTION__, ret);
}


void wx_unlock_mutex( wx_mutex_t mutex )
{
    int ret = pthread_mutex_unlock( mutex );
    if( ret != 0 )
        log_error("%s failed with %d\n", __FUNCTION__, ret);
}

#endif

// EOF
