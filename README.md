# Binocular Stereo Vision 3D Reconstruction | 双目立体视觉三维重建系统

![MATLAB](https://img.shields.io/badge/MATLAB-R2024b-blue.svg)
![3D Vision](https://img.shields.io/badge/Domain-3D%20Computer%20Vision-orange.svg)

[**English**](#english) | [**中文说明**](#中文说明)

---

## English

### 📌 Project Overview
[cite_start]This repository contains the implementation of a 3D surface measurement system based on binocular stereo vision and structured light projection[cite: 50, 77]. [cite_start]The project successfully achieves the complete pipeline from hardware calibration to the 3D point cloud reconstruction of a plaster sculpture target[cite: 5].

### 🚀 Core Pipeline & Contributions
* [cite_start]**High-Precision Camera Calibration (Independent Contribution):** Calibrated the binocular camera system using Zhang's method with a 5mm checkerboard[cite: 8, 70]. [cite_start]Extracted intrinsic and extrinsic matrices and performed epipolar rectification to achieve strict row alignment of stereo pairs[cite: 8, 9, 132].
* [cite_start]**Phase Calculation & Unwrapping:** Implemented a three-frequency, four-step phase-shifting algorithm to extract continuous and absolute phase maps, effectively handling phase ambiguity [cite: 9, 138-143].
* [cite_start]**Stereo Matching & Denoising:** Applied masking techniques with customized thresholds to isolate the valid measurement region and eliminate background/shadow noise [cite: 9, 151-152, 179-180]. 
* [cite_start]**3D Point Cloud Generation:** Mapped 2D image coordinates to 3D spatial coordinates using disparity models and the principle of triangulation [cite: 10, 147-148]. [cite_start]Applied median filtering and moving median techniques for gentle hole-filling and smoothing [cite: 381-390].

### 🛠️ Getting Started
* [cite_start]**Environment:** MATLAB R2024b [cite: 69]
* [cite_start]**Dependencies:** Computer Vision Toolbox [cite: 69]
* [cite_start]**Usage:** 1. Set the correct paths for `left_image_folder` and `right_image_folder` in the main script [cite: 171-173].
  2. Run the main script. [cite_start]The system will process the raw fringe images, output phase maps, disparity maps, and render the final 3D point cloud [cite: 226-446].

---

## 中文说明

### 📌 项目简介
[cite_start]本项目完整实现了一套基于双目立体视觉和结构光投影的三维轮廓测量与重建系统 [cite: 50, 77][cite_start]。系统涵盖了从底层物理相机标定、极线校正、相位解算到最终生成石膏雕塑高精度三维点云的完整闭环流程 [cite: 5]。

### 🚀 核心技术链路与个人贡献
* [cite_start]**高精度相机标定 (独立负责模块)：** 采用张正友标定法，利用 5mm 物理尺寸的黑白棋盘格完成双目相机的精确标定 [cite: 5, 70][cite_start]。获取内外参矩阵后，对原始图像实施极线校正，实现左右图像行对齐，将二维搜索降维至一维 [cite: 5, 132]。
* [cite_start]**相位解算与解包裹：** 采用三频四步相移算法从采集的图像中提取包裹相位，并利用多频外差原理进行解包裹，获取高精度的绝对相位图 [cite: 138-143]。
* [cite_start]**立体匹配与掩码去噪：** 利用双阈值掩码 (Mask) 技术有效剔除背景阴影与噪点，提取出待测物体的有效区域，并在极线上进行亚像素级别的相位匹配 [cite: 5, 145, 151-152, 179-180]。
* [cite_start]**三维点云重建：** 建立视差模型，基于三角测量原理将像素坐标映射为三维空间坐标 [cite: 5, 147-148][cite_start]。引入基于移动中值 (`movmedian`) 的算法填补点云细小空洞，输出平滑的高保真 3D 模型 [cite: 381-390, 435-436]。

### 🛠️ 环境依赖与快速运行
* [cite_start]**运行环境：** MATLAB R2024b [cite: 69]
* [cite_start]**依赖工具箱：** Computer Vision Toolbox [cite: 69]
* **运行步骤：**
  1. [cite_start]在主程序中修改左右相机的图片路径 (`left_image_folder` / `right_image_folder`) [cite: 171-173]。
  2. [cite_start]直接运行主程序，系统将自动进行相位解算、立体匹配并弹出最终的 3D 扫描复原图 [cite: 226-446]。

### 📊 效果展示
*(请在此处替换为你 `results/` 文件夹中的图片链接)*
* [左侧放置极线校正/掩码图]
* [中间放置深度视差图]
* [右侧放置最终重建的 3D 点云图]
