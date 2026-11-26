%%偏置并联腿的扭矩计算
%先求解末端执行器点C的坐标
%基于坐标系和几何关系
syms l1 l2 l3 real %均为连杆长度，设为已知
syms k %为连杆之间的比例系数
syms theta1 theta2 resl %均为关节电机的关节角度，设为已知
syms Cx Cy real %末端C点坐标，为未知量
Dx=k*l1*cos(theta1);
Dy=k*l1*sin(theta1);
Ex=k*l1*cos(theta2);
Ey=k*l1*sin(theta2);
Hx=l1*cos(theta2);
Hy=l1*sin(theta2);

%通过画圆法列出C点方程
eq1=(Cx-Dx)^2+(Cy-Dy)^2==(k*l2)^2;
eq2=(Cx-Ex)^2+(Cy-Ey)^2==(k*l2)^2;
sol=solve([eq1,eq2],[Cx,Cy]);
%% 选择物理可行的解
Cx_sol=real(sol.Cx(1));
Cy_sol=real(sol.Cy(1));

%%通过偏置并联模型我们可以得知CE和HJ存在比例关系，从而可以推导出末端执行器点J的坐标
%点J的坐标
syms jx jy real;
jx=Hx+1/k*(Cx_sol-Ex);
jy=Hy+1/k*(Cy_sol-Ey);

%%将theta1和theta2分别对jx和jy求偏导，得到雅可比矩阵

% jx对theta1和theta2的偏导
J11=diff(jx,theta1);
J12=diff(jx,theta2);

%jy对theta1和theta2的偏导
J21=diff(jy,theta2);
J22=diff(jy,theta1);

J=[J11 J12;J21 J22];

%%设置实际物理参数
m=15; %机器人质量（kg），即除去腿部和驱动轮后的质量
g=9.81; %重力加速度
%连杆长度
l1_val=0.145; %m
l2_val=0.27; %m
k_val=0.5; % 系数 k<1
%关节角度
a_ang=-20; %度deg
b_ang=80; %度deg
theta1_val=deg2rad(180-a_ang) ;
theta2_val=deg2rad(b_ang);

%代入计算C点坐标
Cy_num=subs(sol.Cy(1),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);
Cx_num=subs(sol.Cx(1),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);
Cy_num=vpa(Cy_num);
Cx_num=vpa(Cx_num);
if Cy_num_1>Cy_num_2 && Cy_num_1>0
    fprintf('%.2f,%.2f',Cx_num_1,Cx_num_2);
    fprintf('C点坐标的x为%.2f\n',Cx_num_1);
    fprintf('%.2f,%.2f',Cy_num_1,Cy_num_2);
    fprintf('C点坐标的x为%.5f\n',Cy_num_1);
else
    fprintf('C点选点异常，请查看值\n');
end

%% 代入计算J点坐标
x_num=double(subs(jx,[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]));
y_num=double(subs(jy,[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]));
fprintf('J点的坐标为（%.2f,%.5f）\n',x_num,y_num)

%%雅可比矩阵计算
J_num=subs(J,[l1,l2,k],[l1_val,l2_val,k_val]);
J_final=double(subs(J_num,[theta1,theta2],[theta1_val,theta2_val]));

%%关节电机负载计算
F=[0;m*g/2]; %由受力分析可得，地面反作用力单位为N
tau_final=J_final'*F; %关节扭矩单位为N/m
%将扭矩转换为N*mm（1N*m=1000N*mm）
tau_final_mm=tau_final*1000;
fprintf('A点的关节角度为%.f度，B点关节角度为%.f度\n',a_ang,b_ang);
disp('===并联五连杆雅可比矩阵===');
disp('J=');
disp(J_final);
disp('===并联五连杆关节扭矩===');
fprintf('τ1=%.2f N*m (%.2f N*mm)\n',tau_final(1),tau_final_mm(1));
fprintf('τ2=%.2f N*m (%.2f N*mm)\n\n',tau_final(2),tau_final_mm(2));
