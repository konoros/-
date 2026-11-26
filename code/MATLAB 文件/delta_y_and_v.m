clear;clc;
%%关节电机连线几何中心到地面的距离，此处请看图2.1.4
syms theta1 theta2 l1 l2 l3 k r real
m=6; %机器人质量（kg），即除去腿部和驱动轮后的质量
g=9.81; %重力加速度
r=67.5; %轮子半径mm
%关节H点坐标
syms hx hy real
hx=l1*cos(theta1);
hy=l1*sin(theta1);

% 关节K点坐标，也就是J点，用来求行程和行程速度（mm）
syms ky real
eq=(hx)^2+(ky-hy)^2==(l2)^2;
ky_sol=solve(eq,ky);
for i=1:length(ky_sol)
    current_sol=ky_sol(1);
    % 检查当前解是否为a+b
    if simplify(current_sol-l1*sin(theta1))==(l2+l1*cos(theta1))^0.5*(l2-l1*cos(theta1))^0.5
       r_ky_sol=current_sol*1000+r;%单位换算成mm并加上轮子半径既可得到h
       break; % 找到后退出循环
    end
end

%%设定实际物理参数
%连杆长度
l1_mm=140; %mm
l2_mm=210; %mm
l3_mm=0; %mm
l1_val=l1_mm/1000; %m
l2_val=l2_mm/1000; %m
l3_val=l3_mm/1000; %m
k_val=0.5; % 系数，k<1
max_ang=80;
min_ang=0;
theta_max=deg2rad(max_ang);
theta_min=deg2rad(min_ang);

%%求最高点，最低点，行程
r_ky_max_num=double(subs(r_ky_sol,[l1,l2,l3,k,theta1],[l1_val,l2_val,l3_val,k_val,theta_max]));
r_ky_min_num=double(subs(r_ky_sol,[l1,l2,l3,k,theta1],[l1_val,l2_val,l3_val,k_val,theta_min]));
delta_y=r_ky_max_num-r_ky_min_num;
fprintf('l1=%.4f,l2=%.4f,l3=%.4f时，最高点=%.2f,最低点=%.2f,行程=%.2f\n',l1_val,l2_val,l3_val,r_ky_max_num,r_ky_min_num,delta_y);
theta_range=min_ang:0.1:max_ang;
theta_range_val=deg2rad(theta_range);
k_r_ky=subs(r_ky_sol,[l1,l2,l3,k],[l1_val,l2_val,l3_val,k_val]);
k_r_ky_num=matlabFunction(k_r_ky);% 将符号表达式转换成数值函数
f_vals=k_r_ky_num(theta_range_val);% 计算f（x）的值
%线性拟合
p=polyfit(theta_range,f_vals,1);
slope=p(1);
intercept=p(2);
fit_line=polyval(p,theta_range);
fprintf('形变的平均速率为%f\n',slope);

%%可视化结果
figure;
%绘制原始数据
plot(theta_range,f_vals,'b-','LineWidth',1.5);
hold on;
plot(theta_range,fit_line,'r-','LineWidth',1.5);
xlabel('关节角度\theta（°）');
ylabel('行程(mm)');
title('行程h vs 关节角度');
legend('实际行程','线性拟合','Location','best');
grid on;
axis tight;
% 添加拟合方程文本
eqn_text=sprintf('拟合直线：y=%.4f x+%.4f',slope,intercept);
text(mean(theta_range),mean(f_vals)-20,eqn_text,'FontSize',10,'BackgroundColor','white');