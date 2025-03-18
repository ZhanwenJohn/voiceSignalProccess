clear;
close all;

%% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);

%% 如果是立体声，转换为单声道（取平均值）
if size(y, 2) > 1
    y = mean(y, 2);
end

%% 设定帧长和帧移
frame_duration = 0.025;  % 25ms 帧长
frame_length = round(frame_duration * fs);

%% 生成汉明窗
hamming_window = hamming(frame_length, 'periodic');

%% 处理帧
start_idx = 120000;
end_idx = start_idx + frame_length - 1;
frames = y(start_idx:end_idx)' .* hamming_window';


%% 绘图
figure;
plot((0:frame_length-1) / fs, frames);
xlabel('时间 (秒)');
ylabel('振幅');
grid on;