clear; clc;
close all;

%% 1. 并行池初始化
if isempty(gcp('nocreate'))
    parpool('local', 4);
end

%% 2. 参数定义
m = 6;
g = 9.81;
r = 67.5;            % 轮子半径 mm
max_ang = 60;
min_ang = -20;
theta_max = deg2rad(max_ang);
theta_min = deg2rad(min_ang);
k = 0.5;
interval = 5;

sym_l1_range = 100:interval:250;   % mm
sym_l2_range = 150:interval:300;   % mm
[sym_l1, sym_l2] = meshgrid(sym_l1_range, sym_l2_range);

fprintf('=== 阶段 1/2：计算高度与速度参数 ===\n');
result1_shang = find1(sym_l1, sym_l2, theta_max, theta_min, min_ang, max_ang, m, g, r);

fprintf('\n=== 阶段 2/2：计算扭矩参数 ===\n');
result2 = find2(sym_l1, sym_l2, k, m, g);

%% 3. 整合并保存结果
data = [sym_l1(:), sym_l2(:), result1_shang, result2];

headers = {'l1(mm)','l2(mm)','y_max(mm)','y_min(mm)','delta_y',...
           'v_avg','t_avg','max_t','max_aang','max_bang','min_t','min_aang','min_bang'};
data_table = array2table(data, 'VariableNames', headers);

writetable(data_table, 'datac12_shang.xlsx');

% 筛选满足条件的参数组合
valid_idx = (data(:,3)<540) & (data(:,4)<540) & ...
            (data(:,5)>200) & (data(:,7)<16) & (data(:,8)<16);
result_valid = data_table(valid_idx, :);
writetable(result_valid, 'reslut1.xlsx');

fprintf('\n✅ 计算完成！有效参数组合：%d 组\n', sum(valid_idx));
fprintf('结果已保存至 datac12.xlsx 和 reslut1_shang.xlsx\n');

%% 关闭并行池
delete(gcp('nocreate'));

%% ==================== 子函数 ====================

function result1 = find1(l1_num, l2_num, theta_max, theta_min, min_ang, max_ang, m, g, r)
    % 在函数内部完成符号计算，避免 parfor worker 文件锁
    syms theta2 l1 l2 real
    hx = l1*cos(theta2);
    hy = l1*sin(theta2);
    syms ky real
    eq = (hx)^2 + (ky-hy)^2 == (l2)^2;
    ky_sol = solve(eq, ky);
    
    r_ky_sol = 0;
    for i = 1:length(ky_sol)
        current_sol = ky_sol(i);
        if simplify(current_sol - l1*sin(theta2)) == (l2+l1*cos(theta2))^0.5 * (l2-l1*cos(theta2))^0.5
            r_ky_sol = current_sol*1000 + r;
            break;
        end
    end
    
    k_r_ky_diff = diff(r_ky_sol, theta2);
    
    % 【关键修复】：不使用 matlabFunction 导出文件，直接用匿名函数 + double
    % 将符号表达式转成可在 parfor 中使用的函数句柄
    f_rky = matlabFunction(r_ky_sol, 'Vars', {l1, l2, theta2});
    f_tau = matlabFunction(m*g/2 * k_r_ky_diff / 1000 / 2, 'Vars', {l1, l2, theta2});
    
    n = numel(l1_num);
    result1 = zeros(n, 5);
    
    % 预先生成角度数组（避免 parfor 内重复计算）
    theta_range_val = deg2rad(min_ang:0.1:max_ang);
    theta_range_deg = min_ang:0.1:max_ang;
    theta2_vals = deg2rad(min_ang:2:max_ang);
    
    parfor i = 1:n
        l1_val = l1_num(i)/1000;
        l2_val = l2_num(i)/1000;
        
        % 高度参数
        r_ky_max = double(f_rky(l1_val, l2_val, theta_max));
        r_ky_min = double(f_rky(l1_val, l2_val, theta_min));
        delta_y = r_ky_max - r_ky_min;
        
        % 速度参数
        f_vals = zeros(size(theta_range_val));
        for ti = 1:length(theta_range_val)
            f_vals(ti) = double(f_rky(l1_val, l2_val, theta_range_val(ti)));
        end
        p = polyfit(theta_range_deg, f_vals, 1);
        v_avg = p(1);
        
        % 平均扭矩
        tau_vals = zeros(size(theta2_vals));
        for ti = 1:length(theta2_vals)
            tau_vals(ti) = abs(double(f_tau(l1_val, l2_val, theta2_vals(ti))));
        end
        t_avg = mean(tau_vals);
        
        result1(i,:) = [r_ky_max, r_ky_min, delta_y, v_avg, t_avg];
        
        if mod(i, 50) == 0 || i == n
            fprintf('  高度参数: %d/%d (%.1f%%)\n', i, n, i/n*100);
        end
    end
end

function result2 = find2(l1_num, l2_num, k_num, m, g)
    syms theta1 theta2 l1 l2 real
    k = sym('k', 'real');
    
    Dx = k*l1*cos(theta1);
    Dy = k*l1*sin(theta2);
    Ex = k*l1*cos(theta2);
    Ey = k*l2*sin(theta2);
    
    syms Cx Cy real
    eq1 = (Cx-Dx)^2 + (Cy-Dy)^2 == (k*l2)^2;
    eq2 = (Cx-Ex)^2 + (Cy-Ey)^2 == (k*l2)^2;
    sol = solve([eq1, eq2], [Cx, Cy]);
    Cx_sol = real(sol.Cx(1));
    Cy_sol = real(sol.Cy(1));
    
    Hx = l1*cos(theta2);
    Hy = l1*sin(theta2);
    
    jx = Hx + 1/k*(Cx_sol - Ex);
    jy = Hy + 1/k*(Cy_sol - Ey);
    
    J = [diff(jx,theta1), diff(jx,theta2); diff(jy,theta1), diff(jy,theta2)];
    f_J = matlabFunction(J, 'Vars', {theta1, theta2, l1, l2, k});
    
    n = numel(l1_num);
    result2 = zeros(n, 6);
    
    % 【关键修复】：将角度搜索范围固定为离散网格，避免 while 循环导致 parfor 不确定性
    a_vals = 60:-5:45;   % a_ang 从 60 递减到 45（共4轮）
    b_vals = -20:5:60;   % b_ang 从 -20 递增到 60（共17个值）
    
    % 预先计算总组合数
    num_comb = length(a_vals) * length(b_vals);
    
    parfor j = 1:n
        l1_val = l1_num(j)/1000;
        l2_val = l2_num(j)/1000;
        k_val = k_num;
        
        torque_records = zeros(num_comb * 2, 3);  % 预分配内存：[扭矩, aang, bang]
        idx = 1;
        
        for a_idx = 1:length(a_vals)
            a_ang = a_vals(a_idx);
            for b_idx = 1:length(b_vals)
                b_ang = b_vals(b_idx);
                
                % 只在 b_ang <= a_ang 时计算（对应原作者 while a_ang > mid_ang 的物理含义）
                if b_ang <= a_ang
                    theta1_val = deg2rad(180 - a_ang);
                    theta2_val = deg2rad(b_ang);
                    
                    J_num = double(f_J(theta1_val, theta2_val, l1_val, l2_val, k_val));
                    F = [0, m*g/2];
                    tau_final = J_num * F';
                    
                    torque_records(idx, :) = [abs(tau_final(1)), a_ang, b_ang];
                    idx = idx + 1;
                    torque_records(idx, :) = [abs(tau_final(2)), a_ang, b_ang];
                    idx = idx + 1;
                end
            end
        end
        
        % 去除未填充的零行
        torque_records = torque_records(1:idx-1, :);
        
        % 寻找最大值和最小值
        [current_max, idx_max] = max(torque_records(:,1));
        [current_min, idx_min] = min(torque_records(:,1));
        
        max_aang = torque_records(idx_max, 2);
        max_bang = torque_records(idx_max, 3);
        min_aang = torque_records(idx_min, 2);
        min_bang = torque_records(idx_min, 3);
        
        result2(j,:) = [current_max, max_aang, max_bang, current_min, min_aang, min_bang];
        
        if mod(j, 50) == 0 || j == n
            fprintf('  扭矩参数: %d/%d (%.1f%%)\n', j, n, j/n*100);
        end
    end
end