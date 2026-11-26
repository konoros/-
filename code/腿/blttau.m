%% 并联五连杆模型求末端执行器点C的坐标
% 先列出名词定义
syms l1 l2 l3 real %均为连杆长度，设为已知
syms theta1 theta2 real %均为关节电机的关节角度，设为已知
syms Cx Cy real %末端C点坐标，为未知量
Dx=l1*cos(theta1)+l3/2;
Dy=l1*sin(theta1);
Ex=l1*cos(theta2)-l3/2;
Ey=l1*sin(theta2);
%通过画圆法得出有关C点坐标方程组
eq1=(Cx-Dx)^2+(Cy-Dy)^2==l2^2;
eq2=(Cx-Ex)^2+(Cy-Ey)^2==l2^2;
sol=solve([eq1,eq2], [Cx,Cy]);
%% 选择物理可行的解
Cx_sol=real(sol.Cx(1));
Cy_sol=real(sol.Cy(1));

% 五连杆模型求雅可比矩阵
%% 对theta1和theta2求偏导，得到雅可比矩阵

% Cx对theta1和theta2的偏导
j11=diff(Cx_sol,theta1);
j12=diff(Cx_sol,theta2);

%Cy对theta1和theta2的偏导
j21=diff(Cy_sol,theta2);
j22=diff(Cy_sol,theta1);

j=[j11 j12;j21 j22];

%%设置实际物理参数
m=6; %机器人质量（kg），即除去腿部和驱动轮后的质量
g=9.81; %重力加速度
%连杆长度
l1_val=0.14; %m
l2_val=0.21; %m
l3_val=0; %m
%关节角度
a_ang=50; %度
b_ang=50; %度
theta1_val=deg2rad(180-a_ang) ;
theta2_val=deg2rad(b_ang);

%代入计算C点坐标
Cy_num_1=subs(sol.Cy(1),[l1,l2,l3,theta1,theta2],[l1_val,l2_val,l3_val,theta1_val,theta2_val]);
Cy_num_2=subs(sol.Cy(2),[l1,l2,l3,theta1,theta2],[l1_val,l2_val,l3_val,theta1_val,theta2_val]);
Cx_num_1=subs(sol.Cx(1),[l1,l2,l3,theta1,theta2],[l1_val,l2_val,l3_val,theta1_val,theta2_val]);
Cx_num_2=subs(sol.Cx(2),[l1,l2,l3,theta1,theta2],[l1_val,l2_val,l3_val,theta1_val,theta2_val]);
if Cy_num_1>Cy_num_2 && Cy_num_1>0
    fprintf('%.2f,%.2f',Cx_num_1,Cx_num_2);
    fprintf('C点坐标的x为%.2f\n',Cx_num_1);
    fprintf('%.2f,%.2f',Cy_num_1,Cy_num_2);
    fprintf('C点坐标的y为%.5f\n',Cy_num_1);
else
    fprintf('C点选点异常，请查看值\n');
end

%%雅可比矩阵的计算
j_num=subs(j,[l1,l2,l3],[l1_val,l2_val,l3_val]);
j_final=double(subs(j_num,[theta1,theta2],[theta1_val,theta2_val]));
%Dx_num=subs(Dx,[l1,theta1],[l1_val.theta_val]);

%%关节负载计算
F=[0;m*g/2]; %由受力分析可得，地面反作用力单位为N
tau_final=j_final'*F; %关节扭矩单位为N/m
%将扭矩转换为N*mm（1N*m=1000N*mm）
tau_final_mm=tau_final*1000;
fprintf('A点的关节角度为%.f度，B点关节角度为%.f度\n',a_ang,b_ang);
disp('===并联五连杆雅可比矩阵===');
disp('j=');
disp(j_final);
disp('===并联五连杆关节扭矩===');
fprintf('τ1=%.2f N*m (%.2f N*mm)\n',tau_final(1),tau_final_mm(1));
fprintf('τ2=%.2f N*m (%.2f N*mm)\n\n',tau_final(2),tau_final_mm(2));
