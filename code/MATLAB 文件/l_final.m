clear;clc
if isempty(gcp('nocreate'))
    parpool('local',4);%使用4个核心，根据实际CPU调整
end
syms theta1 theta2 sym_l1 sym_l2 l3 k real
m=6; %机器人质量（kg），即除去腿部和驱动轮后的质量
g=9.81; %重力加速度
r=67.5; %轮子半径mm
max_ang=60;%最大关节角（°）
min_ang=-20;%最小关节角（°）
theta_max=deg2rad(max_ang);
theta_min=deg2rad(min_ang);
k=0.5;
interval=5;
sym_l1=100:interval:250; %(mm)
sym_l2=150:interval:300; %(mm)
[sym_l1,sym_l2]=meshgrid(sym_l1,sym_l2);
result1=find1(sym_l1,sym_l2,theta_max,theta_min,m,g,r);
result2=find2(sym_l1,sym_l2,k,m,g);
data=[sym_l1,sym_l2,result1,result2];
%  1  |  2  |  3  |  4  |  5  |  6  |  8  |  9  |  10  |  11  |  12  |  13  |
%'l1(mm)'|'l2(mm)'|'y_max(mm)'|y_min(mm)|'delta_y'|'v_avg'|'t_avg'|'max_t'|'max_aang'|'max_bang'|'min_t'|'min_aang'|'min_bang'|
xlswrite('datac1.xlsx',data);
%写入表头
%data_table=array2table(data,'VariableNames',headers);
headers={'l1(mm)','l2(mm)','y_max(mm)','y_min(mm)','delta_y','v_avg','t_avg','max_t','max_aang','max_bang','min_t','min_aang','min_bang'};
data_table=array2table(data,'VariableNames',headers);
writetable(data_table, 'datac12.xlsx');
%满足y_min<240,y_max<540，delta_y>200,t_avg<16,t_max<16
resultb=data((data(:,3)<540 & data(:,4)<540) & data(:,5)>200 & data(:,7)<16 & data(:,8)<16);
writetable(data_table,'reslut1.xlsx');

function result1=find1(l1_num,l2_num,theta_max,theta_min,m,g,r)

   syms theta2 l1 l2 real
   hx=l1*cos(theta2);
   hy=l1*sin(theta2);
   % 关节k点坐标，就是J点，用来求行程和行程速度（mm）
   syms ky real
   eq=(hx)^2+(ky-hy)^2==(l2)^2;
   ky_sol=solve(eq,ky);
   for i=1:length(ky_sol)
       current_sol=ky_sol(i);
       % 检查当前解是否为a+b
       if simplify(current_sol-l1*sin(theta2))==(l2+l1*cos(theta2))^0.5*(l2-l1*cos(theta2))^0.5
            r_ky_sol=current_sol*1000+r;%单位换算成mm并加上轮子半径既可得到h
            break; % 找到后退出循环
       end
   end
   r_ky_func=matlabFunction(r_ky_sol,'Vars',{l1,l2,theta2});
   % 预计算导数
   k_r_ky_diff=diff(r_ky_sol,theta2);
   tau_func=matlabFunction(m*g/2*k_r_ky_diff/1000/2,'Vars',{l1,l2,theta2});
   n=length(l1_num);
   result1=zeros(n,5);
   parfor i=1:n
       l1_val=l1_num(i)/1000; %转换为米
       l2_val=l2_num(i)/1000; %转换为米

       %最高点
       r_ky_max=r_ky_func(l1_val,l2_val,theta_max);
       %最低点
       r_ky_min=r_ky_func(l1_val,l2_val,theta_min);
       %行程
       delta_y=r_ky_max-r_ky_min;

       %平均形变速度
       max_ang=60; %最大关节角（°）
       min_ang=-20; %最小关节角（°）
       theta_range=min_ang:0.1:max_ang;
       theta_range_val=deg2rad(theta_range);
       f_vals=arrayfun(@(t)r_ky_func(l1_val,l2_val,t),theta_range_val);
       p=polyfit(theta_range,f_vals,1);
       v_avg=p(1);

       % 计算平均扭矩
       theta2_vals=deg2rad(min_ang:2:max_ang);
       tau_vals=arrayfun(@(t) abs(tau_func(l1_val,l2_val,t)),theta2_vals);
       t_avg=mean(tau_vals);
       result1(i,:)=[r_ky_max,r_ky_min,delta_y,v_avg,t_avg];
   end
end
function result2=find2(l1_num,l2_num,k_num,m,g)
   syms theta1 theta2 l1 l2 real
   k=sym('k','real');

   n=length(l1_num);
   % v_average=zeros(n,1)
   max_t=zeros(n,1);
   max_aang=zeros(n,1);
   max_bang=zeros(n,1);
   min_t=zeros(n,1);
   min_aang=zeros(n,1);
   min_bang=zeros(n,1);

   % 关节A（原点）驱动D点
   % k<1
   Dx=k*l1*cos(theta1);
   Dy=k*l1*sin(theta2);

   % 关节B（原点）驱动E点
   Ex=k*l1*cos(theta2);
   Ey=k*l2*sin(theta2);

   % 关节C点坐标，解方程组，符号解
   syms Cx Cy real
   eq1=(Cx-Dx)^2+(Cy-Dy)^2==(k*l2)^2;
   eq2=(Cx-Ex)^2+(Cy-Ey)^2==(k*l2)^2;
   sol=solve([eq1,eq2],[Cx,Cy]);

   % 选择物理可行的解
   Cx_sol=real(sol.Cx(1));
   Cy_sol=real(sol.Cy(1));

   % 关节H点坐标
   syms Hx Hy real
   Hx=l1*cos(theta2);
   Hy=l1*sin(theta2);
   
   % 关节J点坐标
   syms jx jy real
   jx=Hx+1/k*(Cx_sol-Ex);
   jy=Hy+1/k*(Cy_sol-Ey);
   % 对theta1和theta2求偏导
   J=[diff(jx,theta1),diff(jx,theta2);diff(jy,theta1),diff(jy,theta2)];
   J_func=matlabFunction(J,'Vars',{theta1,theta2,l1,l2,k});
   n=length(l1_num);
   result2=zeros(n,6);

   parfor j=1:n
       %雅可比矩阵计算
       l1_val=l1_num(j)/1000; %转为为米
       l2_val=l2_num(j)/1000; %转为为米
       k_val=k_num;

       interval1=5
       a_ang=60;
       b_ang=-20;
       mid_ang=(a_ang-b_ang)/2;
       t=[];
       while a_ang>mid_ang
           theta1_val=deg2rad(180-a_ang);
           theta2_val=deg2rad(b_ang);
           J_num=J_func(theta1_val,theta2_val,l1_val,l2_val,k_val);
           F=[0;m*g/2];
           tau_final=J_num'*F;
           t(end+1)=abs(tau_final(1));
           t(end+1)=abs(tau_final(2));
           b_ang=b_ang+interval1;
       end
       b_ang=-20;
       a_ang=a_ang-interval1;
       % 处理极值
       [current_max,idx_max]=max(t);
       [current_min,idx_min]=min(t);
       result_max=findindex(idx_max);
       result_min=findindex(idx_min);
       result2(j,:)=[current_max,result_max,current_min,result_min];
   end
end
function result3=findindex(index)
    if rem(index,2)==0
        index=index/2;
    else
        index=(index+1)/2;
    end
    index_b=mod(index,10); %取余
    index_a=(index-index_b); %取商
    aang=60-5*index_a;
    bang=-20+5*(index_b-1);
    result3=[aang,bang];
end