%% 主程序：双目结构光相位处理 (支持左右不同阈值)
clear; clc; close all;

% ===================== 1. 参数设置 =====================
left_image_folder = 'C:\Users\mmr\Desktop\马文睿实验\matlab实验\matlab实验\条纹图\图片\16'; 
% 右相机图片文件夹
right_image_folder = 'C:\Users\mmr\Desktop\马文睿实验\matlab实验\matlab实验\条纹图\图片\74'; 

% 处理结果保存路径
output_folder = 'C:\Users\mmr\Desktop\马文睿实验\matlab实验\matlab实验\条纹图\处理结果';

% ---分别设置左右阈值 ---
% 如果觉得掩码有的地方空了（阈值太高），就把数值调小
% 如果觉得背景噪点太多（阈值太低），就把数值调大
t_threshold_L = 0.8; % 左相机阈值
t_threshold_R = 0.7; % 右相机阈值 (根据实际亮度调整，右图通常可能更亮或更暗)

% 文件名列表
file_names = {
'1.pgm', '2.pgm', '3.pgm', '4.pgm', ...
'5.pgm', '6.pgm', '7.pgm', '8.pgm', ...
'9.pgm', '10.pgm', '11.pgm', '12.pgm'
};

% 检查输出文件夹
if ~exist(output_folder, 'dir'), mkdir(output_folder); end

%% ===================== 2. 处理左相机 =====================
fprintf('--------------------------------------\n');
fprintf('正在处理左相机 (阈值 t=%.2f)...\n', t_threshold_L);
try
% 传入左阈值
[denoised_phase_L, mask_L] = process_camera_folder(left_image_folder, file_names, t_threshold_L);
fprintf('左相机完成。\n');
catch ME
fprintf('左相机出错: %s\n', ME.message);
return;
end

%% ===================== 3. 处理右相机 =====================
fprintf('--------------------------------------\n');
fprintf('正在处理右相机 (阈值 t=%.2f)...\n', t_threshold_R);
try
% 传入右阈值
[denoised_phase_R, mask_R] = process_camera_folder(right_image_folder, file_names, t_threshold_R);
fprintf('右相机完成。\n');
catch ME
fprintf('右相机出错: %s\n', ME.message);
return;
end

%% ===================== 4. 调试：检查掩码质量 =====================
% 这一步非常关键！用于肉眼判断阈值是否合适
figure('Name', '左右掩码对比 (检查是否包含完整物体)', 'Position', [100, 200, 1200, 500]);

subplot(1, 2, 1);
imagesc(mask_L); axis image; colormap jet; title(['左掩码 (t=' num2str(t_threshold_L) ')']);
xlabel('红色=保留区域，深蓝=剔除区域');

subplot(1, 2, 2);
imagesc(mask_R); axis image; colormap jet; title(['右掩码 (t=' num2str(t_threshold_R) ')']);


%% ===================== 5. 保存数据 =====================

save_path_L_mat = fullfile(output_folder, 'denoised_phase_L.mat');
save_path_R_mat = fullfile(output_folder, 'denoised_phase_R.mat');

save(save_path_L_mat, 'denoised_phase_L', 'mask_L');
save(save_path_R_mat, 'denoised_phase_R', 'mask_R');

fprintf('--------------------------------------\n');
fprintf('数据已保存。\n');



%% ========================================================================
% 辅助函数：封装了核心处理逻辑
% ========================================================================
function [denoised_img, final_mask] = process_camera_folder(image_folder, file_names, t_threshold)
% 检查路径是否存在
if ~exist(image_folder, 'dir')
error('文件夹不存在: %s', image_folder);
end
% 获取图片的尺寸信息
first_filename = fullfile(image_folder, file_names{1});
if ~exist(first_filename, 'file')
error('在文件夹 %s 中找不到第一个文件: %s', image_folder, file_names{1});
end
first_img = imread(first_filename);
[height, width, ~] = size(first_img);
% 初始化存储图片的矩阵
img_stack = zeros(height, width, 12);
% 读取12张图片
fprintf('正在从 %s 读取图片...\n', image_folder);
for i = 1:12
filename = fullfile(image_folder, file_names{i});
if ~exist(filename, 'file')
error('文件不存在: %s', filename);
end
a = imread(filename);
if size(a, 3) == 3
a = rgb2gray(a);
end
a = double(a) / 255.0;
img_stack(:, :, i) = a;
end
% 初始化变量
temq = zeros(height, width, 3);
temg = zeros(height, width, 3);
fai = zeros(height, width, 3);
n = zeros(height, width, 2);
fi = zeros(height, width, 3);
% 计算相位
fprintf('计算包裹相位...\n');
for k = 0:2
temq(:,:,k+1) = img_stack(:,:,4*k+4) - img_stack(:,:,4*k+2);
temg(:,:,k+1) = img_stack(:,:,4*k+1) - img_stack(:,:,4*k+3);
fai(:,:,k+1) = atan2(temq(:,:,k+1), temg(:,:,k+1)); 
end
% 相位解包裹
fprintf('进行多频相位解包裹...\n');
% 1. 低频相位处理
fi(:,:,1) = fai(:,:,1);
negative_phase_mask = fi(:,:,1) < 0;
fi(:,:,1) = fi(:,:,1) + negative_phase_mask * 2*pi;
% 2. 中频相位解包裹
n(:,:,1) = round((4*fi(:,:,1) - fai(:,:,2)) / (2*pi));
fi(:,:,2) = fai(:,:,2) + 2*pi*n(:,:,1);
% 3. 高频相位解包裹
n(:,:,2) = round((4*fi(:,:,2) - fai(:,:,3)) / (2*pi));
fi(:,:,3) = fai(:,:,3) + 2*pi*n(:,:,2);
% 掩码去噪部分
fprintf('应用掩码去噪 (阈值 t=%.2f)...\n', t_threshold);
I1 = img_stack(:,:,9); 
I2 = img_stack(:,:,10); 
I3 = img_stack(:,:,11); 
I4 = img_stack(:,:,12); 
mask_sum = I1 + I2 + I3 + I4;
% 直接生成逻辑矩阵(0和1)，然后转为double类型
final_mask = double(mask_sum > t_threshold);
% 读取高频解包裹图像
unwrapped_img = fi(:,:,3);
% 去噪操作
denoised_img = unwrapped_img .* final_mask;
end





%% ================= 1. 加载数据与准备 =================
% 路径设置 (请修改为你保存结果的实际路径)
output_folder = 'C:\Users\mmr\Desktop\马文睿实验\matlab实验\matlab实验\条纹图\处理结果';
calib_file = 'calibrationSession.mat';
str_file='stereoParams.mat';

fprintf('正在加载标定参数与相位数据...\n');
try
load( str_file);
% 加载上一步保存的去噪后的相位和掩码
load(fullfile(output_folder, 'denoised_phase_L.mat'), 'denoised_phase_L', 'mask_L');
load(fullfile(output_folder, 'denoised_phase_R.mat'), 'denoised_phase_R', 'mask_R');
catch
error('文件加载失败，请检查路径及文件名！');
end

% 1. 极线校正 (算法 Input 要求：完成校正的高频解包裹相位图)
fprintf('正在进行极线校正...\n');
% J1: 左图 (基准), J2: 右图 (待匹配)
[J1, J2] = rectifyStereoImages(denoised_phase_L, denoised_phase_R, stereoParams, 'OutputView', 'valid', 'Interp', 'linear');
% 校正掩码，用于去除阴影噪点
[mask_rect_L, mask_rect_R] = rectifyStereoImages(double(mask_L), double(mask_R), stereoParams, 'OutputView', 'valid', 'Interp', 'nearest');
figure;
imshowpair(J1,J2)
% 应用掩码：将背景区域置为0 (满足 J1(i,j)==0 continue 的条件)
J1(mask_rect_L == 0) = 0;
J2(mask_rect_R == 0) = 0;

% 获取图像尺寸
[rows, cols] = size(J1);
x = rows; 
y = cols;

%% ================= 2. 提取参数 (用于后续公式) =================
baseline_distance = norm(stereoParams.TranslationOfCamera2); % 基线
pp1 = stereoParams.CameraParameters1.PrincipalPoint; % 左主点
pp2 = stereoParams.CameraParameters2.PrincipalPoint; % 右主点
F_avg = (mean(stereoParams.CameraParameters1.FocalLength) + ...
mean(stereoParams.CameraParameters2.FocalLength)) / 2; % 平均焦距

fprintf('参数提取: 基线=%.2f, F_avg=%.2f\n', baseline_distance, F_avg);

%% ================= 3. 相位匹配 (保留三重循环) =================
fprintf('开始运行相位匹配算法 (三重循环，速度较慢，请耐心)... \n');
disparityMap = nan(x, y); % 初始化视差图

for i = 1:x
% 进度提示 (防止以为卡死)
if mod(i, 10) == 0, fprintf('正在处理第 %d / %d 行...\n', i, x); end
line_left = J1(i,:);
line_right = J2(i,:);
for j = 1:y
if(J1(i,j)==0)
continue;
end
% 搜索循环
for test = 1 : y-1
% 判断条件
if (line_left(j) >= line_right(test)) && ...
(line_left(j) < line_right(test+1)) && ...
(line_right(test) ~= 0)
upper = line_right(test+1);
lower = line_right(test);
% 线性插值原理
delta = (line_left(j) - lower) ./ (upper - lower) .* (test+1 - test);
% conditions : (两像素点间容错机制 <= pi/4)
if (upper - lower <= pi/4)
% 像素视差值
% 这里改用 disparityMap 存储，避免覆盖 matlab 的 disp 函数
disparityMap(i,j) = j - (test + delta);
% 优化：找到匹配点后通常不需要继续搜索当前行的其他点匹配同一个左点
%break; % (如果需要严格保留暴力搜索逻辑，可以注释掉 break)
end
end
end
end
end
x_start = 3181;
x_end = size(disparityMap, 2); % 裁剪到图像最右侧，或者改为你需要的结束 X 坐标
y_start = 280;
y_end = 1330;
% 3. 执行抠图（矩阵切片）
% 格式：croppedData = 矩阵(纵向范围, 横向范围, 通道)
disparityMap = disparityMap(y_start:y_end, x_start:x_end, :);

disparityMap(disparityMap > 3250) = nan;
disparityMap(disparityMap < 2600) = nan;
%window_size = [3 3]; 
%disparityMap = medfilt2(disparityMap, window_size);
%% ================= 3.1 温和修补 (只填坑，不误删) =================
fprintf('正在进行温和修补...\n');

% 1. 基础降噪 (去除个别极值点)
% 保持窗口小一点，避免把细节抹平
disparityMap = medfilt2(disparityMap, [3 3]); 

% 2. 核心步骤：填补细小空洞 (类似于PS的内容识别填充)
% 我们只填补“被有效数据包围”的小黑点，而不是大块的背景
try
% 生成有效数据的掩码
valid_mask = ~isnan(disparityMap);
% 填充空洞 (基于周围像素进行插值)
% 'movmedian' 移动中值填充比 linear 更稳健，不会产生奇怪的拉丝
% window 设为 10，表示只填补小于 10 个像素宽度的缝隙
filled_disp = fillmissing(disparityMap, 'movmedian', 7); 
% 融合策略：
% 只有当 原数据是NaN 且 填充后的数据有效 时，才采纳填充值
% 这样可以保证原有的有效数据（您的脸部细节）绝对不会被修改！
mask_to_fill = isnan(disparityMap) & ~isnan(filled_disp);
disparityMap(mask_to_fill) = filled_disp(mask_to_fill);
fprintf('细小空洞已填补。\n');
catch
warning('填补函数运行受限，跳过此步。');
end

% 3. (可选) 极其微弱的导向滤波，让皮肤看起来更滑一点点
% 如果还是觉得不够滑，可以取消注释下面这行
%disparityMap = imguidedfilter(disparityMap, 'NeighborhoodSize', [3 3], 'DegreeOfSmoothing', 0.01);

% 4. 再次执行深度截断 (保留您原有的逻辑)
disparityMap(disparityMap > 3250) = nan;
disparityMap(disparityMap < 2600) = nan;

% 5. 再次确保 (0,0,0) 这种噪点在最后被干掉 (双重保险)
% 注意：这一步是在生成点云前做的，这里先在视差图层面上不做处理
% 等生成 x_r, y_r, z_r 后再用我最早给您的代码去除 (0,0,0)

% 显示当前状态
figure; 
imshow(disparityMap, []); 
colormap jet; colorbar;
title('温和修补后的视差图 (无块状缺失)');
%% ================= 4. 三维重建 (向量化极速版) =================
fprintf('开始运行三维重建算法 (向量化加速中)... \n');

% 1. 生成网格坐标矩阵 (替代双重循环中的 row, col)
[cols_grid, rows_grid] = meshgrid(1:size(disparityMap, 2), 1:size(disparityMap, 1));

% 2. 计算 w (直接矩阵运算)
% 注意：任何 disparityMap 为 NaN 的地方，计算结果也会是 NaN，自动过滤
term1 = -disparityMap ./ baseline_distance;
term2 = (pp1(1) - pp2(1)) ./ baseline_distance;
w = term1 + term2;

% 3. 计算 x_r, y_r, z_r (利用点除 ./)
% 为了防止除以0，可以将 w 中为0的地方设为 NaN (虽然概率很低)
w(w == 0) = NaN; 

x_r = (cols_grid - pp1(1)) ./ w;
y_r = (rows_grid - pp1(2)) ./ w;
z_r = F_avg ./ w + 3.5;

% 4. 再次确保 (0,0,0) 被去除 (应用上面的修复逻辑)
bad_points_idx = (abs(x_r) < 1e-4) & (abs(y_r) < 1e-4) & (abs(z_r) < 1e-4);
x_r(bad_points_idx) = NaN;
y_r(bad_points_idx) = NaN;
z_r(bad_points_idx) = NaN;

% 5. 合成点云
point_cloud_matrix = cat(3, x_r, y_r, z_r);
point_cloud = pointCloud(point_cloud_matrix);

fprintf('三维重建完成。\n');
%% ==========================================
% 合成点云数据
point_cloud_matrix = cat(3, x_r, y_r, z_r);
point_cloud = pointCloud(point_cloud_matrix);


%% ================= 5. 显示与去噪 (保留特定阈值) =================

figure;
pcshow(point_cloud);
title('滤波重建点云 (Original)');
xlabel('X'); ylabel('Y'); zlabel('Z');
