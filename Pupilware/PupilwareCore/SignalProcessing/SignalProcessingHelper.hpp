//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#ifndef PUPILWARE_SIGNALPROCESSINGHELPER_HPP
#define PUPILWARE_SIGNALPROCESSINGHELPER_HPP


#include <vector>
#include <cassert>

namespace cw{

    
    double calStd( const std::vector<float>& v);
    
    
    typedef float (*filterFunc) ( std::vector<float>&v);


    void medfilt(           const std::vector<float> &input,
                            std::vector<float> &output,
                            int windowSize);

    void movingAverage(     std::vector<float> &input,
                            std::vector<float> &output,
                            int windowSize);

    void trimMeanFilt(      std::vector<float> &input,
                            std::vector<float> &output,
                            int windowSize);

    void filterSignal(      std::vector<float> &input,
                            std::vector<float> &output,
                            int windowSize,
                            filterFunc filtFunc);

    //-----------------------------------------------------------
    
    float calQuantilef( const std::vector<float>& data, int percent );

    
    //-----------------------------------------------------------
    // This class is modified from Weegreenblobie benchmark test
    // https://github.com/weegreenblobbie/median_filter_benchmark
    class FastMedianFilter
    {
        std::vector<float> _history;
        std::vector<float> _pool;
        unsigned       _median;

    public:

        FastMedianFilter(unsigned window_size);

        std::vector<float> filter(const std::vector<float> & in);

    };


    void fastMedfilt(       const std::vector<float> &input,
                            std::vector<float> &output,
                            int windowSize);
}


#endif //PUPILWARE_SIGNALPROCESSINGHELPER_HPP
