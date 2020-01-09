//
//  main.m
//  test
//
//  Created by linallen on 2019/10/28.
//  Copyright © 2019 linallen. All rights reserved.
//

#import "ProcessMonitor.h"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        //NSLog(@"Hello, World!");
        ProcessMonitor *procMon = [[ProcessMonitor alloc] init];
        ProcessCallbackBlock block = ^(Process* process){
            switch (process.event) {
                case ES_EVENT_TYPE_NOTIFY_EXEC:
                    NSLog(@"PROCESS EXEC ('ES_EVENT_TYPE_NOTIFY_EXEC')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_FORK:
                    NSLog(@"PROCESS FORK ('ES_EVENT_TYPE_NOTIFY_FORK')");
                    break;
                case ES_EVENT_TYPE_NOTIFY_EXIT:
                    NSLog(@"PROCESS EXIT ('ES_EVENT_TYPE_NOTIFY_EXIT')");
                    break;
                default:
                    break;
            }
            NSLog(@"%@", process);
        };
        [procMon start:block];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
