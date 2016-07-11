//
// Created by Chatchai Wangwiwattana on 6/8/16.
//

#include "ALOfflineFile.hpp"

#include <fstream>
#include <cstring>


using namespace std;

namespace pw{

    ALOfflineFile::ALOfflineFile( const std::string& name,
                                  const std::string &fileName,
                                  unsigned int downSampleSize):
            IPupilAlgorithm(name)
            ,filename(fileName)
            ,sampleSize(downSampleSize){

    }

    ALOfflineFile::~ALOfflineFile() {

    }

    void ALOfflineFile::init() {
        // read a csv file
        std::ifstream file;
        file.open(filename, std::ios::in);

        if (file.is_open()){

            string time;
            string eyeDistance;
            string left;
            string right;

            while ( file.good() )
            {
                getline ( file, time, ',' );
                getline ( file, eyeDistance, ',' );
                getline ( file, left, ',' );
                getline ( file, right);

                if(!time.empty())
                {
                    timeList.push_back(stof(time));
                    eyeDistanceList.push_back(stof(eyeDistance));
                    leftPupilSizeList.push_back(stof(left));
                    rightPupilSizeList.push_back(stof(right));
                }
            }


        }else {

            std::cerr << "[Error] Data file is not exited." << __func__ << std::endl;
            return;
        }

        // process data
        cv::resize(leftPupilSizeList, leftPupilSizeList, cv::Size(sampleSize, 1));
        cv::resize(rightPupilSizeList, rightPupilSizeList, cv::Size(sampleSize, 1));
        cv::resize(eyeDistanceList, eyeDistanceList, cv::Size(sampleSize, 1));
        cv::resize(timeList, timeList, cv::Size(sampleSize, 1));


    }



    PWPupilSize ALOfflineFile::process( const cv::Mat& src, const PWFaceMeta &meta )
    {

        const int frameNumber = meta.getFrameNumber();

        return pw::PWPupilSize(    leftPupilSizeList[frameNumber] / eyeDistanceList[frameNumber]
                                 , rightPupilSizeList[frameNumber] / eyeDistanceList[frameNumber]);

    }


    void ALOfflineFile::exit() {

    }

}