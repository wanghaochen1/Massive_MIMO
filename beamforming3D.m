% 3D波束成形可视化 - 动态扫描
% By: GitHub Copilot

% 参数设置
Nx = 8;                % x方向天线数量
Ny = 8;                % y方向天线数量
d = 0.5;              % 阵元间距(wavelength)
filename = 'beamscanning.gif';
delayTime = 0.1;

% 创建球面网格
[theta, phi] = meshgrid(linspace(0, 180, 180), linspace(0, 360, 360));
theta_rad = theta * pi/180;
phi_rad = phi * pi/180;

% 创建图形窗口
figure('Position', [100 100 800 800]);

% 扫描循环
for theta0 = 0:5:60  % 俯仰角扫描范围
    for phi0 = 0:10:360  % 方位角扫描范围
        % 计算相位差
        phase_shifts = zeros(Nx, Ny);
        for nx = 1:Nx
            for ny = 1:Ny
                phase_shifts(nx,ny) = -2*pi * d * (...
                    (nx-1) * sin(theta0*pi/180)*cos(phi0*pi/180) + ...
                    (ny-1) * sin(theta0*pi/180)*sin(phi0*pi/180));
            end
        end
        
        % 计算阵列因子
        AF = zeros(size(theta));
        for i = 1:size(theta, 1)
            for j = 1:size(theta, 2)
                AF_temp = 0;
                for nx = 1:Nx
                    for ny = 1:Ny
                        spatial_phase = 2*pi * d * (...
                            (nx-1) * sin(theta_rad(i,j))*cos(phi_rad(i,j)) + ...
                            (ny-1) * sin(theta_rad(i,j))*sin(phi_rad(i,j)));
                        AF_temp = AF_temp + exp(1i * (spatial_phase + phase_shifts(nx,ny)));
                    end
                end
                AF(i,j) = abs(AF_temp)/(Nx*Ny);
            end
        end
        
        % 转换为球坐标
        r = ones(size(theta));
        x = r .* sin(theta_rad) .* cos(phi_rad);
        y = r .* sin(theta_rad) .* sin(phi_rad);
        z = r .* cos(theta_rad);
        
        % 更新图形
        clf;
        surf(x, y, z, AF);
        colormap('jet');
        colorbar;
        shading interp;
        
        % 设置图形属性
        axis equal;
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title(sprintf('3D波束方向图 (θ_0=%d°, φ_0=%d°)', theta0, phi0));
        rotate3d on;
        
        % 捕获帧并写入GIF
        frame = getframe(gcf);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        if theta0 == 0 && phi0 == 0
            imwrite(imind,cm,filename,'gif','Loopcount',inf,'DelayTime',delayTime);
        else
            imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',delayTime);
        end
        
        drawnow;
        pause(0.01);
    end
end