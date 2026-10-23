#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

#if defined(USE_SLUB) && !defined(USE_BUDDY)
#error "USE_SLUB requires USE_BUDDY"
#endif

/* Single-core allocator; initialize once after Buddy's pmm_init().
 * Every successful allocation is 16-byte aligned and holds at least size
 * writable bytes. Empty slabs are immediately returned to Buddy.
 * kmalloc(0) returns NULL; kfree(NULL) is a no-op. Only live returned
 * pointers may be freed: invalid or duplicate frees trigger a panic. */
void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *ptr);
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */
