clc;
clear;
%% 1.初始参数设定模块
%.传感器节点区域界限(单位 m)
xm = 100;
ym = 100;
% (1)汇聚节坐标给定
sink.x = 0.5*xm;
sink.y = 1.35*ym;
% 区域内传器节数
n = 100;
% 簇头优化比例（当选簇头的概率）
p = 0.1;
% 能量模型（单位 J）
% 初始化能量模型
Eo = 0.5;
% Eelec=Etx=Erx
ETX = 50*0.000000001;
ERX = 50*0.000000001;
% Transmit Amplifier types
Efs = 10*0.000000000001;
Emp = 0.0013*0.000000000001;
% Data Aggregation Energy
EDA = 5*0.000000001;
% 最大循环次数
rmax = 2000;
% 算出参数 do
do = sqrt(Efs/Emp);
% 包大小（单位 bit）
packetLength = 4000;        % 数据包大小

%% 2.无线传感器网络模型产生模块
% 构建无线传感器网络,在区域内均匀投放100个节点,并画出图形
for i = 1:n
    S(i).xd = rand(1,1)*xm;
    S(i).yd = rand(1,1)*ym;
    S(i).G = 0;
    S(i).E = Eo;
    % initially there are no cluster heads only nodes
    S(i).type = 'N';
end
S(n+1).xd = sink.x;
S(n+1).yd = sink.y;

%% 3.网络运行模块
% 簇头节点数
countCHs = 0;
cluster = 1;% 此定义的目的仅仅是给定一个1开始的下标参数，真正的簇头数应该还减去1
flag_first_dead = 0;
flag_teenth_dead = 0;
flag_all_dead = 0;
% 死亡节点数
dead = 0;
first_dead = 0;
teenth_dead = 0;
all_dead = 0;
% 活动节点数
alive = n;
% 传输到基站和簇头的比特计数器
packets_TO_BS = 0;
packets_TO_CH = 0;
% (1)循环模式设定
for r = 0:rmax     % 该 for 循环将下面的所有程序包括在内，直到最后 end 才结束循环
    %r
    % 每过一个轮转周期(本程序为10次)使各节点的S(i).G参数（该参数用于后面的簇选举，在该轮转周期内已当选过簇头的节点不能再当选）恢复为零
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S(i).G = 0;
        end
    end
    % (2)死亡节点检查模块
    dead = 0;
    Et = 0;
    for i = 1:n
        % 检查有无死亡节点
        if S(i).E <= 0
            dead = dead+1;
            % (3)第一个死亡节点的产生时间(用轮次表示)
            % 第一个节点死亡时间
            if dead == 1
                if flag_first_dead == 0
                    first_dead = r;
                    flag_first_dead = 1;
                end
            end
            % 10%的节点死亡时间
            if dead == 0.1*n
                if flag_teenth_dead ==0
                    teenth_dead = r;
                    flag_teenth_dead = 1;
                end
            end
            if dead == n
                if flag_all_dead == 0
                    all_dead = r;
                    flag_all_dead = 1;
                end
            end
        end
        if S(i).E > 0
            Et = Et+S(i).E;
            S(i).type = 'N';
        end
    end
    STATISTICS.DEAD(r+1) = dead;
    STATISTICS.ALIVE(r+1) = alive-dead;
    Ea = Et/STATISTICS.ALIVE(r+1);
    % (4)簇头选举模块
    countCHs = 0;
    cluster = 1;
    for i = 1:n
        if Ea > 0
            if S(i).E > 0
                temp_rand=rand;
                if S(i).G <= 0
                    % 簇头的选举，当选的簇头会把各种相关信存入下面程序所给定的变量中
                    if temp_rand <= p/(1-p*mod(r,round(1/p)))*S(i).E/Ea
                        countCHs = countCHs+1;
                        packets_TO_BS = packets_TO_BS+1;
                        S(i).type = 'C';
                        S(i).G = round(1/p)-1;
                        C(cluster).xd = S(i).xd;
                        C(cluster).yd = S(i).yd;
                        distance = sqrt((S(i).xd-S(n+1).xd)^2 + (S(i).yd-S(n+1).yd)^2);
                        C(cluster).distance = distance;
                        C(cluster).id = i;
                        cluster = cluster+1;
                        % 计算簇头发送packetLength bit数据到基站的能量消耗（这里应是所有节点包括簇头每一轮发送packetLength bit数据）
                        if distance > do
                            S(i).E = S(i).E- ((ETX+EDA)*packetLength + Emp*packetLength*distance^4);
                        else
                            S(i).E=S(i).E- ((ETX+EDA)*packetLength + Efs*packetLength*distance^2);
                        end
                    end
                end
            end
        end
    end
    STATISTICS.COUNTCHS(r+1) = countCHs;
    % (5)簇内成员选择簇头模块(即簇的形成模块)
    % 簇内成员对簇头的选择（即簇的形成）算法
    for i = 1:n
        if S(i).type == 'N' && S(i).E > 0 
            if cluster-1 >= 1
                min_dis = sqrt((S(i).xd-S(n+1).xd)^2 + (S(i).yd-S(n+1).yd)^2);
                min_dis_cluster = 0;
                for c = 1:cluster-1
                    temp = min(min_dis, sqrt((S(i).xd-C(c).xd)^2 + (S(i).yd-C(c).yd)^2));
                    if temp < min_dis 
                        min_dis = temp;
                        min_dis_cluster = c;
                    end
                end
                if min_dis_cluster ~= 0
                    % 簇内节点（发送packetLength bit数据）能量消耗
                    if min_dis > do
                        S(i).E=S(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S(i).E=S(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % 簇头（接收和融合这一簇内节点packetLength bit数据）的能量消耗
                    S(C(min_dis_cluster).id).E = S(C(min_dis_cluster).id).E- ((ERX + EDA)*packetLength);
                    packets_TO_CH = packets_TO_CH+1;
                else
                    if min_dis > do
                        S(i).E = S(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S(i).E = S(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    packets_TO_BS = packets_TO_BS+1;
                end
                S(i).min_dis = min_dis;
                S(i).min_dis_cluster = min_dis_cluster;
            else
                min_dis = sqrt((S(i).xd-S(n+1).xd)^2 + (S(i).yd-S(n+1).yd)^2);
                if min_dis > do
                    S(i).E = S(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                else
                    S(i).E = S(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                end
                packets_TO_BS = packets_TO_BS+1;
            end
        end
    end
    STATISTICS.PACKETS_TO_CH(r+1) = packets_TO_CH;
    STATISTICS.PACKETS_TO_BS(r+1) = packets_TO_BS;
end

%% 绘图比较
r = 0:rmax;
% figure;
% plot(r, STATISTICS.DEAD, 'r', 'linewidth', 2);
% xlabel 'Time(Round)'; ylabel 'Number of nodes dead';
figure;
plot(r, STATISTICS.ALIVE, 'r', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Number of nodes alive';
figure;
plot(r, STATISTICS.PACKETS_TO_BS, 'r', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Total number of packets received by base station';
% figure;
% plot(r, STATISTICS.COUNTCHS, 'r', 'linewidth', 2);
% xlabel 'Time(Round)'; ylabel 'Number of cluster heads selected';
%STATISTICS，结构体数组，包括下面的5个变量；
%countCHs(r+1）,每一轮所选出的簇头数目;
%packets_TO_BS(r+1),基站收到的数据包总数;
%PACKETS_TO_CH(r+1),簇头收到的数据包总数;
%first_dead,第一个节点死亡的时间;
%teenth_dead=r,10%的节点死亡的时间；
%dead(r+1),每一轮的死亡节点数；
%alive(r+1),每一轮的活动节点数。

