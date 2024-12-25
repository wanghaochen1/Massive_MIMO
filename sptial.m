% 电磁波无MIMO仿真 %
% writer:whc 2024/12/22 %
filename = 'particle_simulation.gif';
delayTime = 0.1;


% Simulation parameters
numParticles = 256;
fieldSize = [100 100];
particleSpeed = 2;
numTimeSteps = 200;

% 创建障碍 (format: [x y width height])
obstacles = [
    30 20 10 40;
    60 50 30 10;
    20 70 15 20
    ];

%创建空间
tx = [50 50];

% 随机设置接收者，这里设置2个
rx1 = [randi([1,fieldSize(1)]) randi([1,fieldSize(2)])];
rx2 = [randi([1,fieldSize(1)]) randi([1,fieldSize(2)])];
while norm(rx2 - rx1) < 20  % Ensure receivers aren't too close
    rx2 = [randi([1,fieldSize(1)]) randi([1,fieldSize(2)])];
end

%将电磁波以粒子的形式进行展示
particles = repmat(tx, numParticles, 1);
angles = 2*pi*rand(numParticles, 1);
velocities = [particleSpeed*cos(angles) particleSpeed*sin(angles)];

% 初始化计数器
rx1Count = 0;
rx2Count = 0;

figure('Position', [100 100 800 800]);
hold on;
axis([0 fieldSize(1) 0 fieldSize(2)]);

% 绘制障碍物
for i = 1:size(obstacles,1)
    rectangle('Position', obstacles(i,:), 'FaceColor', [0.7 0.7 0.7]);
end

for t = 1:numTimeSteps
    % Update 粒子位置
    particles = particles + velocities;

    % 检查边界的碰撞
    [particles, velocities] = checkBoundaryCollisions(particles, velocities, fieldSize);

    % 检查障碍碰撞
    [particles, velocities] = checkObstacleCollisions(particles, velocities, obstacles);

    % Check receiver collisions
    [particles, velocities, rx1Count, rx2Count] = checkReceiverCollisions(...
        particles, velocities, rx1, rx2, rx1Count, rx2Count);
    if isempty(particles)
        fprintf('Simulation ended: All particles absorbed\n');
        fprintf('Final counts - Receiver 1: %d, Receiver 2: %d\n', rx1Count, rx2Count);
        break;
    end
    % 重新绘制下时刻的状态
    clf;
    hold on;
    axis([0 fieldSize(1) 0 fieldSize(2)]);


    % 绘制障碍
    for i = 1:size(obstacles,1)
        rectangle('Position', obstacles(i,:), 'FaceColor', [0.7 0.7 0.7]);
    end

    plot(tx(1), tx(2), 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    plot(rx1(1), rx1(2), 'bs', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    plot(rx2(1), rx2(2), 'gs', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(particles(:,1), particles(:,2), 'k.', 'MarkerSize', 8);

    % 计数器
    title(sprintf('Receiver 1: %d particles, Receiver 2: %d particles', rx1Count, rx2Count));
    drawnow;
    pause(0.05);
    frame = getframe(gcf);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    
    % 写入GIF文件
    if t == 1
        imwrite(imind,cm,filename,'gif','Loopcount',inf,'DelayTime',delayTime);
    else
        imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',delayTime);
    end
    
    pause(0.05);
end

% 函数部分
function [particles, velocities] = checkBoundaryCollisions(particles, velocities, fieldSize)
% 边界碰撞检测
xBoundary = particles(:,1) < 0 | particles(:,1) > fieldSize(1);
yBoundary = particles(:,2) < 0 | particles(:,2) > fieldSize(2);
hitBoundary = xBoundary | yBoundary;

if any(hitBoundary)
    %归一化随机进行判断
    probs = rand(sum(hitBoundary), 1);

    % 20% 概率反弹，远处楼群的反射概率
    bounce = probs < 0.2;

    % 粒子反弹
    bounceIdx = find(hitBoundary);
    bounceIdx = bounceIdx(bounce);

    velocities(bounceIdx(xBoundary(bounceIdx)),1) = -velocities(bounceIdx(xBoundary(bounceIdx)),1);
    velocities(bounceIdx(yBoundary(bounceIdx)),2) = -velocities(bounceIdx(yBoundary(bounceIdx)),2);

    % 80%的概率粒子消失
    removeIdx = find(hitBoundary);
    removeIdx = removeIdx(~bounce);
    particles(removeIdx,:) = [];
    velocities(removeIdx,:) = [];
end
end

function [particles, velocities] = checkObstacleCollisions(particles, velocities, obstacles)
for i = 1:size(obstacles,1)
    obs = obstacles(i,:);
    % 检测是否在障碍物内部
    inside = particles(:,1) >= obs(1) & particles(:,1) <= obs(1)+obs(3) & ...
        particles(:,2) >= obs(2) & particles(:,2) <= obs(2)+obs(4);

    if any(inside)
        % 归一化概率
        probs = rand(sum(inside), 1);
        collidingIdx = find(inside);
        collidingIdx = sort(collidingIdx, 'descend');

        % 对每个障碍物内的粒子操作
        for j = 1:length(collidingIdx)
            idx = collidingIdx(j);
            if probs(j) < 0.4  % 40% 的透射
                continue;
            elseif probs(j) < 0.6  % 20% 的吸收概率，这个概率已经很高了。实际上远比这个要低
                particles(idx,:) = [];
                velocities(idx,:) = [];
            else  % 40% 反弹
                velocities(idx,:) = -velocities(idx,:);
                particles(idx,:) = particles(idx,:) - velocities(idx,:);
            end
        end
    end
end
end

function [particles, velocities, rx1Count, rx2Count] = checkReceiverCollisions(...
    particles, velocities, rx1, rx2, rx1Count, rx2Count)
% 接收端收到的信息
rx_radius = 3;

% 距离检测
dist_rx1 = sqrt(sum((particles - rx1).^2, 2));
dist_rx2 = sqrt(sum((particles - rx2).^2, 2));

% 接收检测
rx1Count = rx1Count + sum(dist_rx1 < rx_radius);
rx2Count = rx2Count + sum(dist_rx2 < rx_radius);

% 吸收的就消失了
absorbed = (dist_rx1 < rx_radius) | (dist_rx2 < rx_radius);
particles(absorbed,:) = [];
velocities(absorbed,:) = [];
end