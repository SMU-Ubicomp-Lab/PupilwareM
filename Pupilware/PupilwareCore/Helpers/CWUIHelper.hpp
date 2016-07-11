//
// Created by Chatchai Wangwiwattana on 5/26/16.
//

#ifndef PUPILWARE_CWUIHELPER_HPP
#define PUPILWARE_CWUIHELPER_HPP

#include <vector>
#include <opencv2/opencv.hpp>

#include "CVWindow.hpp"

namespace cw {

    void showGraph(const std::string& name,
                   const std::vector<float> &dataSrc,
                   int delayInMilliSec = 1,
                   cv::Scalar color = cv::Scalar(0, 0, 0));


    int showImage(const std::string& name,
                  const cv::Mat img,
                  int delayInMilliSec = 1);


    std::shared_ptr<pw::CVWindow> createWindow( const std::string& winName);


    void namedWindow(const std::string& winName,
                     int flag=cv::WINDOW_NORMAL);


    void createTrackbar(const std::string& barName,
                    const std::string& windowName,
                    int& value, int max,
                    cv::TrackbarCallback callback = nullptr,
                    void* userData = nullptr );


    void imshow(const std::string& winName, cv::InputArray mat);

    int waitKey(int delay);

}

#endif //PUPILWARE_CWUIHELPER_HPP
