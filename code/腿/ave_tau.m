%%求平均输出扭矩τ
%首先将前文得出的数据复制过来，即有关k_r_ky的求解

%%关节电机连线几何中心到地面的距离，此处请看图2.1.4
syms theta1 theta2 l1 l2 l3 k r real
m=15; %机器人质量（kg），即除去腿部和驱动轮后的质量
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
l1_mm=145; %mm
l2_mm=270; %mm
l3_mm=0; %mm
l1_val=l1_mm/1000; %m
l2_val=l2_mm/1000; %m
l3_val=l3_mm/1000; %m
k_val=0.5; % 系数，k<1
max_ang=80;
min_ang=0;
theta_max=deg2rad(max_ang);
theta_min=deg2rad(min_ang);

%%求解k_r_ky数值
k_r_ky=subs(r_ky_sol,[l1,l2,l3,k],[l1_val,l2_val,l3_val,k_val]);

%%化简后的雅可比矩阵
k_r_ky=diff(r_ky_sol,theta1); %雅可比矩阵的j22
tau=m*g/2*k_r_ky/1000/2; %求关节扭矩

a_ang=-30;
theta1_val=deg2rad(a_ang);

tau_val=subs(tau,[l1,l2],[l1_val,l2_val]);
t_ave=[];
while a_ang<=60
    theta1_val=deg2rad(a_ang);
    tau_num=double(subs(tau_val,theta1,theta1_val));
    t_ave(end+1)=abs(tau_num);
    a_ang=a_ang+2;
end
t_ave_mean=mean(t_ave);

%%计算行程中τ的极值和所在的角度
J=k_r_ky;
J_num=subs(J,[l1,l2,k],[l1_val,l2_val,k_val]);
interval=5;
a_ang=-20;
b_ang=60;
t=[];
while b_ang>15
    while a_ang<15
        theta2_val=deg2rad(180-a_ang);
        theta1_val=deg2rad(a_ang);
        J_final=double(subs(J_num,[theta1,theta2],[theta1_val,theta2_val]));
        F=[0;m*g/2];
        tau_final=J_final'*F;
        t(end+1)=abs(tau_final(1));
        t(end+1)=abs(tau_final(2));
        a_ang=a_ang+interval;
    end
    a_ang=-20;
    b_ang=b_ang-interval;
end
[max_t,index_max]=max(t);
result_max=findindex(index_max);
fprintf('扭矩最大值：%.3f,A关节角度：%.f,B关节角度：%.f\n',max_t,result_max(1),result_max(2));
[min_t,index_min]=min(t);
result_min=findindex(index_min);
fprintf('扭矩最小值：%.3f,A关节角度：%.f,B关节角度：%.f\n',min_t,result_min(1),result_min(2));
function result=findindex(index)
     if rem(index,2)==0
         index=index/2;
     end
     index_a=mod(index,8);%取余
     index_b=(index-index_a)/8;%取商
     aang=-20+5*(index_a-1);
     bang=80-5*index_b;
     result=[aang,bang];
end