clear;clc;

f=@(x) x*exp(x)-1;
df=@(x) x*exp(x)+exp(x);

x0=0.5;
N=1000;
esp1=0.0001;
esp2=0.001;

x_k=x0;
f_k=f(x_k);
df_k=df(x_k);
k=0;

while true
    if k>N
        disp('迭代失败');
        break;
    end
    if df_k==0
        disp('导数为0，迭代失败');
        break;
    end
    x_k1=x_k-f_k/df_k;
    f_k1=f(x_k1);
    df_k1=df(x_k1);

    if abs(x_k1)<1
        delta=abs(x_k1-x_k);
    else
        delta=abs(x_k1-x_k)/abs(x_k1);
    end

    if delta<esp1 || abs(f_k1)<esp2
        fprintf('最终的根为：x=%.6f\n',x_k1);
        fprintf('f（x）=%e\n',f_k1);
        break;
    end

    x_k=x_k1;
    f_k=f_k1;
    df_k=df_k1;
    k=k+1;
end

