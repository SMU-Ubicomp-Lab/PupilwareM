//
// Created by Chatchai Wangwiwattana on 6/7/16.
//

#ifndef PUPILWARE_PWTYPES_HPP
#define PUPILWARE_PWTYPES_HPP

namespace pw{

    struct PWPupilSize{
        PWPupilSize(float leftRadius, float rightRadius):
                leftRadius(leftRadius),rightRadius(rightRadius)
        { }

        float leftRadius;
        float rightRadius;
    };

}

#endif //PUPILWARE_PWTYPES_HPP
