//
//  wx_thread.c
//  weather-relay
//
//  Created by Alex Lelievre on 7/19/20.
//  Copyright © 2020 Far Out Labs. All rights reserved.
//

#ifndef H_wx_thread
#define H_wx_thread

#ifdef WIN32
#include <windows.h>
#include <process.h>
typedef void   wx_thread_return_t;
typedef HANDLE wx_thread_t;
typedef HANDLE wx_mutex_t;

#define wx_thread_return()
#else
#include <pthread.h>
typedef void*            wx_thread_return_t;
typedef pthread_t        wx_thread_t;
typedef pthread_mutex_t* wx_mutex_t;

#define wx_thread_return()	return 0
#endif

typedef wx_thread_return_t (*wx_thread_entry)(void* args);
wx_thread_t wx_create_thread(wx_thread_entry entry_point, void* args);
wx_thread_t wx_create_thread_detached( wx_thread_entry routine, void* args );
void        wx_thread_join(wx_thread_t);
wx_thread_t wx_thread_self(void);
int         wx_thread_equal(wx_thread_t a, wx_thread_t b);

wx_mutex_t wx_create_mutex(void);
void       wx_destroy_mutex(wx_mutex_t mutex);
void       wx_lock_mutex(wx_mutex_t mutex);
void       wx_unlock_mutex(wx_mutex_t mutex);

#endif // !H_wx_thread

// EOF
