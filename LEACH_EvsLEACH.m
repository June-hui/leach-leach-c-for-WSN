clc;
clear;
%% 1.初始参数设定模块
%.传感器节点区域界限(单位 m)
xm = 100;
ym = 100;
% (1)汇聚节坐标给定
sink.x = 0.5*xm;
sink.y = 0.5*ym;
% 区域内传器节数
n = 100;
% 簇头优化比例（当选簇头的概率）
p = 0.05;
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
    S1(i).xd = rand(1,1)*xm;
    S2(i).xd = S1(i).xd;
    S1(i).yd = rand(1,1)*ym;
    S2(i).yd = S1(i).yd;
    S1(i).G = 0;
    S2(i).G = 0;
    S1(i).E = Eo;
    S2(i).E = Eo;
    % initially there are no cluster heads only nodes
    S1(i).type = 'N';
    S2(i).type = 'N';
end
S1(n+1).xd = sink.x;
S1(n+1).yd = sink.y;
S2(n+1).xd = sink.x;
S2(n+1).yd = sink.y;
%%%%%%%%%%%%%%%%LEACH-E%%%%%%%%%%%%%%%%
%% 3.网络运行模块
% 簇头节点数
countCHs1 = 0;
cluster1 = 1;% 此定义的目的仅仅是给定一个1开始的下标参数，真正的簇头数应该还减去1
flag_first_dead1 = 0;
flag_teenth_dead1 = 0;
flag_all_dead1 = 0;
% 死亡节点数
dead1 = 0;
first_dead1 = 0;
teenth_dead1 = 0;
all_dead1 = 0;
% 活动节点数
alive1 = n;
% 传输到基站和簇头的比特计数器
packets_TO_BS1 = 0;
packets_TO_CH1 = 0;
% (1)循环模式设定
for r = 0:rmax     % 该 for 循环将下面的所有程序包括在内，直到最后 end 才结束循环
    %r
    % 每过一个轮转周期(本程序为10次)使各节点的S(i).G参数（该参数用于后面的簇选举，在该轮转周期内已当选过簇头的节点不能再当选）恢复为零
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S1(i).G = 0;
        end
    end
    % (2)死亡节点检查模块
    dead = 0;
    Et = 0;
    for i = 1:n
        % 检查有无死亡节点
        if S1(i).E <= 0
            dead = dead+1;
            % (3)第一个死亡节点的产生时间(用轮次表示)
            % 第一个节点死亡时间
            if dead == 1
                if flag_first_dead1 == 0
                    first_dead1 = r;
                    flag_first_dead1 = 1;
                end
            end
            % 10%的节点死亡时间
            if dead == 0.1*n
                if flag_teenth_dead1 ==0
                    teenth_dead1 = r;
                    flag_teenth_dead1 = 1;
                end
            end
            if dead == n
                if flag_all_dead1 == 0
                    all_dead1 = r;
                    flag_all_dead1 = 1;
                end
            end
        end
        if S1(i).E > 0
            Et = Et+S1(i).E;
            S1(i).type = 'N';
        end
    end
%     if flag_all_dead1 == 1
%         break;
%     end
    STATISTICS.DEAD1(r+1) = dead;
    STATISTICS.alive1(r+1) = alive1-dead;
    Ea = Et/STATISTICS.alive1(r+1);
    % (4)簇头选举模块
    countCHs1 = 0;
    cluster1 = 1;
    for i = 1:n
        if Ea > 0
            if S1(i).E > 0
                temp_rand=rand;
                if S1(i).G <= 0
                    % 簇头的选举，当选的簇头会把各种相关信存入下面程序所给定的变量中
                    if temp_rand <= p/(1-p*mod(r,round(1/p)))*S1(i).E/Ea
                        countCHs1 = countCHs1+1;
                        packets_TO_BS1 = packets_TO_BS1+1;
                        S1(i).type = 'C';
                        S1(i).G = round(1/p)-1;
                        C(cluster1).xd = S1(i).xd;
                        C(cluster1).yd = S1(i).yd;
                        distance = sqrt((S1(i).xd-S1(n+1).xd)^2 + (S1(i).yd-S1(n+1).yd)^2);
                        C(cluster1).distance = distance;
                        C(cluster1).id = i;
                        cluster1 = cluster1+1;
                        % 计算簇头发送packetLength bit数据到基站的能量消耗（这里应是所有节点包括簇头每一轮发送packetLength bit数据）
                        if distance > do
                            S1(i).E = S1(i).E- ((ETX+EDA)*packetLength + Emp*packetLength*distance^4);
                        else
                            S1(i).E=S1(i).E- ((ETX+EDA)*packetLength + Efs*packetLength*distance^2);
                        end
                    end
                end
            end
        end
    end
    STATISTICS.COUNTCHS1(r+1) = countCHs1;
    % (5)簇内成员选择簇头模块(即簇的形成模块)
    % 簇内成员对簇头的选择（即簇的形成）算法
    for i = 1:n
        if S1(i).type == 'N' && S1(i).E > 0 
            if cluster1-1 >= 1
                min_dis = sqrt((S1(i).xd-S1(n+1).xd)^2 + (S1(i).yd-S1(n+1).yd)^2);
                min_dis_cluster = 0;
                for c = 1:cluster1-1
                    temp = min(min_dis, sqrt((S1(i).xd-C(c).xd)^2 + (S1(i).yd-C(c).yd)^2));
                    if temp < min_dis 
                        min_dis = temp;
                        min_dis_cluster = c;
                    end
                end
                if min_dis_cluster ~= 0
                    % 簇内节点（发送packetLength bit数据）能量消耗
                    if min_dis > do
                        S1(i).E=S1(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S1(i).E=S1(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % 簇头（接收和融合这一簇内节点packetLength bit数据）的能量消耗
                    S1(C(min_dis_cluster).id).E = S1(C(min_dis_cluster).id).E- ((ERX + EDA)*packetLength);
                    packets_TO_CH1 = packets_TO_CH1+1;
                else
                    if min_dis > do
                        S1(i).E = S1(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S1(i).E = S1(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    packets_TO_BS1 = packets_TO_BS1+1;
                end
                S1(i).min_dis = min_dis;
                S1(i).min_dis_cluster = min_dis_cluster;
            else
                min_dis = sqrt((S1(i).xd-S1(n+1).xd)^2 + (S1(i).yd-S1(n+1).yd)^2);
                if min_dis > do
                    S1(i).E = S1(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                else
                    S1(i).E = S1(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                end
                packets_TO_BS1 = packets_TO_BS1+1;
            end
        end
    end
    STATISTICS.PACKETS_TO_CH1(r+1) = packets_TO_CH1;
    STATISTICS.PACKETS_TO_BS1(r+1) = packets_TO_BS1;
end

%%%%%%%%%%%%%%%%%LEACH%%%%%%%%%%%%%%%%%%
%% 3.网络运行模块
% 簇头节点数
countCHs2 = 0;
cluster2 = 1;% 此定义的目的仅仅是给定一个1开始的下标参数，真正的簇头数应该还减去1
flag_first_dead2 = 0;
flag_teenth_dead2 = 0;
flag_all_dead2 = 0;
% 死亡节点数
dead2 = 0;
first_dead2 = 0;
teenth_dead2 = 0;
all_dead2 = 0;
% 活动节点数
alive2 = n;
% 传输到基站和簇头的比特计数器
packets_TO_BS2 = 0;
packets_TO_CH2 = 0;
% (1)循环模式设定
for r = 0:rmax     % 该 for 循环将下面的所有程序包括在内，直到最后 end 才结束循环
    %r
    % 每过一个轮转周期(本程序为10次)使各节点的S(i).G参数（该参数用于后面的簇选举，在该轮转周期内已当选过簇头的节点不能再当选）恢复为零
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S2(i).G = 0;
        end
    end
    % (2)死亡节点检查模块
    dead = 0;
    for i = 1:n
        % 检查有无死亡节点
        if S2(i).E <= 0
            dead = dead+1;
            % (3)第一个死亡节点的产生时间(用轮次表示)
            % 第一个节点死亡时间
            if dead == 1
                if flag_first_dead2 == 0
                    first_dead2 = r;
                    flag_first_dead2 = 1;
                end
            end
            % 10%的节点死亡时间
            if dead == 0.1*n
                if flag_teenth_dead2 ==0
                    teenth_dead2 = r;
                    flag_teenth_dead2 = 1;
                end
            end
            if dead == n
                if flag_all_dead2 == 0
                    all_dead2 = r;
                    flag_all_dead2 = 1;
                end
            end
        end
        if S2(i).E > 0
            S2(i).type = 'N';
        end
    end
    STATISTICS.DEAD2(r+1) = dead;
    STATISTICS.alive2(r+1) = alive1-dead;
    % (4)簇头选举模块
    countCHs2 = 0;
    cluster2 = 1;
    for i = 1:n
            if S2(i).E > 0
                temp_rand=rand;
                if S2(i).G <= 0
                    % 簇头的选举，当选的簇头会把各种相关信存入下面程序所给定的变量中
                    if temp_rand <= p/(1-p*mod(r,round(1/p)))
                        countCHs2 = countCHs2+1;
                        packets_TO_BS2 = packets_TO_BS2+1;
                        S2(i).type = 'C';
                        S2(i).G = round(1/p)-1;
                        C(cluster2).xd = S2(i).xd;
                        C(cluster2).yd = S2(i).yd;
                        distance = sqrt((S2(i).xd-S2(n+1).xd)^2 + (S2(i).yd-S2(n+1).yd)^2);
                        C(cluster2).distance = distance;
                        C(cluster2).id = i;
                        cluster2 = cluster2+1;
                        % 计算簇头发送packetLength bit数据到基站的能量消耗（这里应是所有节点包括簇头每一轮发送packetLength bit数据）
                        if distance > do
                            S2(i).E = S2(i).E- ((ETX+EDA)*packetLength + Emp*packetLength*distance^4);
                        else
                            S2(i).E=S2(i).E- ((ETX+EDA)*packetLength + Efs*packetLength*distance^2);
                        end
                    end
                end
            end
    end
    STATISTICS.COUNTCHS2(r+1) = countCHs2;
    % (5)簇内成员选择簇头模块(即簇的形成模块)
    % 簇内成员对簇头的选择（即簇的形成）算法
    for i = 1:n
        if S2(i).type == 'N' && S2(i).E > 0 
            if cluster2-1 >= 1
                min_dis = inf;
                min_dis_cluster = 0;
                for c = 1:cluster2-1
                    temp = min(min_dis, sqrt((S2(i).xd-C(c).xd)^2 + (S2(i).yd-C(c).yd)^2));
                    if temp < min_dis 
                        min_dis = temp;
                        min_dis_cluster = c;
                    end
                end
                if min_dis_cluster ~= 0
                    % 簇内节点（发送packetLength bit数据）能量消耗
                    if min_dis > do
                        S2(i).E=S2(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S2(i).E=S2(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % 簇头（接收和融合这一簇内节点packetLength bit数据）的能量消耗
                    S2(C(min_dis_cluster).id).E = S2(C(min_dis_cluster).id).E- ((ERX + EDA)*packetLength);
                    packets_TO_CH2 = packets_TO_CH2+1;
                else
                    if min_dis > do
                        S2(i).E = S2(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S2(i).E = S2(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    packets_TO_BS2 = packets_TO_BS2+1;
                end
                S2(i).min_dis = min_dis;
                S2(i).min_dis_cluster = min_dis_cluster;
            else
                min_dis = sqrt((S2(i).xd-S2(n+1).xd)^2 + (S2(i).yd-S2(n+1).yd)^2);
                if min_dis > do
                    S2(i).E = S2(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                else
                    S2(i).E = S2(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                end
                packets_TO_BS2 = packets_TO_BS2+1;
            end
        end
    end
    STATISTICS.PACKETS_TO_CH2(r+1) = packets_TO_CH2;
    STATISTICS.PACKETS_TO_BS2(r+1) = packets_TO_BS2;
end
%%%%% 绘图比较
r = 0:rmax;
figure;
plot(r, STATISTICS.DEAD1, 'r', r, STATISTICS.DEAD2, 'g', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Number of nodes dead';
legend('LEACH-E', 'LEACH');
figure;
plot(r, STATISTICS.alive1, 'r', r, STATISTICS.alive2, 'g', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Number of nodes alive';
legend('LEACH-E', 'LEACH');
figure;
plot(r, STATISTICS.PACKETS_TO_BS1, 'r', r, STATISTICS.PACKETS_TO_BS2, 'g', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Total number of packets received by base station';
legend('LEACH-E', 'LEACH');
figure;
plot(r, STATISTICS.COUNTCHS1, 'r', r, STATISTICS.COUNTCHS2, 'g', 'linewidth', 2);
xlabel 'Time(Round)'; ylabel 'Number of cluster heads selected';
legend('LEACH-E', 'LEACH');
%STATISTICS，结构体数组，包括下面的5个变量；
%countCHs(r+1）,每一轮所选出的簇头数目;
%packets_TO_BS(r+1),基站收到的数据包总数;
%PACKETS_TO_CH(r+1),簇头收到的数据包总数;
%first_dead,第一个节点死亡的时间;
%teenth_dead=r,10%的节点死亡的时间；
%dead(r+1),每一轮的死亡节点数；
%alive(r+1),每一轮的活动节点数。

