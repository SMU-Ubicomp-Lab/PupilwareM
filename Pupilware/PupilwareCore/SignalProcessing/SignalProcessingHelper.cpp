//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#include "SignalProcessingHelper.hpp"

#include <cassert>
#include <numeric>

namespace cw {


    float median( std::vector<float> &v )
    {
        if (v.size() <= 0)
        {
            return 0.0f;
        }

        std::vector<float>cpy;
        cpy.assign(v.begin(), v.end());

        size_t n = v.size() / 2;
        nth_element(cpy.begin(), cpy.begin()+n, cpy.end());
        return cpy[n];
    }


    float trimMean( std::vector<float> &v)
    {
        if (v.size() <= 0)
        {
            return 0.0f;
        }

        sort(v.begin(), v.end());

        int trimSize = static_cast<int>(v.size() * 0.2);

        double sum_of_elems = std::accumulate(v.begin()+trimSize,v.end()-trimSize, 0);
        return sum_of_elems/(v.size() - (trimSize*2));
    }


    float average( std::vector<float> &v)
    {
        if (v.size() <= 0)
        {
            return 0.0f;
        }

        float sum = 0.0f;
        for( const float & item : v)
        {
            sum += item;
        }

        return sum/(float)v.size();
    }

    void medfilt( std::vector<float>& input,
                 std::vector<float>& output, int windowSize)
    {
        filterSignal(input, output, windowSize, median);
    }

    void fastMedfilt(   const std::vector<float>& input,
                        std::vector<float>& output, int windowSize  )
    {
        cw::FastMedianFilter medfiltF(windowSize);
        output = medfiltF.filter(input);
    }

    void movingAverage( std::vector<float>& input, std::vector<float>& output, int windowSize)
    {
        filterSignal(input, output, windowSize, average);
    }

    void trimMeanFilt( std::vector<float>& input, std::vector<float>& output, int windowSize)
    {
        filterSignal(input, output, windowSize, trimMean);
    }


    void filterSignal( std::vector<float> &input,
                      std::vector<float> &output,
                      int windowSize, filterFunc filtFunc) {

        assert(input.size() > 0);
        assert(windowSize > 0);

        if (input.size() <= 0) {
            return;
        }

        if (windowSize <= 0) {
            return;
        }

        if (input.size() < windowSize) {
            windowSize = (int) input.size();
        }

        // allocate memory
        output.resize(input.size());

        int midPos = windowSize / 2;

        // fill the first haft of data
        for (size_t i = 0; i < midPos; i++) {
            auto p_start = input.begin();
            auto p_end = input.begin() + i + 1;

            std::vector<float> nWindow;
            nWindow.assign(p_start, p_end);

            float m = filtFunc(nWindow);
            output[i] = m;

        }

        // fill the rest of the data
        for (size_t i = 0; i < input.size() - midPos; i++) {

            auto p_start = input.begin() + i;
            auto p_end = input.begin() + i + windowSize;

            std::vector<float> nWindow;
            nWindow.assign(p_start, p_end);

            float m = filtFunc(nWindow);
            output[midPos + i] = m;
        }

        assert(output.size() > 0);
    }

    ////////////////////////////////


    unsigned keep_odd(unsigned n)
    {
        if(n % 2 == 0) return n + 1;

        return n;
    }


    FastMedianFilter::FastMedianFilter(unsigned window_size)
                :
                _history(keep_odd(window_size), float()),
                _pool(_history),
                _median(window_size / 2 + 1)
        {
            assert(window_size >= 3);
        }


        std::vector<float> FastMedianFilter::filter(const std::vector<float> & in)
        {
            assert(in.size() > 0);

            //---------------------------------------------------------------------
            // init state

            unsigned hist_ptr = 0;

            std::fill(_history.begin(), _history.end(), in[0]);
            std::fill(_pool.begin(), _pool.end(), in[0]);

            // pool is keep sorted

            //---------------------------------------------------------------------
            // filter input

            std::vector<float> out;
            out.reserve(in.size());

            for(auto x : in)
            {
                // step 1, remove oldest value from the pool.

                auto last = _history[hist_ptr];

                auto last_pos = std::lower_bound(_pool.begin(), _pool.end(), last);

                _pool.erase(last_pos);

                // step 2, insert new value into pool

                auto insert_pos = std::lower_bound(_pool.begin(), _pool.end(), x);

                _pool.insert(insert_pos, x);

                // step 3, write input value into history.

                _history[hist_ptr] = x;

                hist_ptr = (hist_ptr + 1) % _history.size();

                // median is always the middle of the pool

                out.push_back(_pool[_median]);
            }

            return out;
        }

}