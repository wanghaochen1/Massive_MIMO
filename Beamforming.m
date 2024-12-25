clear all;
close all;

% 参数设置
lambda = 1;
f = 3;
k = 2 * pi / lambda;
omega = 2 * pi * f;
phase_diff = pi / 2;
d = lambda;

% 空间和时间参数
x = linspace(-3 * lambda, 3 * lambda, 100);
y = linspace(-3 * lambda, 3 * lambda, 100);
[X, Y] = meshgrid(x, y);
dt = 0.02;
t = 0:dt:2;

% 源的位置
source1_pos = [-d / 2, 0];
source2_pos = [d / 2, 0];

% 创建图形窗口
figure('Position', [100 100 800 600]);

% 动态演示
for time = t
    % 计算到每个点的距离
    R1 = sqrt((X - source1_pos(1)) .^ 2 + (Y - source1_pos(2)) .^ 2);
    R2 = sqrt((X - source2_pos(1)) .^ 2 + (Y - source2_pos(2)) .^ 2);

    % 计算每个源的波场
    wave1 = cos(k * R1 - omega * time);
    wave2 = cos(k * R2 - omega * time + phase_diff);

    % 波场叠加
    total_wave = wave1 + wave2;

    % 使用mesh替代surf
    mesh(X, Y, total_wave, 'EdgeColor', 'interp');

    % 设置绘图属性
    zlim([-2.5 2.5]);
    xlabel('X (λ)');
    ylabel('Y (λ)');
    zlabel('Amplitude');
    title(['两个天线震源叠加波场 - t = ' num2str(time, '%.2f') 's']);
    colormap('jet');
    colorbar;

    % 设置视角
    view(-30, 45);

    % 添加源的位置标记（调整标记大小使其更显眼）
    hold on;
    plot3(source1_pos(1), source1_pos(2), 0, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
    plot3(source2_pos(1), source2_pos(2), 0, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
    hold off;

    % 添加网格
    grid on;

    % 更新显示
    drawnow;
end
