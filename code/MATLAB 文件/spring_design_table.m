function optimize_spring_design_with_deviation()
    % =========================================================
    % 自动搜索最优 l1、l2，给出100~200组可行数据 + 20组最佳数据
    % 新增：列出理论k_target与实际k_calc，并计算偏差百分比
    % 核心特征：强推短弹簧，内径固定10mm，忽略稳定性与应力
    % =========================================================
    clc; clear; close all;

    %% 1. 搜索范围设定
    l1_range = 50:2:150;   % l1 搜索范围 (mm)，步长2mm
    l2_range = 50:2:150;   % l2 搜索范围 (mm)
    
    G = 79000;    % 弹簧钢剪切模量 (MPa)
    D1 = 10;      % 固定内径 (mm)
    
    d_list = 0.5:0.05:1.5;    % 线径范围 (mm)
    
    %% 2. 遍历所有 l1, l2 组合收集数据
    All_Data = []; % 格式: [l1, l2, k_target, 评分, d, D2, D, n, H0, Hb, k_calc, f_max]
    
    fprintf('正在搜索，请稍候...\n');
    for l1 = l1_range
        for l2 = l2_range
            k_target = (20 * 48.02) / (l1 * l2);
            
            % 获取该力臂组合下所有符合条件的弹簧
            springs = get_springs_for_k(k_target, G, D1, d_list);
            
            if ~isempty(springs)
                % 为每个弹簧添加 l1, l2, k_target 信息
                rows = size(springs, 1);
                extra_cols = repmat([l1, l2, k_target], rows, 1);
                combined = [extra_cols, springs];
                All_Data = [All_Data; combined];
            end
        end
    end
    
    if isempty(All_Data)
        fprintf('⚠️ 未找到任何满足条件的组合。请放宽搜索范围或检查参数。\n');
        return;
    end
    
    %% 3. 排序并提取最佳 20 组
    [~, idx] = sort(All_Data(:, 4), 'descend');
    All_Data_Sorted = All_Data(idx, :);
    
    top_n = min(20, size(All_Data_Sorted, 1));
    Top_20 = All_Data_Sorted(1:top_n, :);
    
    max_all = min(200, size(All_Data_Sorted, 1));
    All_Data_Final = All_Data_Sorted(1:max_all, :);
    
    %% 4. 显示到命令行
    fprintf('\n=============================================================\n');
    fprintf('✅ 搜索完成！共找到 %d 组可行组合。输出前 %d 组。\n', size(All_Data, 1), max_all);
    fprintf('=============================================================\n');
    
    fprintf('\n========== 前 20 组最佳参数（弹簧偏短，优先推荐） ==========\n');
    print_table(Top_20);
    
    %% 5. 导出到 Excel（含两个 Sheet 页，并计算偏差）
    output_filename = 'Optimal_Springs_Results.xlsx';
    if exist(output_filename, 'file')
        delete(output_filename);
    end
    
    % 新增 k_target 和 deviation_percent
    VarNames = {'Rank', 'l1_mm', 'l2_mm', 'k_target', 'Score', 'd_mm', 'D2_mm', 'D_mm', ...
                'n', 'H0_mm', 'Hb_mm', 'k_calc', 'f_max_mm', 'L_max_mm', 'Deviation_percent'};
            
    % --- 生成 All_Valid_Data ---
    T_all = array2table(zeros(size(All_Data_Final,1), 15), 'VariableNames', VarNames);
    for i = 1:size(All_Data_Final, 1)
        r = All_Data_Final(i, :);
        T_all.Rank(i) = i;
        T_all.l1_mm(i) = r(1);
        T_all.l2_mm(i) = r(2);
        T_all.k_target(i) = r(3);
        T_all.Score(i) = r(4);
        T_all.d_mm(i) = r(5);
        T_all.D2_mm(i) = r(6);
        T_all.D_mm(i) = r(7);
        T_all.n(i) = r(8);
        T_all.H0_mm(i) = r(9);
        T_all.Hb_mm(i) = r(10);
        T_all.k_calc(i) = r(11);
        T_all.f_max_mm(i) = r(12);
        T_all.L_max_mm(i) = r(12);
        T_all.Deviation_percent(i) = (r(11) - r(3)) / r(3) * 100;
    end
    
    % --- 生成 Top_20_Best ---
    T_top = array2table(zeros(size(Top_20,1), 15), 'VariableNames', VarNames);
    for i = 1:size(Top_20, 1)
        r = Top_20(i, :);
        T_top.Rank(i) = i;
        T_top.l1_mm(i) = r(1);
        T_top.l2_mm(i) = r(2);
        T_top.k_target(i) = r(3);
        T_top.Score(i) = r(4);
        T_top.d_mm(i) = r(5);
        T_top.D2_mm(i) = r(6);
        T_top.D_mm(i) = r(7);
        T_top.n(i) = r(8);
        T_top.H0_mm(i) = r(9);
        T_top.Hb_mm(i) = r(10);
        T_top.k_calc(i) = r(11);
        T_top.f_max_mm(i) = r(12);
        T_top.L_max_mm(i) = r(12);
        T_top.Deviation_percent(i) = (r(11) - r(3)) / r(3) * 100;
    end
    
    try
        writetable(T_all, output_filename, 'Sheet', 'All_Valid_Data');
        writetable(T_top, output_filename, 'Sheet', 'Top_20_Best');
        fprintf('\n✅ 数据已成功保存至当前目录下的 %s\n', output_filename);
        fprintf('包含两个Sheet: "All_Valid_Data" (%d组) 和 "Top_20_Best" (20组)\n', size(T_all,1));
        fprintf('Excel中已包含理论k值(k_target)、实际k值(k_calc)和偏差百分比(Deviation_percent)\n');
    catch ME
        fprintf('\n❌ 写入Excel失败: %s\n', ME.message);
    end
    
    %% 6. 绘制最佳组合的弹簧特性曲线
    if top_n > 0
        r = Top_20(1, :);
        sample_d = r(5); sample_D2 = r(6); sample_H0 = r(9);
        sample_k = r(11); sample_fmax = r(12);
        
        x_plot = linspace(0, sample_fmax, 100);
        F_plot = sample_k * x_plot;
        
        figure('Name', '最佳组合弹簧特性曲线');
        plot(x_plot, F_plot, 'b-', 'LineWidth', 2);
        grid on;
        xlabel('压缩量 x (mm)');
        ylabel('弹簧力 F (N)');
        title_str = sprintf('最佳弹簧 (l1=%d, l2=%d, d=%.2f, D2=%.2f, H0=%d, 偏差=%.2f%%)', ...
            r(1), r(2), sample_d, sample_D2, sample_H0, (sample_k-r(3))/r(3)*100);
        title(title_str);
        hold on;
        limit_F = sample_k * sample_fmax;
        plot(sample_fmax, limit_F, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        text(sample_fmax, limit_F, sprintf('  极限点 (%.1fmm, %.1fN)', sample_fmax, limit_F), ...
            'VerticalAlignment', 'bottom');
    end
end

%% 辅助函数：根据目标k值，返回所有满足条件的弹簧参数
function springs = get_springs_for_k(k_target, G, D1, d_list)
    springs = [];
    
    for d = d_list
        D = D1 + d;       % 中径
        D2 = D1 + 2*d;    % 外径
        
        % 反推所需圈数
        n_float = (G * d^4) / (8 * D^3 * k_target);
        n = round(n_float);
        
        if n < 3 || n > 50
            continue;
        end
        
        % 实际刚度
        k_calc = (G * d^4) / (8 * D^3 * n);
        err = abs(k_calc - k_target) / k_target;
        
        % 严格限制误差在 8% 以内
        if err > 0.08
            continue;
        end
        
        % 压并高度
        Hb = (n + 2) * d;
        
        % 核心约束：整体弹簧要偏短
        H0_min = Hb + 50;
        if H0_min > 100
            continue;
        end
        
        H0_max = min(105, H0_min + 20);
        H0_list = H0_min : 2 : H0_max;
        
        for H0 = H0_list
            f_max = H0 - Hb;
            
            if f_max < 50
                continue;
            end
            
            % ---------- 评分机制（强推短弹簧） ----------
            % 线径评分
            if d >= 0.7 && d <= 1.0
                score_d = 1.0;
            elseif d < 0.7
                score_d = d / 0.7;
            else
                score_d = 1.0 - (d - 1.0) / 0.2;
                if score_d < 0, score_d = 0; end
            end
            
            % 刚度匹配评分
            score_k = 1.0 - err / 0.08;
            
            % 长度评分（核心，越短越好）
            score_len = 1.0 - (H0 - H0_min) / 60;
            if score_len < 0.1, score_len = 0.1; end
            
            % 行程效率
            score_travel = f_max / H0;
            
            % 综合评分
            total_score = 0.2*score_d + 0.3*score_k + 0.4*score_len + 0.1*score_travel;
            
            % 保存到数组: [评分, d, D2, D, n, H0, Hb, k_calc, f_max]
            springs = [springs; total_score, d, D2, D, n, H0, Hb, k_calc, f_max];
        end
    end
end

%% 辅助函数：在命令行打印表格（包含理论k、实际k、偏差）
function print_table(data)
    fprintf('%-4s %-5s %-5s %-9s %-7s %-6s %-6s %-5s %-6s %-7s %-9s %-7s %-9s\n', ...
        '排名', 'l1', 'l2', 'k_target', '偏差%', '评分', 'd', 'D2', 'n', 'H0', 'Hb', 'k_calc', 'f_max');
    for i = 1:size(data, 1)
        r = data(i, :);
        dev = (r(11) - r(3)) / r(3) * 100;
        fprintf('%-4d %-5d %-5d %-9.4f %-7.2f %-6.3f %-6.2f %-6.2f %-5d %-6d %-7.1f %-9.4f %-7.1f\n', ...
            i, r(1), r(2), r(3), dev, r(4), r(5), r(6), r(8), r(9), r(10), r(11), r(12));
    end
end