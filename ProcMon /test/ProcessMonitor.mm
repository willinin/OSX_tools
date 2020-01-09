//
//  ProcessMonitor.m
//  test
//
//  Created by linallen on 2019/10/28.
//  Copyright © 2019 linallen. All rights reserved.
//

#import "ProcessMonitor.h"
#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>

es_client_t *endpointClient = nil;

es_event_type_t events[] = {ES_EVENT_TYPE_NOTIFY_EXEC,ES_EVENT_TYPE_NOTIFY_FORK,ES_EVENT_TYPE_NOTIFY_EXIT};

@implementation ProcessMonitor

-(BOOL)start:(ProcessCallbackBlock)callback
{
    BOOL started = NO;
    es_new_client_result_t result;
    
    
    @synchronized(self)
    {
    result = es_new_client(&endpointClient,^(es_client_t *client, const es_message_t *message){
        Process * process = nil;
        process = [[Process alloc] init:(es_message_t *_Nonnull)message];
        if(nil != process)
        {
        callback(process);
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
