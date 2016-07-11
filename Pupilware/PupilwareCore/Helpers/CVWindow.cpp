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


            // No implementation on IOS version

        }


        static void callback(int, void* object){

            // No implementation on IOS version

        }

    };


    CVWindow::CVWindow(const std::string& winName):
    winName(winName){
        // No implementation on IOS version
    }

    CVWindow::CVWindow(const CVWindow &other) {

    }

    CVWindow::~CVWindow() {

        // No implementation on IOS version

    }

    void CVWindow::addTrackbar(const std::string &label, int *value, int max) {
        // No implementation on IOS version
    }

    void CVWindow::addTrackbarDouble(const std::string &label, void(*f)(double), double max) {

        // No implementation on IOS version);

    }

    void CVWindow::moveWindow(int x, int y){

        // No implementation on IOS version

    }

    void CVWindow::resize( int width, int height){

        // No implementation on IOS version

    }

    int CVWindow::update(cv::Mat mat) {

        // No implementation on IOS version
        
        return 0;
    }

    void CVWindow::setTrackbarValue( const std::string& name, int value ) const{
        // No implementation on IOS version
    }

}


