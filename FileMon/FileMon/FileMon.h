//
//  FileMon.h
//  FileMon
//
//  Created by linallen on 2019/10/29.
//  Copyright © 2019 linallen. All rights reserved.
//

#ifndef FileMon_h
#define FileMon_h
#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#define KEY_SIGNATURE_CDHASH @"cdHash"
#define KEY_SIGNATURE_FLAGS @"csFlags"
#define KEY_SIGNATURE_IDENTIFIER @"signatureIdentifier"
#define KEY_SIGNATURE_TEAM_IDENTIFIER @"teamIdentifier"
#define KEY_SIGNATURE_PLATFORM_BINARY @"isPlatformBinary"

@class File;
@class Process;
typedef void (^FileCallbackBlock)(File *_Nonnull);

@interface FileMonitor : NSObject
-(BOOL)start:(FileCallbackBlock _Nonnull)callback;
-(BOOL)stop;
@end


@interface File : NSObject
@property u_int32_t event;
@property(nonatomic,retain)NSString *_Nullable sourcePath;
@property(nonatomic,retain)NSString *_Nullable destinationPath;
@property(nonatomic,retain)Process *_Nullable process;
-(id _Nullable)init:(es_message_t * _Nonnull)message;
@end

@interface Process : NSObject
@property pid_t pid;
@property pid_t ppid;
@property uid_t uid;
@property u_int32_t event;  //exec,fork,exit
@property int exit;    //exit code
@property(nonatomic, retain)NSString* _Nullable path;
@property(nonatomic, retain)NSMutableArray* _Nonnull arguments;
@property(nonatomic, retain)NSMutableArray* _Nonnull ancestors;
@property(nonatomic, retain)NSMutableDictionary* _Nonnull signingInfo;
@property(nonatomic, retain)NSDate* _Nonnull timestamp;

-(id _Nullable)init:(es_message_t * _Nonnull)message;
@end


NSString* convertStringToken(es_string_token_t* stringToken);

#endif /* FileMon_h */
