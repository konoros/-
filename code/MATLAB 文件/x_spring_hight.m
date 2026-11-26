clear; clc; close all;

%% ==================== 参数输入区 ====================

fprintf('====== 轮腿机器人向前跳跃距离计算 ======\n\n');
fprintf('（运动学模型与 PSO 代码完全一致）\n\n');

% --- 质量参数（与 PSO 完全一致）---
m_l1 = 0.6;         % 单条大腿质量 (kg)
m_l2 = 0.4;         % 单条小腿质量 (kg)
m_body = 5.5;       % 机体质量 (kg)
m_wheel = 0.65;     % 单轮质量 (kg)
g = 9.81;           % 重力加速度 (m/s²)

% --- 最优参数（来自 PSO 优化结果）---
l1 = 0.22;        % 大腿长度 (m)
l2 = 0.22;        % 小腿长度 (m)
phi1_deg = 60.00;   % 缩腿角度 (度)
phi2_deg = 150.00;  % 离地瞬间角度 (度)
phi3_deg = 121.44;  % 最高点角度 (度)
tau = 10.00;        % 关节扭矩 (N·m)

% --- 驱动轮参数 ---
omega_wheel = 12.5;   % 离地瞬间驱动轮角速度 (rad/s)
R_wheel = 0.077;     % 轮子半径 (m)

fprintf('参数输入完成，开始计算...\n\n');

%% ==================== 第一部分：运动学建模 ====================

fprintf('--- 运动学建模 ---\n');
syms cx cy real
syms theta1 theta2 real

dy = l1 * cos(theta1);  dx = l1 * sin(theta1);
ey = l1 * cos(theta2);  ex = l1 * sin(theta2);

eq1 = (cx - dx)^2 + (cy - dy)^2 == l2^2;
eq2 = (cx - ex)^2 + (cy - ey)^2 == l2^2;
sol = solve([eq1, eq2], [cx, cy], 'Real', true);

fprintf('  运动学方程求解完成\n');

%% ==================== 第二部分：三个状态的机体高度 ====================

fprintf('\n--- 各状态机体高度 ---\n');

phi1 = deg2rad(phi1_deg);
phi2 = deg2rad(phi2_deg);
phi3 = deg2rad(phi3_deg);

% State 1
cy_expr1 = subs(sol.cy, [theta1, theta2], [phi1, -phi1]);
ay_phi1 = -double(cy_expr1(1));
fprintf('  State1 (缩腿) 机体y坐标: %.5f m\n', ay_phi1);

% State 2
cy_expr2 = subs(sol.cy, [theta1, theta2], [phi2, -phi2]);
ay_phi2 = -double(cy_expr2(1));
fprintf('  State2 (离地) 机体y坐标: %.5f m\n', ay_phi2);

% State 3
cy_expr3 = subs(sol.cy, [theta1, theta2], [phi3, -phi3]);
ay_phi3 = -double(cy_expr3(1));
fprintf('  State3 (最高) 机体y坐标: %.5f m\n', ay_phi3);

%% ==================== 第三部分：跳跃高度计算 ====================

fprintf('\n--- 跳跃高度计算 ---\n');

h1 = ay_phi2 - ay_phi1;
h2 = (2*tau*(phi2 - phi1) - (m_body + 2*m_l1 + 2*m_l2)*g*h1) ...
     / (m_body + 2*m_l1 + 2*m_l2 + m_wheel) / g;
h3 = ay_phi2 - ay_phi3;
H  = h2 + h3;

fprintf('  地面伸腿位移 h1 = %.5f m\n', h1);
fprintf('  腾空高度     h2 = %.5f m\n', h2);
fprintf('  空中收腿高度 h3 = %.5f m\n', h3);
fprintf('  ★ 总跳跃高度  H = %.4f m (%.1f cm)\n', H, H*100);

%% ==================== 第四部分：向前跳跃距离计算 ====================

fprintf('\n--- 向前跳跃距离计算 ---\n');

vx = omega_wheel * R_wheel;
vy = sqrt(2 * g * h2);

a_eq = -0.5 * g;
b_eq = vy;
c_eq = ay_phi2;
discriminant = b_eq^2 - 4*a_eq*c_eq;
t_flight = (-b_eq - sqrt(discriminant)) / (2*a_eq);

D = vx * t_flight;

fprintf('  离地水平速度 vx = %.3f m/s\n', vx);
fprintf('  离地竖直速度 vy = %.3f m/s\n', vy);
fprintf('  起跳点高度   y0 = %.5f m\n', ay_phi2);
fprintf('  空中飞行时间 t  = %.4f s\n', t_flight);
fprintf('  ★ 向前跳跃距离 D = %.4f m (%.1f cm)\n', D, D*100);

%% ==================== 第五部分：约束检查 ====================

fprintf('\n--- 约束检查 ---\n');
w1 = 2*(phi2 - phi1) / 0.1;
w2 = 2*(phi3 - phi2) / 0.1;
F  = 2*tau / 1;

fprintf('  角速度 w1 = %.1f rad/s (限值 80) %s\n', w1, checkMark(w1<=80));
fprintf('  角速度 w2 = %.1f rad/s (限值 80) %s\n', w2, checkMark(w2<=80));
fprintf('  作用力 F  = %.1f N     (限值 100) %s\n', F, checkMark(F<=100));

%% ==================== 第六部分：结果汇总 ====================

fprintf('\n========================================\n');
fprintf('         ★ 最终计算结果 ★\n');
fprintf('========================================\n');
fprintf('  总跳跃高度  H = %.4f m  (%.1f cm)\n', H, H*100);
fprintf('  向前跳跃距离 D = %.4f m  (%.1f cm)\n', D, D*100);
fprintf('  空中飞行时间 t = %.4f s\n', t_flight);
fprintf('========================================\n');

%% ==================== 绘图 ====================

figure('Name', '轮腿机器人跳跃分析', 'Position', [100, 100, 900, 400]);

t_plot = linspace(0, t_flight, 100);
x_plot = vx * t_plot;
y_plot = ay_phi2 + vy * t_plot - 0.5 * g * t_plot.^2;

subplot(1, 2, 1);
plot(x_plot, y_plot, 'b-', 'LineWidth', 2); hold on;
plot(0, ay_phi2, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g');
plot(D, 0, 'r*', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
xlabel('水平距离 (m)'); ylabel('高度 (m)');
title(sprintf('跳跃轨迹\nD = %.3f m, H = %.3f m', D, H));
legend('跳跃轨迹', '离地点', '落地点', 'Location', 'best');
grid on; axis equal;

subplot(1, 2, 2);
bar([h1, h2, h3, H], 'FaceColor', [0.4 0.7 1], 'EdgeColor', 'k');
set(gca, 'XTickLabel', {'h_1 伸腿', 'h_2 腾空', 'h_3 收腿', 'H 总计'});
ylabel('高度 (m)');
title('跳跃高度分解');
grid on;

%% ==================== 辅助函数 ====================

function str = checkMark(passed)
    if passed, str = '✓'; else, str = '⚠ 超限！'; end
end