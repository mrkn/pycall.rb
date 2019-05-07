#include "pycall_internal.h"

#if defined(PYCALL_THREAD_WIN32)
int pycall_tls_create(pycall_tls_key *tls_key)
{
  *tls_key = TlsAlloc();
  return *tls_key == TLS_OUT_OF_INDEXES;
}

void *pycall_tls_get(pycall_tls_key tls_key)
{
  return TlsGetValue(tls_key);
}

int pycall_tls_set(pycall_tls_key tls_key, void *ptr)
{
  return 0 == TlsSetValue(tls_key, ptr);
}
#endif

#if defined(PYCALL_THREAD_PTHREAD)
int pycall_tls_create(pycall_tls_key *tls_key)
{
  return pthread_key_create(tls_key, NULL);
}

void *pycall_tls_get(pycall_tls_key tls_key)
{
  return pthread_getspecific(tls_key);
}

int pycall_tls_set(pycall_tls_key tls_key, void *ptr)
{
  return pthread_setspecific(tls_key, ptr);
}
#endif
