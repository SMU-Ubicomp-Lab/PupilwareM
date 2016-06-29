//
// Created by Chatchai Wangwiwattana on 6/2/16.
//

#ifndef PUPILWARE_PWGRAPH_HPP
#define PUPILWARE_PWGRAPH_HPP

#include <opencv2/opencv.hpp>

namespace pw{

    class PWGraph {
    private:
        IplImage* canvas;
        std::string name;

    public:
        PWGraph(const char* title);
        PWGraph(const PWGraph& other);
        ~PWGraph();

        void drawGraph(const char *name,
                       const std::vector<float> &dataSrc,
                       cv::Scalar color,
                       float minVal = 0.0,
                       float maxVal = 0.0,
                       int width = 0,
                       int height = 0);

        void move(int x, int y) const;
        void resize( int width, int height ) const;
        void show() const;
        const cv::Mat getGraphImage() const;
    };

}


#endif //PUPILWARE_PWGRAPH_HPP
