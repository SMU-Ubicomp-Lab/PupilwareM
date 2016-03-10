#ifndef CONSTANTS_H
#define CONSTANTS_H

// Settings

#define kEyeDistance    @"s_eyeDistance"
#define kWindowSize     @"s_windowSize"
#define kMbWindowSize   @"s_mbWindowSize"
#define kBaselineStart  @"s_baselineStart"
#define kBaselineEnd    @"s_baselineEnd"
#define kThreshold      @"s_threshold"
#define kMarkCost       @"s_markCost"

#define kBaseline       @"s_baseLine"
#define kCogHighSize    @"s_cogHighSize"

// Debugging
const bool kPlotVectorField = false;

// Size constants
const int kEyePercentTop = 30;
const int kEyePercentSide = 13;
const int kEyePercentHeight = 20;
const int kEyePercentWidth = 35;

// Preprocessing
const bool kSmoothFaceImage = false;
const float kSmoothFaceFactor = 0.005f;

// Algorithm Parameters
const int kFastEyeWidth = 50;
const int kWeightBlurSize = 5;
const bool kEnableWeight = false;
const float kWeightDivisor = 150.0;
const double kGradientThreshold = 50.0;

// Postprocessing
const bool kEnablePostProcess = true;
const float kPostProcessThreshold = 0.97f;

// Eye Corner
const bool kEnableEyeCorner = false;

#endif