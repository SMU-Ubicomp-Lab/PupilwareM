//
// Created by Chatchai Wangwiwattana on 6/15/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PUPILWARE_PREHEADER_HPP
#define PUPILWARE_PREHEADER_HPP

#include <cassert>
#include "Core/ThrowAssert.hpp"
#include "Core/Property.hpp"
#include "Core/logcpp/log.h"
#include "Core/profiler/CWClock.hpp"

#define REQUIRES throw_assert
#define PROMISES throw_assert

namespace pw{
    const bool DEBUG = true;
}

#endif //PUPILWARE_PREHEADER_HPP
