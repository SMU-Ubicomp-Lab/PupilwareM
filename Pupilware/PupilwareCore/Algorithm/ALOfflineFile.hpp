//
// Created by Chatchai Wangwiwattana on 6/8/16.
//

#ifndef PUPILWARE_ALOFFLINEFILE_HPP
#define PUPILWARE_ALOFFLINEFILE_HPP

#include "IPupilAlgorithm.hpp"

namespace pw{

    class ALOfflineFile: public IPupilAlgorithm {
    public:

        ALOfflineFile( const std::string& name,
                       const std::string& fileName,
                       unsigned int downSampleSize);
        
        ALOfflineFile( const ALOfflineFile& other)=default;
        ALOfflineFile( ALOfflineFile&& other)=default;
        ALOfflineFile& operator=( const ALOfflineFile& other)=default;
        ALOfflineFile& operator=( ALOfflineFile&& other)= default;
        
        virtual ~ALOfflineFile();

        virtual void init() override ;

        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override;

        virtual void exit() override;

        
    private:
        std::string filename;
        unsigned int sampleSize;

        std::vector<float> timeList;
        std::vector<float> eyeDistanceList;
        std::vector<float> leftPupilSizeList;
        std::vector<float> rightPupilSizeList;
    };

}

#endif //PUPILWARE_ALOFFLINEFILE_HPP
