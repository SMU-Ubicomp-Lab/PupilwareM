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
        if(canvas)
            cvReleaseImage(&canvas);
    }
    
    void PWGraph::drawGraph(const char *name,
                            const std::vector<float> &dataSrc,
                            cv::Scalar color,
                            float minVal,
                            float maxVal,
                            int width,
                            int height) {
        
        setCustomGraphColor(static_cast<int>(color[0]),
                            static_cast<int>(color[2]),
                            static_cast<int>(color[1]));
        
        canvas = drawFloatGraph(dataSrc.data(),
                                static_cast<int>(dataSrc.size()),
                                canvas, minVal,maxVal,width, height,
                                const_cast<char*>(name) );
    }
    
    void PWGraph::move(int x, int y) const {
        
        //No Implementation for IOS version.
    }
    
    void PWGraph::resize( int width, int height ) const{
        //No Implementation for IOS version.
    }
    
    void PWGraph::show() const{
        //No Implementation for IOS version.
        
        
    }
    
    const cv::Mat PWGraph::getGraphImage() const{
        return cv::cvarrToMat(canvas, true);
    }
}