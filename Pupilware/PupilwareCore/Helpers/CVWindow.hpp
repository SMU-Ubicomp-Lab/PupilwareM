//
// Created by Chatchai Wangwiwattana on 5/30/16.
//

#ifndef PUPILWARE_CVWINDOW_HPP
#define PUPILWARE_CVWINDOW_HPP

#include <string>
#include <opencv2/opencv.hpp>

namespace pw{

    class CVWindow {
    public:

        CVWindow(const std::string& winName);
        CVWindow(const CVWindow& other);
        ~CVWindow();

        void addTrackbar(const std::string& label,
                         int* value,
                         int max=255);

        void addTrackbarDouble(const std::string &label,
                                         void(*f)(double value),
                                         double max);

        int update(cv::Mat mat);

        void moveWindow(int x, int y);

        void resize( int width, int height);

        void setTrackbarValue( const std::string& name, int value ) const;

    private:
        std::string winName;

    };

}



#endif //PUPILWARE_CVWINDOW_HPP
