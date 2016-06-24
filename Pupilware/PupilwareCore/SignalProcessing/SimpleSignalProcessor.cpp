//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#include "SimpleSignalProcessor.hpp"
#include "SignalProcessingHelper.hpp"


using namespace cv;

namespace pw{

    cv::Mat BasicSignalProcessor::getNanMask(cv::Mat v)
    {
        cv::Mat mask = cv::Mat(v == v);
        return mask;
    }

    void BasicSignalProcessor::process(std::vector<float> &leftEyeRadius,
                                       std::vector<float> &rightEyeRadius,
                                       std::vector<float> &eyeDistance,
                                       std::vector<float> &result)
    {

        const unsigned int MEDIAN_WINDOW_SIZE = 11;

        if(leftEyeRadius.size() <= MEDIAN_WINDOW_SIZE) { std::cout<< "The pupil vector is less than Window Size. " << std::endl; return;}
        if(leftEyeRadius.size() != rightEyeRadius.size()) {
            std::cout<< "The left eye and right eye is not equal size. Left:"
            << leftEyeRadius.size() << " right:" << rightEyeRadius.size()
            << std::endl;
            return;
        }

        std::vector<float> pupilDiameter;
        cv::add(leftEyeRadius, rightEyeRadius, pupilDiameter);

        std::vector<float> smoothPupilDiameter;
        cw::fastMedfilt(pupilDiameter, smoothPupilDiameter, MEDIAN_WINDOW_SIZE);

        std::vector<float>smoothEyeDistance;
        cw::fastMedfilt(eyeDistance, smoothEyeDistance, MEDIAN_WINDOW_SIZE);

        std::vector<float> pupilSize_EyeDistance_Ratio;
        for (size_t i=0; i<smoothPupilDiameter.size(); i++) {
            float avgPupilRadius = static_cast<float>(smoothPupilDiameter[i]) * 0.5f;
            pupilSize_EyeDistance_Ratio.push_back( avgPupilRadius / static_cast<float>(smoothEyeDistance[i]));
        }

#pragma warning change baseline to the real data
//TODO: change baseline to the real baseline

        //! It MUST NOT be a Zero or Negative number.
        float pupilSizeRatioBaseline = 1.0f;
        assert(pupilSizeRatioBaseline > 0);

        Mat percentChange_FromBaseline;
        cv::subtract(pupilSize_EyeDistance_Ratio,
                     Mat::ones(1, (int)pupilSize_EyeDistance_Ratio.size(), CV_32F) * pupilSizeRatioBaseline,
                     percentChange_FromBaseline);

        cv::divide(percentChange_FromBaseline,
                   Mat::ones(1, (int)pupilSize_EyeDistance_Ratio.size(), CV_32F) * pupilSizeRatioBaseline,
                   percentChange_FromBaseline);

        //cv::GaussianBlur(percentChange_FromBaseline, percentChange_FromBaseline, cv::Size(windowSize_ud,windowSize_ud), 15);

        Mat NanMask = getNanMask(percentChange_FromBaseline);

        percentChange_FromBaseline.copyTo(result, NanMask);

    }

}