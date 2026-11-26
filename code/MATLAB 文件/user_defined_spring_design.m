function spring_design_ID_5_to_10()
    % =========================================================
    % 内径限制在 5mm ~ 10mm 之间，形变量要求 >= 40mm
    % 强推短弹簧，手动指定 l1、l2，输出实际k与需求k的偏差
    % =========================================================
    clc; clear; close all;

    %% 1. 用户输入区 (每次修改这里重新运行)
    % =========================================================
    l1 = 72.76;    % 力臂1 (mm)
    l2 = 73;   % 力臂2 (mm)
    % =========================================================
    
    % 计算目标刚度 k
    k_target = (11.29 * 72.76) / (l1 * l2);
    fprintf('【用户指定参数】l1 = %d mm, l2 = %d mm\n', l1, l2);
    fprintf('【理论目标刚度】k_target = %.5f N/mm\n', k_target);
    
    %% 2. 参数搜索与筛选
    G = 79000;          % 弹簧钢剪切模量 (MPa)
    min_ID = 5;         % 最小内径约束 (mm)
    max_ID = 10;        % 最大内径约束 (mm)
    min_travel = 100;    % 最小形变量约束 (mm)
    
    % 搜索范围设定
    d_list = 0.4:0.05:2.0;      % 线径范围 (mm)
    D_list = 5:0.2:15;          % 中径范围 (mm)，涵盖内径5~10mm的各种组合
    
    % 初始化数据矩阵: [评分, d, D2, D, n, H0, Hb, k_calc, f_max, Deviation]
    valid_springs = []; 
    
    fprintf('正在搜索内径在 5~10mm 之间、形变 >= 40mm 的弹簧组合...\n');
    
    for d = d_list
        for D = D_list
            % 计算内径与外径
            D1 = D - d;
            D2 = D + d;
            
            % 核心约束：内径限制在 5mm 到 10mm 之间
            if D1 < min_ID || D1 > max_ID
                continue;
            end
            
            % 反推所需有效圈数 n
            n_float = (G * d^4) / (8 * D^3 * k_target);
            n = round(n_float);
            
            % 过滤不合理的圈数
            if n < 5 || n > 65
                continue;
            end
            
            % 计算实际刚度 k_calc
            k_calc = (G * d^4) / (8 * D^3 * n);
            err = abs(k_calc - k_target) / k_target;
            
            % 允许的刚度误差范围
            if err > 0.10
                continue;
            end
            
            % 计算压并高度 Hb
            Hb = (n + 2) * d;
            
            % 约束：最大压缩量 >= 100mm
            H0_min = Hb + min_travel;
            
            % 如果最短自由长度超过 190mm，淘汰，保证整体偏短
            if H0_min > 190
                continue;
            end
            
            % 自由长度搜索范围
            H0_max = min(190, H0_min + 20);
            H0_list = H0_min : 2 : H0_max;
            
            for H0 = H0_list
                f_max = H0 - Hb;      % 最大压缩量
                L_max = f_max;        % 最大伸长量
                
                if f_max < min_travel
                    continue;
                end
                
                % ---------- 评分机制 ----------
                % 1. 线径评分 (0.8~1.5mm 易采购且稳定)
                if d >= 0.8 && d <= 1.5
                    score_d = 1.0;
                elseif d < 0.8
                    score_d = d / 0.8;
                else
                    score_d = 1.0 - (d - 1.5) / 1.0;
                    if score_d < 0, score_d = 0; end
                end
                
                % 2. 刚度匹配评分
                score_k = 1.0 - err / 0.10;
                
                % 3. 长度评分（核心偏短逻辑）
                score_len = 1.0 - (H0 - H0_min) / 60;
                if score_len < 0.1, score_len = 0.1; end
                
                % 4. 行程效率评分
                score_travel = f_max / H0;
                
                % 综合评分
                total_score = 0.2*score_d + 0.35*score_k + 0.35*score_len + 0.1*score_travel;
                
                % 计算偏差百分比
                dev_percent = (k_calc - k_target) / k_target * 100;
                
                % 保存数据
                valid_springs = [valid_springs; total_score, d, D2, D, n, H0, Hb, k_calc, f_max, dev_percent];
            end
        end
    end
    
    %% 3. 结果排序与提取
    if isempty(valid_springs)
        fprintf('⚠️ 未能找到满足内径 5~10mm 且形变量 >= 40mm 的弹簧组合。\n');
        return;
    end
    
    [~, idx] = sort(valid_springs(:, 1), 'descend');
    valid_springs_sorted = valid_springs(idx, :);
    
    max_all = min(200, size(valid_springs_sorted, 1));
    All_Data_Final = valid_springs_sorted(1:max_all, :);
    
    top_n = min(20, size(valid_springs_sorted, 1));
    Top_20 = valid_springs_sorted(1:top_n, :);
    
    fprintf('✅ 搜索完成！共筛选出 %d 组符合要求的弹簧。\n', size(valid_springs, 1));
    
    %% 4. 导出到 Excel (包含两个 Sheet，覆盖写入)
    output_filename = 'Springs_ID_5_to_10.xlsx';
    if exist(output_filename, 'file')
        delete(output_filename);
    end
    
    VarNames = {'Rank', 'l1_mm', 'l2_mm', 'k_target', 'Score', 'D1_mm', 'd_mm', 'D2_mm', 'D_mm', ...
                'n', 'H0_mm', 'Hb_mm', 'k_calc', 'f_max_mm', 'L_max_mm', 'Deviation_percent'};
            
    % --- 生成 All_Valid_Data ---
    T_all = array2table(zeros(max_all, 16), 'VariableNames', VarNames);
    for i = 1:max_all
        r = All_Data_Final(i, :);
        T_all.Rank(i) = i;
        T_all.l1_mm(i) = l1;
        T_all.l2_mm(i) = l2;
        T_all.k_target(i) = k_target;
        T_all.Score(i) = r(1);
        T_all.D1_mm(i) = r(4) - r(2);
        T_all.d_mm(i) = r(2);
        T_all.D2_mm(i) = r(3);
        T_all.D_mm(i) = r(4);
        T_all.n(i) = r(5);
        T_all.H0_mm(i) = r(6);
        T_all.Hb_mm(i) = r(7);
        T_all.k_calc(i) = r(8);
        T_all.f_max_mm(i) = r(9);
        T_all.L_max_mm(i) = r(9);
        T_all.Deviation_percent(i) = r(10);
    end
    
    % --- 生成 Top_20_Best ---
    T_top = array2table(zeros(top_n, 16), 'VariableNames', VarNames);
    for i = 1:top_n
        r = Top_20(i, :);
        T_top.Rank(i) = i;
        T_top.l1_mm(i) = l1;
        T_top.l2_mm(i) = l2;
        T_top.k_target(i) = k_target;
        T_top.Score(i) = r(1);
        T_top.D1_mm(i) = r(4) - r(2); 
        T_top.d_mm(i) = r(2);
        T_top.D2_mm(i) = r(3);
        T_top.D_mm(i) = r(4);
        T_top.n(i) = r(5);
        T_top.H0_mm(i) = r(6);
        T_top.Hb_mm(i) = r(7);
        T_top.k_calc(i) = r(8);
        T_top.f_max_mm(i) = r(9);
        T_top.L_max_mm(i) = r(9);
        T_top.Deviation_percent(i) = r(10);
    end
    
    try
        writetable(T_all, output_filename, 'Sheet', 'All_Valid_Data');
        writetable(T_top, output_filename, 'Sheet', 'Top_20_Best');
        fprintf('✅ 数据已保存至当前目录下的 %s\n', output_filename);
        fprintf('表格包含 "All_Valid_Data" (%d组) 和 "Top_20_Best" (%d组)\n', max_all, top_n);
    catch ME
        fprintf('❌ 写入Excel失败，请检查文件是否被占用。错误信息: %s\n', ME.message);
    end
    
    %% 5. 命令行打印前 10 组预览
    fprintf('\n================ 前 10 组最佳参数 (内径 5~10mm, 形变>=40mm) ================\n');
    fprintf('%-4s %-8s %-8s %-6s %-6s %-6s %-5s %-6s %-7s %-9s %-8s\n', ...
        '排名', 'k_target', '偏差%', '内径D1', '线径d', '外径D2', '圈数n', '自由长H0', '压并Hb', '实际k', '最大形变');
    for i = 1:min(10, top_n)
        r = Top_20(i, :);
        fprintf('%-4d %-8.5f %-8.2f %-6.2f %-6.2f %-6.2f %-5d %-6d %-7.1f %-9.5f %-8.1f\n', ...
            i, k_target, r(10), r(4)-r(2), r(2), r(3), r(5), r(6), r(7), r(8), r(9));
    end
    
    %% 6. 绘制最佳组合的特性曲线
    if top_n > 0
        r = Top_20(1, :);
        sample_d = r(2); sample_D2 = r(3); sample_H0 = r(6);
        sample_k = r(8); sample_fmax = r(9);
        
        x_plot = linspace(0, sample_fmax, 100);
        F_plot = sample_k * x_plot;
        
        figure('Name', '最佳弹簧特性曲线');
        plot(x_plot, F_plot, 'b-', 'LineWidth', 2);
        grid on;
        xlabel('压缩量 x (mm)');
        ylabel('弹簧力 F (N)');
        title_str = sprintf('最佳弹簧 (内径%.1f, d=%.2f, D2=%.2f, H0=%d, 偏差=%.2f%%)', ...
            r(4)-r(2), sample_d, sample_D2, sample_H0, r(10));
        title(title_str);
        hold on;
        limit_F = sample_k * sample_fmax;
        plot(sample_fmax, limit_F, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        text(sample_fmax, limit_F, sprintf('  极限点 (%.1fmm, %.1fN)', sample_fmax, limit_F), ...
            'VerticalAlignment', 'bottom');
    end
end