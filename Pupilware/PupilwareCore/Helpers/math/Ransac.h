#pragma once
#include <opencv2/opencv.hpp>
#include <vector>
#include "Circle.h"

namespace pw
{
	class Ransac
	{

	public:
		void getThreeRandomPoints( int max_num, int* out_random_nums  );
		int num_samples_circle( int nsample, int ngood,  double p );
		bool ransac_circle_fitting(std::vector<cv::Point2f>, int N,
			int ngood_pts,               //num of good input(estimation);
			double p_fail,                //prior prb. algorithm exit without having a good fits;

			double distance_th,       //fitting distance threshold;
			int    samples_th,           //minimum num of final fitting data.
			std::vector<cv::Point2f>& out_inliner );
        float distance_sq( cv::Point2f * pt1, cv::Point2f * pt2);

		Circle bestModel;
	private:

	};

}