/*
 aprs-weather-submit version 1.4
 Copyright (c) 2019-2020 Colin Cogle <colin@colincogle.name>

 This file, aprs-is.c, is part of aprs-weather-submit.
 <https://github.com/rhymeswithmogul/aprs-weather-submit>
 
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program.  If not, see <https://www.gnu.org/licenses/agpl-3.0.html>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <strings.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/termios.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdint.h>
#include <time.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include <netdb.h>
#include <netinet/tcp.h>

#include "main.h"

//#define TRACE_CONNECT_TIMEOUT

#define CONNECT_TIMEOUT_SECS 10


int connect_with_timeout( int socket, const struct sockaddr* addressinfo, socklen_t addrLen, int timeoutSecs )
{
    int                error = EXIT_SUCCESS;
    long               arg = 0;
    fd_set             myset;
    struct timeval     tv;
    int                valopt;
    socklen_t          lon;


    // Set non-blocking
    if( (arg = fcntl( socket, F_GETFL, NULL )) < 0 )
    {
        log_error( "connect_with_timeout:fcntl:F_GETFL error: %s\n", strerror( errno ) );
        error = -1;
        goto exitGracefully;
    }
    
    arg |= O_NONBLOCK;
    if( fcntl( socket, F_SETFL, arg ) < 0 )
    {
        log_error( "connect_with_timeout:fcntl:F_SETFL error: %s\n", strerror( errno ) );
        error = -1;
        goto exitGracefully;
    }

      
    // Trying to connect with timeout
    int res = connect( socket, addressinfo, addrLen );
    if( res < 0 )
    {
        if( errno == EINPROGRESS )
        {
#ifdef TRACE_CONNECT_TIMEOUT
            log_error( "EINPROGRESS in connect() - selecting\n" );
#endif
            do
            {
                tv.tv_sec  = timeoutSecs;
                tv.tv_usec = 0;
                FD_ZERO( &myset );
                FD_SET( socket, &myset );
                res = select( socket + 1 , NULL, &myset, NULL, &tv );
                if( res < 0 && errno != EINTR )
                {
                    log_error( "error connecting %d - %s\n", errno, strerror( errno ) );
                    error = -1;
                    goto exitGracefully;
                }
                else if( res > 0 )
                {
                    // Socket selected for write
                    lon = sizeof( int );
                    if( getsockopt( socket, SOL_SOCKET, SO_ERROR, (void*)&valopt, &lon ) < 0 )
                    {
                        log_error( "error in getsockopt() %d - %s\n", errno, strerror( errno ) );
                        error = -1;
                        goto exitGracefully;
                    }

                    // Check the value returned...
                    if( valopt )
                    {
                        log_error( "%s (%d)\n", strerror( valopt ), valopt );
                        error = -1;
                        goto exitGracefully;
                    }
                    break;
                }
                else
                {
#ifdef TRACE_CONNECT_TIMEOUT
                    log_error( "timeout in select() - Cancelling!\n" );
#endif
                    error = -ETIMEDOUT;     // return negative error so the outside loop continues
                    goto exitGracefully;
                }
            }
            while( 1 );
       }
       else
       {
          log_error( "Error connecting %d - %s\n", errno, strerror( errno ) );
          error = -1;
          goto exitGracefully;
       }
    }

exitGracefully:

    // Set to blocking mode again...
    if( (arg = fcntl( socket, F_GETFL, NULL )) < 0 )
    {
       log_error( "connect_with_timeout:fcntl:F_GETFL error: %s\n", strerror( errno ) );
       error = -1;
    }

    arg &= ~O_NONBLOCK;
    if( fcntl( socket, F_SETFL, arg ) < 0 )
    {
        log_error( "connect_with_timeout:fcntl:F_SETFL error: %s\n", strerror( errno ) );
        error = -1;
    }

    return error;
}


/**
 * sendPacket() -- sends a packet to an APRS-IS IGate server.
 *
 * @author         Colin Cogle
 * @param server   The DNS hostname of the server.
 * @param port     The listening port on the server.
 * @param username The username with which to authenticate to the server.
 * @param password The password with which to authenticate to the server.
 * @param toSend   The APRS-IS packet, as a string.
 * @since 0.3
 */
int sendPacket (const char* const restrict server, const unsigned short port, const char* const restrict username, const char* const restrict password, const char* const restrict toSend)
{
	int              error = 0;
	ssize_t          bytesRead = 0;
	char             authenticated = 0;
	char             foundValidServerIP = 0;
	struct addrinfo* result = NULL;
	struct addrinfo* results;
	char             verificationMessage[BUFSIZE];
	char             buffer[BUFSIZE];
	int              socket_desc = -1;

	error = getaddrinfo(server, NULL, NULL, &results);
	if (error != 0)
	{
		if (error == EAI_SYSTEM)
		{
            log_unix_error( "sendPacket:getaddrinfo: " );
		}
		else
		{
            log_error( "error in sendPacket:getaddrinfo: %s %s\n", server, gai_strerror(error) );
		}
        return -3;
	}

	for (result = results; result != NULL; result = result->ai_next)
	{
		/* For readability later: */
		struct sockaddr* const addressinfo = result->ai_addr;

		socket_desc = socket( addressinfo->sa_family, SOCK_STREAM, IPPROTO_TCP );
		if( socket_desc < 0 )
		{
            log_unix_error( "sendPacket:socket: " );
			continue; /* for loop */
		}

		/* Assign the port number. */
		switch (addressinfo->sa_family)
		{
			case AF_INET:
				((struct sockaddr_in*)addressinfo)->sin_port   = htons(port);
				break;
			case AF_INET6:
				((struct sockaddr_in6*)addressinfo)->sin6_port = htons(port);
				break;
		}

#ifdef DEBUG_PRINT_CONNECTION_INFO
		/* Connect */
		switch (addressinfo->sa_family)
		{
			case AF_INET:
				inet_ntop(
					AF_INET,
					&((struct sockaddr_in*)addressinfo)->sin_addr,
					buffer,
					INET_ADDRSTRLEN);
				printf("Connecting to %s:%d...\n", buffer,
				       ntohs(((struct sockaddr_in*)addressinfo)->sin_port));
				break;
			case AF_INET6:
				inet_ntop(
					AF_INET6,
					&((struct sockaddr_in6*)addressinfo)->sin6_addr,
					buffer,
					INET6_ADDRSTRLEN);
				printf("Connecting to [%s]:%d...\n", buffer,
				       ntohs(((struct sockaddr_in6*)addressinfo)->sin6_port));
				break;
		}
#endif

        int flags = 1;
        setsockopt( socket_desc, IPPROTO_TCP, TCP_NODELAY, &flags, sizeof(flags) );
        
        error = connect_with_timeout( socket_desc, addressinfo, result->ai_addrlen, CONNECT_TIMEOUT_SECS );
		if (error == 0)
		{
			foundValidServerIP = 1;
			break; /* for loop */
		}
		else
		{
			shutdown( socket_desc, 2 );
            close( socket_desc );
            socket_desc = -1;
		}
	}
	freeaddrinfo(results);
	if( foundValidServerIP == 0 )
	{
		log_error( "sendPacket: could not connect to the server.  %s\n", toSend );
        if( !error )
            error = -1;
        goto exitGracefully;
	}

	/* Authenticate */
	sprintf(buffer, "user %s pass %s vers %s/%s\n", username, password, PROGRAM_NAME, VERSION);
#ifdef DEBUG
	printf("> %s", buffer);
#endif
	send(socket_desc, buffer, (size_t)strlen(buffer), 0);

	strncpy(verificationMessage, username, (size_t)strlen(username)+1);
	strncat(verificationMessage, " verified", 9);
	bytesRead = recv(socket_desc, buffer, BUFSIZE, 0);
	while (bytesRead > 0)
	{
		buffer[bytesRead] = '\0';
#ifdef DEBUG
		printf("< %s", buffer);
#endif
		if( strstr(buffer, verificationMessage) != NULL )
		{
			authenticated = 1;
			break;
		}
		else
		{
			bytesRead = recv( socket_desc, buffer, BUFSIZE, 0 );
		}
	}

    if( !authenticated )
	{
		log_error( "Authentication failed.  %s\n", toSend );
        error = -2;
        goto exitGracefully;
	}

	/* Send packet */
#ifdef DEBUG
	printf( "> %s", toSend );
#endif
    ssize_t klen = strlen( toSend );
	ssize_t rc = send( socket_desc, toSend, klen, 0 );
    if( rc != klen )
        log_error( "error writing frame to socket.  %s\n", toSend );
    
    // for some reason the APRS-IS wants a newline in there... without it, we get no error and no packet sent...
    send( socket_desc, "\n\0", 2, 0 );
    error = 0;
    
exitGracefully:
	/* Done! */
	shutdown( socket_desc, 2 );
    close( socket_desc );
	return error;
}
