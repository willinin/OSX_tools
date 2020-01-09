//
//  libtest_dylib.c
//  test_dylib
//
//  Created by linallen on 2020/1/9.
//  Copyright © 2020 linallen. All rights reserved.
//

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>

/*
void __attribute__ ((constructor)) install()
{
    printf( "will pwn it\n" );
}
*/



void __attribute__ ((constructor)) install()
{
 SInt32 nRes = 0;
 CFUserNotificationRef pDlg = NULL;
 const void* keys[] = { kCFUserNotificationAlertHeaderKey,
  kCFUserNotificationAlertMessageKey };
 const void* vals[] = {
  CFSTR("you are hacked "),
  CFSTR("will pwn it!")
 };
 
 CFDictionaryRef dict = CFDictionaryCreate(0, keys, vals,
                sizeof(keys)/sizeof(*keys),
                &kCFTypeDictionaryKeyCallBacks,
                &kCFTypeDictionaryValueCallBacks);
 
 pDlg = CFUserNotificationCreate(kCFAllocatorDefault, 0,
                     kCFUserNotificationPlainAlertLevel,
                     &nRes, dict);
}

