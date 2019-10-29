//
//  Process.m
//  test
//
//  Created by linallen on 2019/10/28.
//  Copyright © 2019 linallen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libproc.h>
#import <bsm/libbsm.h>
#import <sys/sysctl.h>

//#import "utilities.h"
#import "FileMon.h"

pid_t getParentID(pid_t child);

@implementation Process

@synthesize pid;
@synthesize exit;
@synthesize path;
@synthesize ppid;
@synthesize event;
@synthesize ancestors;
@synthesize arguments;
@synthesize timestamp;
@synthesize signingInfo;

-(id)init:(es_message_t*)message
{
    self = [super init];
    if(nil != self)
    {
    es_process_t *process  = NULL;
    self.arguments = [NSMutableArray array];
    self.ancestors = [NSMutableArray array];
    self.signingInfo = [NSMutableDictionary dictionary];
    self.exit = -1;
    self.uid = -1;
    self,event = -1;
    self.timestamp = [NSDate date];
    self.event = message->event_type;
    
    switch(message->event_type){
        case ES_EVENT_TYPE_NOTIFY_EXEC:
            process = message->event.exec.target;
            [self extractArgs:&message->event];
            break;
        case ES_EVENT_TYPE_NOTIFY_FORK:
            process = message->event.fork.child;
            break;
        case ES_EVENT_TYPE_NOTIFY_EXIT:
            process = message->process;
            self.exit = message->event.exit.stat;
            break;
        default:
            process = message->process;
            break;
        }
    
    self.pid = audit_token_to_pid(process->audit_token);
    self.ppid = process->ppid;
    self.uid = audit_token_to_euid(process->audit_token);
    self.path = convertStringToken(&process->executable->path);
    [self extractSigningInfo:process];
    [self enumerateAncestors];
    }
    return self;
}

-(void)extractArgs:(es_events_t*)event
{
    uint32_t count = 0;
    NSString* argument = nil;
    count = es_exec_arg_count(&event->exec);
    if(count == 0)
        return;
    int i;
    for(i=0;i<count; i++)
    {
    es_string_token_t currentArg = {0};
    currentArg =  es_exec_arg(&event->exec,i);
    argument = convertStringToken(&currentArg);
    if(argument!= nil)
        [self.arguments addObject:argument];
    }
    return;
}

-(void)extractSigningInfo:(es_process_t*)process
{
    NSMutableString *cdHash = nil;
    NSString *signingID = nil;
    NSString *teamID = nil;
    cdHash =[NSMutableString string];
    self.signingInfo[KEY_SIGNATURE_FLAGS]=[NSNumber numberWithUnsignedInt:process->codesigning_flags];
    signingID = convertStringToken(&process->signing_id);
    
    if(signingID !=nil)
        self.signingInfo[KEY_SIGNATURE_IDENTIFIER]= signingID;
    teamID = convertStringToken(&process->team_id);
    
    if(teamID != nil)
        self.signingInfo[KEY_SIGNATURE_TEAM_IDENTIFIER] = teamID;
    
    self.signingInfo[KEY_SIGNATURE_PLATFORM_BINARY]=[NSNumber numberWithBool:process->is_platform_binary];
    
    int i;
    for(i=0; i<CS_CDHASH_LEN;i++)
        [cdHash appendFormat:@"%X",process->cdhash[i]];
    
    self.signingInfo[KEY_SIGNATURE_CDHASH]=cdHash;
    return;
}


-(void)enumerateAncestors
{
    pid_t currentPID = -1;
    pid_t parentPID = -1;
    if(self.ppid != -1){
        [self.ancestors addObject:[NSNumber numberWithInt:self.ppid]];
        
        //set current to parent
        currentPID = self.ppid;
    }
    else{
        //start with self
        currentPID = self.pid;
    }
    
    while(YES){
        parentPID = getParentID(currentPID);
        if(parentPID == 0 || parentPID ==-1 || currentPID == parentPID){
            break;
        }
        currentPID  = parentPID;
        [self.ancestors addObject:[NSNumber numberWithInt:parentPID]];
    }
    return;
}

-(NSString *)description
{
    //description
    NSString* description = nil;
    
    //exec/fork events
    // don't add exit code...
    if(ES_EVENT_TYPE_NOTIFY_EXIT != self.event)
    {
        //pretty print
        description =  [NSString stringWithFormat: @"pid: %d\npath: %@\nuid: %d\nargs: %@\nancestors: %@\nsigning info: %@", self.pid, self.path, self.uid, self.arguments, self.ancestors, self.signingInfo];
    }
    //exit event
    // add exit code
    else
    {
        description =  [NSString stringWithFormat: @"pid: %d\npath: %@\nuid: %d\nargs: %@\nancestors: %@\nsigning info: %@\nexit code: %d", self.pid, self.path, self.uid, self.arguments, self.ancestors, self.signingInfo, self.exit];
    }
    
    return description;
}
@end


//get ppid so comprehensive?
pid_t getParentID(pid_t child){
    pid_t parentID  = -1;
    struct kinfo_proc processStruct ={0};
    size_t procBufferSize =0;
    const u_int mibLength =4;
    
    int sysctlResult = -1;
    procBufferSize = sizeof(processStruct);
    int mib[mibLength] ={CTL_KERN,KERN_PROC,KERN_PROC_PID,child};
    sysctlResult = sysctl(mib,mibLength,&processStruct,&procBufferSize,NULL,0);
    
    if((noErr == sysctlResult)&& (procBufferSize!=0)){
        parentID = processStruct.kp_eproc.e_ppid;
    }
    return parentID;
}

