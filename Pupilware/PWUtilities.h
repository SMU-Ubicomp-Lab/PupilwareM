//
//  PWUitlities.h
//  CogSense
//
//  Created by Mark Wang on 2/24/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#ifndef CogSense_PWUitlities_h
#define CogSense_PWUitlities_h
#include <vector>


//NSArray* vector2NSArray( std::vector<float> v );

double calStd( const std::vector<float>& v);

double calTrimStd( const std::vector<float>& v,
                  float percentTrim);
float median(std::vector<float> &v);

double calMad( std::vector<float>& v);

double calMadP( std::vector<float>& v);

float trimMean(std::vector<float> &v);

float average(std::vector<float> &v);


typedef float (*filterFunc) (std::vector<float>&v);

void filterSignal(std::vector<float>& input,
                  std::vector<float>& output,
                  int windowSize,
                  filterFunc filtFunc );

void medfilt(std::vector<float>& input,
             std::vector<float>& output,
             int windowSize = 5);

void movingAverage(std::vector<float>& input,
                   std::vector<float>& output,
                   int windowSize = 5);

void trimMeanFilt(std::vector<float>& input,
                  std::vector<float>& output,
                  int windowSize = 5);

std::vector<float> calZScore(std::vector<float> &v);

float calStableness(std::vector<float> &v);
std::vector<float> calSubstract(std::vector<float> &v1, std::vector<float> &v2);
std::vector<float> threadholdVector(std::vector<float>& v, float threadhold);


#endif
