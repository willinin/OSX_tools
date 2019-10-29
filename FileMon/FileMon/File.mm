//
//  File.m
//  FileMon
//
//  Created by linallen on 2019/10/29.
//  Copyright © 2019 linallen. All rights reserved.
//

#import <libproc.h>
#import <bsm/libbsm.h>
#import <sys/sysctl.h>
//#import "utilities.h"
#import "FileMon.h"


@implementation File

@synthesize process;
@synthesize sourcePath;
@synthesize destinationPath;

-(id)init:(es_message_t *)message
{
    self = [super init];
    if(self != nil){
        self.event = message->event_type;
        self.process =[[Process alloc] init:message];
        // (BOOL)containsString:(NSString *)str
        //NSLog(@"hujdkhaskjlfakjhsfakj-----\n");
        //NSString *ss =self.process.path
        [self extractPaths:message];
    }
    return self;
}

-(void)extractPaths:(es_message_t*)message
{
    switch (message->event_type) {
            
        /**
        * @note If an object is being created but has not yet been created, the
        * `destination_type` will be `ES_DESTINATION_TYPE_NEW_PATH`.
        *
        * Typically, `ES_EVENT_TYPE_NOTIFY_CREATE` events are created after the
        * object has been created and the `destination_type` will be
        * `ES_DESTINATION_TYPE_EXISTING_FILE`. The exception to this is for
        * notifications that occur if an ES client responds to an
        * `ES_EVENT_TYPE_AUTH_CREATE` event with `ES_AUTH_RESULT_DENY`.
        *
        */
        /*
         typedef enum {
             ES_DESTINATION_TYPE_EXISTING_FILE,
             ES_DESTINATION_TYPE_NEW_PATH,
         } es_destination_type_t;

       typedef struct {
             es_destination_type_t destination_type;
             union {
                 es_file_t * _Nullable existing_file;
                 struct {
                     es_file_t * _Nullable dir;
                     es_string_token_t filename;
                     mode_t mode;
                 } new_path;
             } destination;
             uint8_t reserved[64];
         } es_event_create_t;
         */
        case ES_EVENT_TYPE_NOTIFY_CREATE:
            if(message->event.create.destination_type == ES_DESTINATION_TYPE_EXISTING_FILE)
                 self.destinationPath = convertStringToken(&message->event.create.destination.existing_file->path);
            if(message->event.create.destination_type == ES_DESTINATION_TYPE_EXISTING_FILE)
                self.destinationPath = [convertStringToken(&message->event.create.destination.new_path.dir->path) stringByAppendingPathComponent:convertStringToken(&message->event.create.destination.new_path.filename)];
            break;
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            self.destinationPath = convertStringToken(&message->event.open.file->path);
            break;
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            self.destinationPath = convertStringToken(&message->event.write.target->path);
            break;
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            self.destinationPath = convertStringToken(&message->event.close.target->path);
            break;
        case ES_EVENT_TYPE_AUTH_LINK:
            self.sourcePath = convertStringToken(&message->event.link.source->path);
            self.destinationPath = [convertStringToken(&message->event.link.target_dir->path) stringByAppendingPathComponent: convertStringToken(&message->event.link.target_filename)];
            break;
            
        /*
         typedef struct {
             es_file_t * _Nullable source;
             es_destination_type_t destination_type;
             union {
                 es_file_t * _Nullable existing_file;
                 struct {
                     es_file_t * _Nullable dir;
                     es_string_token_t filename;
                 } new_path;
             } destination;
             uint8_t reserved[64];
         } es_event_rename_t;
        */
        case ES_EVENT_TYPE_AUTH_RENAME:
            self.sourcePath= convertStringToken(&message->event.rename.source->path);
            if(message->event.rename.destination_type == ES_DESTINATION_TYPE_EXISTING_FILE)
                self.destinationPath = convertStringToken(&message->event.rename.destination.existing_file->path);
            if(message->event.rename.destination_type == ES_DESTINATION_TYPE_EXISTING_FILE)
                 self.destinationPath = [convertStringToken(&message->event.rename.destination.new_path.dir->path) stringByAppendingPathComponent:convertStringToken(&message->event.rename.destination.new_path.filename)];
            break;
        case ES_EVENT_TYPE_AUTH_UNLINK:
            self.destinationPath = convertStringToken(&message->event.unlink.target->path);
            break;
        default:
            break;
    }
}

-(NSString *)description
{
    //pretty print
    return [NSString stringWithFormat: @"source path: %@\ndestination path: %@\nprocess: %@\n\n\n", self.sourcePath, self.destinationPath, process];
}
@end
