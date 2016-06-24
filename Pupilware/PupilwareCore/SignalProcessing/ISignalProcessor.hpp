//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#ifndef PUPILWARE_ISIGNALPROCESSOR_HPP
#define PUPILWARE_ISIGNALPROCESSOR_HPP

#include <vector>

namespace pw{

    class ISignalProcessor {
    public:
        ISignalProcessor();
        ISignalProcessor(const ISignalProcessor& other);
        virtual ~ISignalProcessor();

        virtual void process(std::vector<float> &leftEyeRadius,
                             std::vector<float> &rightEyeRadius,
                             std::vector<float> &eyeDistance,
                             std::vector<float> &result) = 0;
    };

}


#endif //PUPILWARE_ISIGNALPROCESSOR_HPP
