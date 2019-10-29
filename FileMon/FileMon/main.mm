//
//  main.m
//  FileMon
//
//  Created by linallen on 2019/10/29.
//  Copyright © 2019 linallen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import "FileMon.h"
#import "stdio.h"

//redirect NSLog to file
void redirectNSLog(NSString *path){
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:nil];
    freopen([path cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
    freopen([path cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

/*
 es_event_type_t events[]={ES_EVENT_TYPE_NOTIFY_CREATE, ES_EVENT_TYPE_NOTIFY_OPEN, ES_EVENT_TYPE_NOTIFY_WRITE, ES_EVENT_TYPE_NOTIFY_CLOSE, ES_EVENT_TYPE_NOTIFY_RENAME, ES_EVENT_TYPE_NOTIFY_LINK, ES_EVENT_TYPE_NOTIFY_UNLINK};
*/
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        //NSLog(@"Hello, World!");
        if(argc!=2)
            return -1;
        NSString *path = [NSString stringWithFormat:@"%s",argv[1]];
        redirectNSLog(path);
        FileMonitor *filemon = [[FileMonitor alloc]init];
        FileCallbackBlock block = ^(File *file){
            if([file.process.path containsString:@"FileMon"]==NO && [file.destinationPath containsString:@"FileMon"] == NO && [file.sourcePath containsString:@"FileMon"]==NO && [file.destinationPath containsString:path] == NO){
            switch(file.event){
                case ES_EVENT_TYPE_NOTIFY_CREATE:
                    NSLog(@"File Create ('ES_EVENT_TYPE_NOTIFY_CREATE')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_OPEN:
                    NSLog(@"File Open ('ES_EVENT_TYPE_NOTIFY_OPEN')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_WRITE:
                    NSLog(@"File Write ('ES_EVENT_TYPE_NOTIFY_WRITE')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_CLOSE:
                    NSLog(@"File Close ('ES_EVENT_TYPE_NOTIFY_CLOSE')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_RENAME:
                    NSLog(@"File Rename ('ES_EVENT_TYPE_NOTIFY_RENAME')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_LINK:
                    NSLog(@"File Link ('ES_EVENT_TYPE_NOTIFY_LINK')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_UNLINK:
                    NSLog(@"File Unlink ('ES_EVENT_TYPE_NOTIFY_UNLINK')");
                    break;
            }
            NSLog(@"%@", file);
            }
        };
loop:
        [filemon start:block];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
