function spring_calc()
    % =========================================================
    % 压缩弹簧参数计算器
    % 使用前请修改下方 "用户输入参数" 模块
    % =========================================================
    clc; clear; close all;

    %% 1. 用户输入参数
    d = 1.0;        % 线径 (mm)
    D2 = 15;        % 外径 (mm)
    H0 = 105;       % 自由长度 (mm)
    n = 19;         % 有效圈数
    G = 79000;      % 剪切模量 (MPa, 弹簧钢65Mn/60Si2Mn约为79000，不锈钢约71000)
    
    %% 2. 几何计算
    D = D2 - d;             % 中径 (mm)
    C = D / d;              % 弹簧指数
    nt = n + 2;             % 总圈数 (两端并紧磨平)
    Hb = nt * d;            % 压并高度 (mm)
    f_max = H0 - Hb;        % 理论最大压缩量 (mm)
    
    %% 3. 刚度计算
    k = (G * d^4) / (8 * D^3 * n);    % 刚度 (N/mm)
    F_max = k * f_max;                % 压并时的最大理论力 (N)
    
    %% 4. 应力校核 (Wahl修正)
    Kw = (4*C - 1)/(4*C - 4) + 0.615/C; % 应力修正系数
    tau_max = (8 * F_max * D * Kw) / (pi * d^3); % 压并时最大切应力 (MPa)
    
    %% 5. 稳定性判断 (长细比)
    ratio = H0 / D;         % 长细比
    stability = "良好";
    if ratio > 5.3
        stability = "极差，必须加导杆或套筒";
    elseif ratio > 2.6
        stability = "一般，建议加导杆";
    end
    
    %% 6. 输出结果
    fprintf('================ 弹簧计算报告 ================\n');
    fprintf('输入参数:\n');
    fprintf('  线径 d = %.2f mm, 外径 D2 = %.2f mm, 自由长度 H0 = %.2f mm\n', d, D2, H0);
    fprintf('  有效圈数 n = %.1f, 中径 D = %.2f mm, 弹簧指数 C = %.2f\n', n, D, C);
    fprintf('----------------------------------------------\n');
    fprintf('计算结果:\n');
    fprintf('  刚度 k = %.4f N/mm\n', k);
    fprintf('  压并高度 Hb = %.2f mm\n', Hb);
    fprintf('  最大压缩量 f_max = %.2f mm\n', f_max);
    fprintf('  压并最大力 F_max = %.2f N (%.2f kgf)\n', F_max, F_max/9.8);
    fprintf('  最大切应力 tau = %.2f MPa\n', tau_max);
    fprintf('----------------------------------------------\n');
    fprintf('设计建议:\n');
    fprintf('  长细比 H0/D = %.2f -> 稳定性: %s\n', ratio, stability);
    
    if tau_max > 600
        fprintf('  ⚠️ 警告: 压并应力超过600MPa，极易发生塑性变形或断裂！\n');
    elseif tau_max > 480
        fprintf('  ⚠️ 注意: 压并应力偏高，建议限制最大压缩量，不要压并。\n');
    else
        fprintf('  ✅ 应力在安全范围内。\n');
    end
    fprintf('==============================================\n');
    
    %% 7. 绘制特性曲线 (可选)
    x_plot = linspace(0, f_max, 100);
    F_plot = k * x_plot;
    figure('Name', '弹簧特性曲线');
    plot(x_plot, F_plot, 'b-', 'LineWidth', 2);
    grid on;
    xlabel('压缩量 x (mm)');
    ylabel('弹簧力 F (N)');
    title('压缩弹簧力-位移特性曲线');
    % 标出压并点
    hold on;
    plot(f_max, F_max, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    text(f_max, F_max, sprintf('  压并点 (%.1fmm, %.1fN)', f_max, F_max), ...
        'VerticalAlignment', 'bottom');
end