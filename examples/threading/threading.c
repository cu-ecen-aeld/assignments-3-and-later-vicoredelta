#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)


void* threadfunc(void* thread_param)
{
    // wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_param_local = (struct thread_data*)thread_param;

    if (usleep(thread_param_local->wait_to_obtain_ms) != 0)
    {
        printf("Thread sleep before mutex lock failed\n");
    }

    if (pthread_mutex_lock(thread_param_local->mutex) != 0)
    {
        printf("Mutex lock failed\n");
    }

    if (usleep(thread_param_local->wait_to_release_ms) != 0)
    {
        printf("Thread sleep after mutex lock failed\n");
    }

    if (pthread_mutex_unlock(thread_param_local->mutex) != 0)
    {
        printf("Mutex unlock failed\n");
    }

    thread_param_local->thread_complete_success = true;
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data* thread_param = malloc(sizeof(struct thread_data));
    thread_param->mutex = mutex;
    thread_param->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_param->wait_to_release_ms = wait_to_release_ms;

    /*
    if (pthread_mutex_init(mutex, NULL) != 0)
    {
        printf("Mutex init has failed\n");
        return false;
    }
    */

    if (pthread_create(&thread_param->tid, NULL, &threadfunc, thread_param) != 0)
    {
        printf("Thread can't be created\n");
        return false;
    }

    *thread = thread_param->tid;
    //pthread_join(thread_param->tid, NULL);
    return true;
}

