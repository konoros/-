function parallel_five_bar_leg_optimization()
    clear;clc
    %% 第一步：建立机器人运动学模型（符号推导）
    fprintf('正在建立运动学模型...\n');
    syms l1 l2 theta1 theta2 real

    %% 1.1 基本几何关系
    % 关节 A（原点）驱动 D 点
    dy = l1 * cos(theta1);
    dx = l1 * sin(theta1);

    % 关节 B（原点）驱动 E 点
    ey = l1 * cos(theta2);
    ex = l1 * sin(theta2);

    %% 1.2 求解 C 点坐标（并联五连杆闭合方程）
    syms cx cy real
    eq1 = (cx - dx)^2 + (cy - dy)^2 == l2^2;
    eq2 = (cx - ex)^2 + (cy - ey)^2 == l2^2;
    sol = solve([eq1, eq2], [cx, cy]);

    % 选择物理合理的解
    cx_sol = real(sol.cx(1));
    cy_sol = real(sol.cy(1));

    %% 1.3 坐标变换（将坐标系旋转 180 度，使轮子朝下）
    theta = pi; % 180 度旋转
    rot_matrix = [cos(theta), -sin(theta), 0;
                  sin(theta), cos(theta), 0;
                  0, 0, 1];

    % 定义齐次坐标
    c_point = [cx_sol; cy_sol; 1];
    a_point = [0; 0; 1];

    % 应用旋转
    c_rot = rot_matrix * c_point;
    a_rot = rot_matrix * a_point;

    % 提取旋转后的坐标
    cx_rot = c_rot(1);
    cy_rot = c_rot(2);
    ax_rot = a_rot(1);
    ay_rot = a_rot(2);

    %% 第二步：跳跃高度计算模型
    fprintf('推导跳跃高度函数...\n');
    syms phi1 phi2 phi3 t b c m_l1 m_l2 m_body m_wheel g real

    % 2.1 定义三个关键状态的角度
    % phi1: 缩腿状态（最低点）
    % phi2: 离地瞬间
    % phi3: 最高点

    % 2.2 计算各状态下的机体高度
    ay_phi1 = subs(ay_rot, [theta1, theta2], [phi1, -phi1]);
    ay_phi2 = subs(ay_rot, [theta1, theta2], [phi2, -phi2]);
    ay_phi3 = subs(ay_rot, [theta1, theta2], [phi3, -phi3]);

    % 2.3 计算各阶段高度变化
    h1 = ay_phi2 - ay_phi1; % 地面阶段高度变化
    h3 = ay_phi2 - ay_phi3; % 空中阶段高度变化

    % 2.4 能量法计算腾空高度 h2
    % 这里简化计算，实际需要完整动力学推导
    h2 = (2*t*(phi2-phi1) - (m_body+2*m_l1+2*m_l2)*g*h1) / (m_body + 2*m_l1 + 2*m_l2+m_wheel) / g;

    % 总跳跃高度
    H = h2 + h3;

    % 2.5 约束条件计算
    w1 = 2*(phi2 - phi1)/0.1; % 简化的角速度计算（实际需要微分）
    w2 = 2*(phi3 - phi2)/0.1;
    F = 2*t/1; % 简化的作用力计算

    %% 第三步：转换为数值计算函数
    fprintf('生成数值计算函数...\n');

    % 固定参数赋值
    m_l1_val = 0.6; % 大腿质量 (kg)
    m_l2_val = 0.4; % 小腿质量 (kg)
    m_body_val = 5.5; % 机体质量 (kg)
    m_wheel_val = 0.65; % 轮子质量 (kg)
    g_val = 9.81; % 重力加速度 (m/s^2)
    b_val = 0.5; % 质心位置参数
    c_val = 0.85;

    % 生成函数句柄
    H_func = matlabFunction(subs(H, [m_l1, m_l2, m_body, m_wheel, g, b, c], ...
        [m_l1_val, m_l2_val, m_body_val, m_wheel_val, g_val, b_val, c_val]), ...
        'Vars', {l1, l2, phi1, phi2, phi3, t});

    w1_func = matlabFunction(subs(w1, [m_l1, m_l2, m_body, m_wheel, g, b, c], ...
        [m_l1_val, m_l2_val, m_body_val, m_wheel_val, g_val, b_val, c_val]), ...
        'Vars', {l1, l2, phi1, phi2, t});

    w2_func = matlabFunction(subs(w2, [m_l1, m_l2, m_body, m_wheel, g, b, c], ...
        [m_l1_val, m_l2_val, m_body_val, m_wheel_val, g_val, b_val, c_val]), ...
        'Vars', {l1, l2, phi1, phi2, phi3, t});

    F_func = matlabFunction(subs(F, [m_l1, m_l2, m_body, m_wheel, g, b, c], ...
        [m_l1_val, m_l2_val, m_body_val, m_wheel_val, g_val, b_val, c_val]), ...
        'Vars', {l1, l2, phi1, phi2, t});

    %% 第四步：改进的粒子群优化
    fprintf('开始优化计算...\n');

    % 4.1 优化参数设置
    n_particles = 50; % 粒子数量
    max_iter = 100; % 最大迭代次数
    dim = 6; % 优化变量维度 [l1, l2, phi1, phi2, phi3, t]

    % 变量范围约束
    lb = [0.1, 0.22, 60, 90, 60, 10]; % 下限
    ub = [0.22, 0.32, 90, 150, 150, 15]; % 上限

    % 约束阈值
    w1_max = 80; % 角速度约束 1 (rad/s)
    w2_max = 80; % 角速度约束 2 (rad/s)
    F_max = 100; % 作用力约束 (N)

    % 4.2 初始化粒子群
    particles = rand(n_particles, dim) .* (ub - lb) + lb;
    velocities = zeros(n_particles, dim);

    % 初始化最优解 (添加了 personal_best 初始化)
    personal_best = particles;
    personal_best_fitness = -inf(n_particles, 1);
    global_best = particles(1, :);
    global_best_fitness = -inf;
    fitness_history = zeros(max_iter, 1);

    % 4.3 主优化循环
    for iter = 1:max_iter
        % 动态调整参数
        w = 0.9 - 0.5*(iter/max_iter); % 惯性权重递减
        c1 = 2.5 * exp(-iter/max_iter); % 个体学习因子
        c2 = 1.5 + 1.5*(iter/max_iter); % 社会学习因子

        % 评估所有粒子
        for i = 1:n_particles
            % 当前粒子参数
            p = particles(i, :);

            % 计算适应度
            [fitness, h] = evaluate_particle(p, H_func, w1_func, w2_func, F_func, w1_max, w2_max, F_max);

            % 更新个体最优
            if fitness > personal_best_fitness(i)
                personal_best_fitness(i) = fitness;
                personal_best(i, :) = p;
            end

            % 更新全局最优
            if fitness > global_best_fitness
                global_best_fitness = fitness;
                global_best = p;
                fprintf('迭代 %d: 新最优高度 %.4f m (l1=%.3f, l2=%.3f)\n', ...
                    iter, h, p(1), p(2));
            end
        end

        % 更新粒子速度和位置
        for i = 1:n_particles
            r1 = rand(1, dim);
            r2 = rand(1, dim);

            % 速度更新方程
            velocities(i, :) = w * velocities(i, :) + ...
                c1 * r1 .* (personal_best(i, :) - particles(i, :)) + ...
                c2 * r2 .* (global_best - particles(i, :));

            % 位置更新
            particles(i, :) = particles(i, :) + velocities(i, :);

            % 边界约束处理
            particles(i,:) = max(particles(i,:), lb);
            particles(i,:) = min(particles(i,:), ub);
        end
        % 记录历史最佳适应度
        fitness_history(iter) = global_best_fitness;
        % 混沌扰动（每隔 10 次迭代）
        if mod(iter, 10) == 0
            particles = chaotic_disturbance(particles, lb, ub, 0.2);
        end
    end
    %% 第五步：结果显示
    fprintf('\n===== 优化结果 =====\n');
    fprintf('最优跳跃高度: %.4f m\n', global_best_fitness);
    fprintf('最优参数组合:\n');
    fprintf('大腿长度 l1 = %.4f m\n', global_best(1));
    fprintf('小腿长度 l2 = %.4f m\n', global_best(2));
    fprintf('缩腿角度 phi1 = %.2f°\n', global_best(3));
    fprintf('离地角度 phi2 = %.2f°\n', global_best(4));
    fprintf('最高点角度 phi3 = %.2f°\n', global_best(5));
    fprintf('关节扭矩 t = %.2f Nm\n', global_best(6));
    % 绘制收敛曲线
    figure;
    plot(1:max_iter, fitness_history, 'b-', 'LineWidth', 2);
    xlabel('迭代次数');
    ylabel('跳跃高度 (m)');
    title('PSO 优化收敛曲线');
    grid on;
end

%% 辅助函数：粒子评估
function [fitness, h] = evaluate_particle(p, H_func, w1_func, w2_func, F_func, w1_max, w2_max, F_max)
    % 参数转换
    l1 = p(1); l2 = p(2);
    phi1 = deg2rad(p(3)); phi2 = deg2rad(p(4));
    phi3 = deg2rad(p(5)); t = p(6);
    % 计算目标函数值
    h = H_func(l1, l2, phi1, phi2, phi3, t);
    % 计算约束条件
    w1 = w1_func(l1, l2, phi1, phi2, t);
    w2 = w2_func(l1, l2, phi1, phi2, t);
    F = F_func(l1, l2, phi1, phi2, t);
    % 约束惩罚项
    penalty = 0;
    if w1 > w1_max
        penalty = penalty + 100*(w1/w1_max)^3;
    end
    if w2 > w2_max
        penalty = penalty + 100*(w2/w2_max)^3;
    end
    if F > F_max
        penalty = penalty + 100*(F/F_max)^3;
    end
    % 适应度计算（带惩罚项）
    fitness = h / (1 + sqrt(penalty));
    % 确保输出合理
    if ~isreal(fitness) || isnan(fitness)
        fitness = -inf;
        h = 0;
    end
end

%% 辅助函数：混沌扰动
function particles = chaotic_disturbance(particles, lb, ub, strength)
    % 混沌映射（Logistic 映射）
    chaos = 0.7; % 初始混沌值
    a = 3.9;     % 混沌参数

    for i = 1:size(particles,1)
        % 生成混沌序列
        chaos = a * chaos * (1 - chaos);

        % 应用扰动
        perturbation = strength * (ub - lb) .* (chaos - 0.5);
        particles(i,:) = particles(i,:) + perturbation;

        % 确保仍在边界内
        particles(i,:) = max(min(particles(i,:), ub), lb);
    end
end