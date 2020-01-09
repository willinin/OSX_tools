//
//  ProcessMonitor.h
//  test
//
//  Created by linallen on 2019/10/28.
//  Copyright © 2019 linallen. All rights reserved.
//

#ifndef ProcessMonitor_h
#define ProcessMonitor_h
#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>


#define KEY_SIGNATURE_CDHASH @"cdHash"
#define KEY_SIGNATURE_FLAGS @"csFlags"
#define KEY_SIGNATURE_IDENTIFIER @"signatureIdentifier"
#define KEY_SIGNATURE_TEAM_IDENTIFIER @"teamIdentifier"
#define KEY_SIGNATURE_PLATFORM_BINARY @"isPlatformBinary"

@class Process;
typedef void (^ProcessCallbackBlock)(Process* _Nonnull);

@interface  ProcessMonitor : NSObject
-(BOOL) start:(ProcessCallbackBlock _Nonnull)callback;
-(BOOL) stop;
@end

@interface Process : NSObject
@property pid_t pid;
@property pid_t ppid;
@property uid_t uid;
@property u_int32_t event;
@property int exit;
@property(nonatomic, retain)NSString* _Nullable path;
@property(nonatomic, retain)NSMutableArray* _Nonnull arguments;
@property(nonatomic, retain)NSMutableArray* _Nonnull ancestors;
@property(nonatomic, retain)NSMutableDictionary* _Nonnull signingInfo;
@property(nonatomic, retain)NSDate* _Nonnull timestamp;

-(id _Nullable)init:(es_message_t * _Nonnull)message;
@end

#endif /* ProcessMonitor_h */
