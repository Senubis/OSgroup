#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

//LAB4 function3 2413015



void
schedule(void) {
    bool intr_flag;
    local_intr_save(intr_flag);

    current->need_resched = 0;
    list_entry_t *start = &current->list_link;
    if (list_empty(start)) {
        // An unlinked process such as idleproc has a self-linked list entry.
        start = &proc_list;
    }

    struct proc_struct *next = idleproc;
    list_entry_t *entry = start;
    do {
        entry = list_next(entry);
        if (entry == &proc_list) {
            continue;
        }

        struct proc_struct *candidate = le2proc(entry, list_link);
        if (candidate->state == PROC_RUNNABLE) {
            next = candidate;
            break;
        }
    } while (entry != start);

    next->runs++;
    if (next != current) {
        proc_run(next);
    }

    local_intr_restore(intr_flag);
}
