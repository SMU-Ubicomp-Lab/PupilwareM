//
// Created by Chatchai Wangwiwattana on 5/30/16.
//

#include "CVWindow.hpp"

#include "../preHeader.hpp"

namespace pw{

    class DoubleTrack{
    public:

        int int_value = 0;
        double precision;
        void(*user_callback)(double);

        void setup(const std::string& field_name
                , const std::string& window_name
                , void(*function)(double)
                , double max_value
                , double default_value = 0
                , unsigned precision = 100){


            int_value = default_value * precision;
            cv::createTrackbar(field_name, window_name, &int_value, max_value * precision, DoubleTrack::callback, this);
            user_callback = function;
            this->precision = precision;

        }


        static void callback(int, void* object){

            DoubleTrack* pObject = static_cast<DoubleTrack*>(object);
            pObject->user_callback(pObject->int_value / pObject->precision);

        }

    };


    CVWindow::CVWindow(const std::string& winName):
    winName(winName){
        cv::namedWindow(winName, CV_WINDOW_NORMAL);
    }

    CVWindow::CVWindow(const CVWindow &other) {

    }

    CVWindow::~CVWindow() {

        if(!winName.empty())
            cv::destroyWindow( this->winName );

    }

    void CVWindow::addTrackbar(const std::string &label, int *value, int max) {
        cv::createTrackbar(label, this->winName, value, max);
    }

    void CVWindow::addTrackbarDouble(const std::string &label, void(*f)(double), double max) {

        throw_assert(false, "This function has not been implemented. ");
        DoubleTrack().setup(label, this->winName, f, max);
    }

    void CVWindow::moveWindow(int x, int y){

        cv::moveWindow(winName, x, y);

    }

    void CVWindow::resize( int width, int height){


        cv::resizeWindow(winName, width, height);

    }

    int CVWindow::update(cv::Mat mat) {

        cv::imshow(winName, mat);
        return cv::waitKey(1);
    }

    void CVWindow::setTrackbarValue( const std::string& name, int value ) const{
        cv::setTrackbarPos(name, winName, value);
    }

}


