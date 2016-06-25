//
// Created by Chatchai Wangwiwattana on 6/2/16.
//

#include "PWGraph.hpp"
#include "simpleGraph/GraphUtils.h"
namespace pw
{
    PWGraph::PWGraph(const char *name):
            canvas(nullptr),
            name(name)
    {

    }

    PWGraph::PWGraph(const PWGraph& other){}

    PWGraph::~PWGraph() {
        // No implementation on IOS version
    }

    void PWGraph::drawGraph(const char *name,
                            const std::vector<float> &dataSrc,
                            cv::Scalar color,
                            float minVal,
                            float maxVal,
                            int width,
                            int height) {

        // No implementation on IOS version
    }

    void PWGraph::move(int x, int y) const {

        // No implementation on IOS version
        
    }

    void PWGraph::resize( int width, int height ) const{
        // No implementation on IOS version
    }

    void PWGraph::show() const{
        
        // No implementation on IOS version

    }
}