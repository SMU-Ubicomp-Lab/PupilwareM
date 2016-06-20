//
//  PWUtilities.m
//  CogSense
//
//  Created by Mark Wang on 2/24/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PWUtilities.h"
#include <numeric>

//NSArray* vector2NSArray( std::vector<float> v )
//{
//    if(v.size() <= 0 )
//        return nil;
//    
//    float percentTrim = 0.05;
//    int trimSize = v.size()*percentTrim;
//    
//    NSMutableArray *buffer = [[NSMutableArray alloc] init];
//    for( int i=trimSize; i<v.size()-trimSize; i++)
//    {
//        [buffer addObject:@(v[i])];
//    }
//    
//    return [NSArray arrayWithArray:buffer];
//}

NSArray* vector2NSArrayTrim( std::vector<float> v, float percentTrim )
{
    if(v.size() <= 0 )
        return nil;
    
    int trimSize = v.size()/percentTrim;
    
    NSMutableArray *buffer = [[NSMutableArray alloc] init];
    for( int i=trimSize; i<v.size()-trimSize; i++)
    {
        [buffer addObject:@(v[i])];
    }
    
    return [NSArray arrayWithArray:buffer];
}

std::vector<float> threadholdVector(std::vector<float>& v, float threadhold)
{
    std::vector<float> returnVector;
    
    for (size_t i =0; i <v.size(); i++)
    {
        if (v[i] <= threadhold)
        {
            returnVector.push_back(v[i]);
        }
        
    }
    
    return returnVector;
}

//TODO need testing!
double calMad( std::vector<float>& v)
{
    double medianOfV = median(v);
    
    std::vector<float>absMedianOfV;
    absMedianOfV.resize(v.size());
    
    for (size_t i =0; i <v.size(); i++)
    {
        absMedianOfV[i] = fabs(v[i]-medianOfV);
    }
    double madV = median(absMedianOfV);
    
    return madV;
}

double calMadP( std::vector<float>& v)
{
    double medianOfV = median(v);
    
    std::vector<float>absMedianOfV;
    absMedianOfV.resize(v.size());
    
    for (size_t i =0; i <v.size(); i++)
    {
        absMedianOfV[i] = fabs(v[i]-medianOfV)/medianOfV;
    }
    double madV = median(absMedianOfV);
    
    return madV;
}


double calStd( const std::vector<float>& v)
{
    double sum = std::accumulate(v.begin(), v.end(), 0.0);
    double mean = sum / v.size();
    
    double sq_sum = std::inner_product(v.begin(), v.end(), v.begin(), 0.0);
    double stdev = std::sqrt(sq_sum / v.size() - mean * mean);
    
    return stdev;
}

// TODO This function is wrong! do not use it!!
double calTrimStd( const std::vector<float>& v, float percentTrim)
{
    assert(false);
    assert(percentTrim >=0 );
    assert(percentTrim <=0.5);
    
    std::vector<float> sortedV;
    sortedV.assign(v.begin(), v.end());
    std::sort(sortedV.begin(), sortedV.end());
    
    int offset = sortedV.size()*percentTrim;
    double sum = std::accumulate(sortedV.begin()+offset, sortedV.end()-offset, 0.0);
    double mean = sum / (sortedV.size()-(offset*2));
    
    double sq_sum = std::inner_product(sortedV.begin()+offset, sortedV.end()+offset, sortedV.begin()+offset, 0.0);
    double stdev = std::sqrt((sq_sum / (sortedV.size()-(offset*2))) - mean * mean);
    
    return stdev;
}

//---------------------------------------------


float median(std::vector<float> &v)
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

float trimMean(std::vector<float> &v)
{
    if (v.size() <= 0)
    {
        return 0.0f;
    }
    
    sort(v.begin(), v.end());
    
    int trimSize = (int) v.size() * 0.2;
    
    double sum_of_elems =std::accumulate(v.begin()+trimSize,v.end()-trimSize, 0);
    return sum_of_elems/(v.size() - (trimSize*2));
}

float average(std::vector<float> &v)
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

std::vector<float> calZScore(std::vector<float> &v)
{
    std::vector<float>z;
    z.resize(v.size());
    
    float std = calStd(v);
    float mean = average(v);

    for (int i=0; i<z.size(); i++) {
        z[i] = (v[i] - mean)/std;
    }
    
    return z;
}

std::vector<float> calSubstract(std::vector<float> &v1, std::vector<float> &v2)
{
    
    assert(v1.size()>0);
    assert(v2.size()>0);
    assert(v1.size() == v2.size());
    
    std::vector<float>s;
    s.resize(v1.size());
    
    for (int i=0; i<s.size(); i++) {
        s[i] = (v1[i] - v2[i]);
    }
    
    return s;
}

float calStableness(std::vector<float> &v)
{
    std::vector<float>z = (v);
    
    std::vector<float>trend;
    
    std::vector<float>medV;
    medfilt(z, medV, 21);
    movingAverage(medV, trend, 9);
    
    std::vector<float>sub;
    sub = calSubstract(z, trend);
    
    float mad = calMad(sub);
    float med = median(sub);
    
    return mad;
}

void filterSignal(std::vector<float>& input, std::vector<float>& output, int windowSize, filterFunc filtFunc )
{
    assert(input.size() > 0);
    assert(windowSize > 0);
    
    if (input.size() <= 0)
    {
        return;
    }
    
    if (windowSize <= 0)
    {
        return;
    }
    
    
    if (input.size() < windowSize)
    {
        windowSize = (int)input.size();
    }
    
    // allocate memory
    output.resize(input.size());
    
    int midPos = windowSize/2;
    
    // fill the first haft of data
    for (size_t i=0; i<midPos; i++)
    {
        auto p_start = input.begin();
        auto p_end = input.begin()+i+1;
        
        std::vector<float>nWindow;
        nWindow.assign(p_start, p_end);
        
        float m = filtFunc(nWindow);
        output[i] = m;
        
    }
    
    // fill the rest of the data
    for (size_t i=0; i<input.size()-midPos; i++)
    {
        
        auto p_start = input.begin()+i;
        auto p_end = input.begin()+i+windowSize;
        
        std::vector<float>nWindow;
        nWindow.assign(p_start, p_end);
        
        float m = filtFunc(nWindow);
        output[midPos+i] = m;
    }
    
    assert(output.size() > 0);
}

void medfilt(std::vector<float>& input, std::vector<float>& output, int windowSize)
{
    filterSignal(input, output, windowSize, median);
}

void movingAverage(std::vector<float>& input, std::vector<float>& output, int windowSize)
{
    filterSignal(input, output, windowSize, average);
}

void trimMeanFilt(std::vector<float>& input, std::vector<float>& output, int windowSize)
{
    filterSignal(input, output, windowSize, trimMean);
}