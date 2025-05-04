%% 清除缓存
clear;
clc;
close all;
%% 预处理
% 读取音频文件
[file, path] = uigetfile('*.wav', '选择WAV文件');
filename = fullfile(path, file);
[y, fs] = audioread(filename);
y = y - mean(y);
y = y / max(abs(y));
times = (0:length(y) - 1) / fs;
% 分帧处理
frame_length = 320;
frame_shift = 80;
overlap = frame_length - frame_shift;
fn = fix((length(y) - frame_length) / frame_shift) + 1;
frames = zeros(frame_length, fn);

for i = 1:fn
    start_idx = (i - 1) * frame_shift + 1;
    end_idx = start_idx + frame_length - 1;
    frames(:, i) = y(start_idx:end_idx);
end

%% 计算每帧的时间坐标
frame_times = (0:fn-1) * frame_shift / fs + (frame_length / (2 * fs));

%% 基音的端点检测
T1 = 0.05;
[voiceseg, vosl, SF, Ef] = pitch_vad1(frames, fn, T1);

%% 倒谱法基音检测
lmin=fix(fs/500);                           % 基音周期的最小值
lmax=fix(fs/60);                            % 基音周期的最大值
period=zeros(1,fn);                         % 基音周期初始化
R=zeros(1,fn); 
Lc=zeros(1,fn);
for k=1:fn 
    if SF(k)==1                             % 是否在有话帧中
        windows_frames=frames(:,k).*hamming(frame_length);           % 取来一帧数据加窗函数
        win_frame_fft=fft(windows_frames);                         % FFT
        a=2*log(abs(win_frame_fft)+eps);               % 取模值和对数
        b=ifft(a);                          % 求取倒谱 
        [R(k),Lc(k)]=max(b(lmin:lmax));     % 在lmin和lmax区间中寻找最大值
        period(k)=Lc(k)+lmin-1;             % 给出基音周期
    end
end

%% 作图
subplot 211, plot(times,y,'b');  title('语音信号')
axis([0 max(times) -1 1]); ylabel('幅值');
subplot 212; plot(frame_times,period,'b');
xlim([0 max(times)]); title('基音周期'); 
grid; xlabel('时间/s'); ylabel('样点数');
for k=1 : vosl                              % 标出有话段
    nx1=voiceseg(k).begin;
    nx2=voiceseg(k).end;
    nxl=voiceseg(k).duration;
    fprintf('%4d   %4d   %4d   %4d\n',k,nx1,nx2,nxl);
    subplot 211
    line([frame_times(nx1) frame_times(nx1)],[-1 1],'color','b','linestyle','-');
    line([frame_times(nx2) frame_times(nx2)],[-1 1],'color','b','linestyle','--');
end