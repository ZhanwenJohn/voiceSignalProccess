function T0 = pitfilterm1(period, voiceseg, vosl)
    % 基音周期平滑处理函数
    % 输入:
    %   period: 原始基音周期序列
    %   voiceseg: 语音段信息结构体数组
    %   vosl: 语音段数量
    % 输出:
    %   T0: 平滑后的基音周期序列

    % 初始化平滑后的基音周期序列
    T0 = zeros(size(period));

    % 对每个语音段进行处理
    for k = 1:vosl
        % 获取当前语音段的起始和结束帧索引
        start_idx = voiceseg(k).begin;
        end_idx = voiceseg(k).end;

        % 提取当前语音段的基音周期
        segment_period = period(start_idx:end_idx);

        % 对当前语音段的基音周期进行平滑处理
        smoothed_segment = smooth(segment_period, 5);  % 使用窗口大小为5的平滑

        % 将平滑后的基音周期赋值回原始序列
        T0(start_idx:end_idx) = smoothed_segment;
    end
end
