%%计算偏置并联构型k值的影响
%前面部分均为前文所展示的计算各点坐标的过程
syms l1 l2 k real %连杆参数
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

%%设置实际物理参数
m=15; %机器人质量（kg），即除去腿部和驱动轮后的质量
g=9.81; %重力加速度
%连杆长度
l1_val=0.21; %m
l2_val=0.25; %m
k_val=0.8; % 系数 k<1
%关节角度
a_ang=20; %度deg
b_ang=30; %度deg
theta1_val=deg2rad(180-a_ang) ;
theta2_val=deg2rad(b_ang);

%代入计算C点坐标
Cy_num_1=subs(sol.Cy(1),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);
Cy_num_2=subs(sol.Cy(2),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);
Cx_num_1=subs(sol.Cx(1),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);
Cx_num_2=subs(sol.Cx(2),[l1,l2,k,theta1,theta2],[l1_val,l2_val,k_val,theta1_val,theta2_val]);

if Cy_num_1>Cy_num_2 && Cy_num_1>0
    Cy_num=vpa(Cy_num_1);
    Cx_num=vpa(Cx_num_1);
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

%%根据受力分析列出方程
Fn=m*g;
CE=((Dx-Ex)*(Cy-Ey)-(Dy-Ey)*(Cx-Ex))/((Dx-Ex)^2+(Dy-Ey)^2)^0.5;
F2=Fn*(jx-Hx)/CE;

%%代入计算F2大小
F2_num=double(subs(F2,[m,g,Cx,Cy,l1,l2,k,theta1,theta2],[m,g,Cx_num,Cy_num,l1_val,l2_val,k_val,theta1_val,theta2_val]));
fprintf('A点的关节角度为%.f度，B点关节角度为%.f度\n',a_ang,b_ang);
fprintf('k的值为%.1f\n',k_val)
fprintf('F2的大小为%.2f N',F2_num);