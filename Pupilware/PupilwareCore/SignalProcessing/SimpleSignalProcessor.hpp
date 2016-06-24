//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#ifndef PUPILWARE_BASICSIGNALPROCESSOR_HPP
#define PUPILWARE_BASICSIGNALPROCESSOR_HPP

#include "ISignalProcessor.hpp"

#include <vector>

#include <opencv2/opencv.hpp>

namespace pw{

    class BasicSignalProcessor: public ISignalProcessor {

    public:

        void process(std::vector<float> &leftEyeRadius,
                     std::vector<float> &rightEyeRadius,
                     std::vector<float> &eyeDistance,
                     std::vector<float> &result);


    private:
        cv::Mat getNanMask(cv::Mat v);

    };

}


#endif //PUPILWARE_BASICSIGNALPROCESSOR_HPP
