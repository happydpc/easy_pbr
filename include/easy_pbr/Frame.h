#pragma once

#include <Eigen/Geometry>
#include <opencv2/highgui/highgui.hpp>

#include "easy_pbr/Mesh.h"

#ifdef WITH_TORCH
    #include "torch/torch.h"
#endif

namespace easy_pbr{

class Frame {
public:
    // EIGEN_MAKE_ALIGNED_OPERATOR_NEW
    Frame();

    int width=-1;
    int height=-1;

    cv::Mat rgb_8u;
    cv::Mat rgb_32f; // becasue some algorithms like the cnns require floating point tensors
    // cv::Mat_<cv::Vec4b> rgba_8u; //Opengl likes 4 channels images
    // cv::Mat_<cv::Vec4f> rgba_32f; //Opengl likes 4 channels images
    cv::Mat gray_32f;
    cv::Mat grad_x_32f;
    cv::Mat grad_y_32f;
    cv::Mat gray_with_gradients; //gray image and grad_x and grad_y into one RGB32F image, ready to be uploaded to opengl

    cv::Mat thermal_16u;
    cv::Mat thermal_32f;
    cv::Mat thermal_vis_32f; //for showing only we make the thermal into a 3 channel one so imgui shows it in black and white

    cv::Mat mask;
    cv::Mat depth;
    unsigned long long int timestamp;
    Eigen::Matrix3f K = Eigen::Matrix3f::Identity();
    Eigen::Matrix<float, 5, 1> distort_coeffs;
    Eigen::Affine3f tf_cam_world = Eigen::Affine3f::Identity();

    int cam_id; //id of the camera depending on how many cameras we have (it gos from 0 to 1 in the case of stereo)
    int frame_idx; //frame idx monotonically increasing

    bool is_last=false; //is true when this image is the last in the dataset
    bool is_keyframe=false; //if it is keyframe we would need to create seeds

    Mesh create_frustum_mesh(float scale_multiplier=1.0);
    void rotate_y_axis(const float rads );
    Mesh backproject_depth() const;
    Mesh assign_color(Mesh& cloud);
    std::shared_ptr<Mesh> pixel_world_direction(); //return a mesh where the V vertices represent directions in world coordiantes in which every pixel of this camera looks through
    cv::Mat rgb_with_valid_depth(const Frame& frame_depth);

    //getters that are nice to have for python bindings
    Eigen::Vector3f pos_in_world();

    #ifdef WITH_TORCH
        torch::Tensor rgb2tensor();
        torch::Tensor depth2tensor();
        void tensor2rgb(const torch::Tensor& tensor);
        void tensor2gray(const torch::Tensor& tensor);
        void tensor2depth(const torch::Tensor& tensor);
    #endif



};

} //namespace easy_pbr