#ifndef ulid_hpp
#define ulid_hpp

// http://stackoverflow.com/a/23981011
#ifdef __SIZEOF_INT128__
#define ULIDUINT128
#endif

#ifdef ULIDUINT128
#include "ulid_uint128.hpp"
#else
#include "ulid_struct.hpp"
#endif // ULIDUINT128

#endif /* ulid_hpp */
