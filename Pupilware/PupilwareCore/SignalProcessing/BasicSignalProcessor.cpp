//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#include "BasicSignalProcessor.hpp"

#include "../preHeader.hpp"

#include "SignalProcessingHelper.hpp"

using namespace cv;

namespace pw{

    cv::Mat BasicSignalProcessor::getNanMask(cv::Mat v)
    {
        cv::Mat mask = cv::Mat(v == v);
        return mask;
    }

    void BasicSignalProcessor::process(const std::vector<float> &leftEyeRadius,
                                       const std::vector<float> &rightEyeRadius,
                                       const std::vector<float> &eyeDistance,
                                       std::vector<float> &result)
    {

        const unsigned int MEDIAN_WINDOW_SIZE = 31;

        REQUIRES(leftEyeRadius.size() == rightEyeRadius.size(), "Left eye and right eye array size must be equal array size.");
        REQUIRES(eyeDistance.size() > 0, "Eyedistance array size must not be zero");
        REQUIRES(leftEyeRadius.size() > 0, "left eye array size must not be zero.");
        
        
        if(leftEyeRadius.size() <= MEDIAN_WINDOW_SIZE)
        {
            std::cout<< "The pupil vector is less than Window Size. " << std::endl;
            return;
        }
        
        
        if(leftEyeRadius.size() != rightEyeRadius.size()) {
            std::cout
            << "The left eye and right eye is not equal size. Left:"
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

        /* Normalized raw pupil size to ratio, so the pupil size is equal regardless of distance from the cameara. */
        std::vector<float> pupilSize_EyeDistance_Ratio;
        for (size_t i=0; i<smoothPupilDiameter.size(); i++) {
            float avgPupilRadius = static_cast<float>(smoothPupilDiameter[i]) * 0.5f;
            pupilSize_EyeDistance_Ratio.push_back( avgPupilRadius / static_cast<float>(smoothEyeDistance[i]));
        }


        /* Then normalize to percent change from baseline */
        float pupilSizeRatioBaseline = 1.0f;
        float q = cw::calQuantilef(pupilSize_EyeDistance_Ratio, 10);
        pupilSizeRatioBaseline = std::fmax(0.001, q);
        
        REQUIRES(pupilSizeRatioBaseline > 0, "Baseline must not be zero.");

        Mat percentChange_FromBaseline;
        cv::subtract(pupilSize_EyeDistance_Ratio,
                     Mat::ones(1, (int)pupilSize_EyeDistance_Ratio.size(), CV_32F) * pupilSizeRatioBaseline,
                     percentChange_FromBaseline);

        cv::divide(percentChange_FromBaseline,
                   Mat::ones(1, (int)pupilSize_EyeDistance_Ratio.size(), CV_32F) * pupilSizeRatioBaseline,
                   percentChange_FromBaseline);


        Mat NanMask = getNanMask(percentChange_FromBaseline);

        /* Copy result and return */
        percentChange_FromBaseline.copyTo(result, NanMask);
        
        
        PROMISES(result.size() > 0, "Result array size must not be zero");

    }

}