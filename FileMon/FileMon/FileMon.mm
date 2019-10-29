//
//  FileMon.m
//  FileMon
//
//  Created by linallen on 2019/10/29.
//  Copyright © 2019 linallen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import "FileMon.h"

es_client_t *endpointClient = nil;
es_event_type_t events[]={ES_EVENT_TYPE_NOTIFY_CREATE, ES_EVENT_TYPE_NOTIFY_OPEN, ES_EVENT_TYPE_NOTIFY_WRITE, ES_EVENT_TYPE_NOTIFY_CLOSE, ES_EVENT_TYPE_NOTIFY_RENAME, ES_EVENT_TYPE_NOTIFY_LINK, ES_EVENT_TYPE_NOTIFY_UNLINK};


@implementation FileMonitor

-(BOOL)start:(FileCallbackBlock)callback
{
    BOOL started = NO;
    es_new_client_result_t result;
    
    
    @synchronized(self)
    {
    result = es_new_client(&endpointClient,^(es_client_t *client, const es_message_t *message){
        File * file = nil;
        file = [[File alloc] init:(es_message_t *_Nonnull)message];
        if(nil != file)
        {
        callback(file);
        }
    });
    
    
    if(ES_NEW_CLIENT_RESULT_SUCCESS != result)
    {
        //err msg
        NSLog(@"ERROR: es_new_client() failed with %d", result);
    }
    
    //clear cache
    if(ES_CLEAR_CACHE_RESULT_SUCCESS != es_clear_cache(endpointClient))
    {
           //err msg
           NSLog(@"ERROR: es_clear_cache() failed");
    }
    
    //subscribe
    if(ES_RETURN_SUCCESS != es_subscribe(endpointClient, events, sizeof(events)/sizeof(events[0])))
    {
           NSLog(@"ERROR: es_subscribe() failed");
    }
    }//end synchronized
    
    started  = YES;
    return started;
}

-(BOOL)stop
{
    BOOL stopped  = NO;
    @synchronized (self) {
        if(NULL != endpointClient)
        {
            if(ES_RETURN_SUCCESS != es_unsubscribe_all(endpointClient))
            {
                NSLog(@"ERROR: es_unsubscribe_all() failed");
            }
            if(ES_RETURN_SUCCESS != es_delete_client(endpointClient))
            {
                 NSLog(@"ERROR: es_delete_client() failed");
            }
        }
        endpointClient = NULL;
        stopped = YES;
    }
    return stopped;
}

@end


NSString* convertStringToken(es_string_token_t* stringToken)
{
    //string
    NSString* string = nil;
    
    //sanity check(s)
    if( (NULL == stringToken) ||
        (NULL == stringToken->data) ||
        (stringToken->length <= 0) )
    {
        //bail
        goto bail;
    }
        
    //convert to data, then to string
   string = [NSString stringWithUTF8String:(const char * _Nonnull)[[NSData dataWithBytes:stringToken->data length:stringToken->length] bytes]];
    
bail:
    
    return string;
    
}
