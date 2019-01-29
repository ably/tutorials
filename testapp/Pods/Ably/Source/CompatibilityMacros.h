//
//  CompatibilityMacros.h
//  ably
//
//  Created by Yavor Georgiev on 1.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

#ifndef CompatibilityMacros_h
#define CompatibilityMacros_h

#if __has_feature(nullability)
    #define ART_ASSUME_NONNULL_BEGIN      NS_ASSUME_NONNULL_BEGIN
    #define ART_ASSUME_NONNULL_END        NS_ASSUME_NONNULL_END
    #define art_nullable                  nullable
    #define art_nonnull                   nonnull
    #define art_null_resettable           null_resettable
    #define __art_nullable                __nullable
    #define __art_nonnull                 __nonnull
#else
    #define ART_ASSUME_NONNULL_BEGIN
    #define ART_ASSUME_NONNULL_END
    #define art_nullable
    #define art_nonnull
    #define art_null_resettable
    #define __art_nullable
    #define __art_nonnull
#endif

#if __has_feature(objc_generics)
    #define __GENERIC(class, ...)         class<__VA_ARGS__>
    #define __GENERIC_TYPE(type)          type
#else
    #define __GENERIC(class, ...)         class
    #define __GENERIC_TYPE(type)          id
#endif

#endif /* CompatibilityMacros_h */
