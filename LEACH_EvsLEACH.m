clc;
clear;
%% 1.��ʼ�����趨ģ��
%.�������ڵ��������(��λ m)
xm = 100;
ym = 100;
% (1)��۽��������
sink.x = 0.5*xm;
sink.y = 0.5*ym;
% �����ڴ�������
n = 100;
% ��ͷ�Ż���������ѡ��ͷ�ĸ��ʣ�
p = 0.05;
% ����ģ�ͣ���λ J��
% ��ʼ������ģ��
Eo = 0.5;
% Eelec=Etx=Erx
ETX = 50*0.000000001;
ERX = 50*0.000000001;
% Transmit Amplifier types
Efs = 10*0.000000000001;
Emp = 0.0013*0.000000000001;
% Data Aggregation Energy
EDA = 5*0.000000001;
% ���ѭ������
rmax = 2000;
% ������� do
do = sqrt(Efs/Emp);
% ����С����λ bit��
packetLength = 4000;        % ���ݰ���С

%% 2.���ߴ���������ģ�Ͳ���ģ��
% �������ߴ���������,�������ھ���Ͷ��100���ڵ�,������ͼ��
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
%% 3.��������ģ��
% ��ͷ�ڵ���
countCHs1 = 0;
cluster1 = 1;% �˶����Ŀ�Ľ����Ǹ���һ��1��ʼ���±�����������Ĵ�ͷ��Ӧ�û���ȥ1
flag_first_dead1 = 0;
flag_teenth_dead1 = 0;
flag_all_dead1 = 0;
% �����ڵ���
dead1 = 0;
first_dead1 = 0;
teenth_dead1 = 0;
all_dead1 = 0;
% ��ڵ���
alive1 = n;
% ���䵽��վ�ʹ�ͷ�ı��ؼ�����
packets_TO_BS1 = 0;
packets_TO_CH1 = 0;
% (1)ѭ��ģʽ�趨
for r = 0:rmax     % �� for ѭ������������г���������ڣ�ֱ����� end �Ž���ѭ��
    %r
    % ÿ��һ����ת����(������Ϊ10��)ʹ���ڵ��S(i).G�������ò������ں���Ĵ�ѡ�٣��ڸ���ת�������ѵ�ѡ����ͷ�Ľڵ㲻���ٵ�ѡ���ָ�Ϊ��
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S1(i).G = 0;
        end
    end
    % (2)�����ڵ���ģ��
    dead = 0;
    Et = 0;
    for i = 1:n
        % ������������ڵ�
        if S1(i).E <= 0
            dead = dead+1;
            % (3)��һ�������ڵ�Ĳ���ʱ��(���ִα�ʾ)
            % ��һ���ڵ�����ʱ��
            if dead == 1
                if flag_first_dead1 == 0
                    first_dead1 = r;
                    flag_first_dead1 = 1;
                end
            end
            % 10%�Ľڵ�����ʱ��
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
    % (4)��ͷѡ��ģ��
    countCHs1 = 0;
    cluster1 = 1;
    for i = 1:n
        if Ea > 0
            if S1(i).E > 0
                temp_rand=rand;
                if S1(i).G <= 0
                    % ��ͷ��ѡ�٣���ѡ�Ĵ�ͷ��Ѹ�������Ŵ�����������������ı�����
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
                        % �����ͷ����packetLength bit���ݵ���վ���������ģ�����Ӧ�����нڵ������ͷÿһ�ַ���packetLength bit���ݣ�
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
    % (5)���ڳ�Աѡ���ͷģ��(���ص��γ�ģ��)
    % ���ڳ�Ա�Դ�ͷ��ѡ�񣨼��ص��γɣ��㷨
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
                    % ���ڽڵ㣨����packetLength bit���ݣ���������
                    if min_dis > do
                        S1(i).E=S1(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S1(i).E=S1(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % ��ͷ�����պ��ں���һ���ڽڵ�packetLength bit���ݣ�����������
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
%% 3.��������ģ��
% ��ͷ�ڵ���
countCHs2 = 0;
cluster2 = 1;% �˶����Ŀ�Ľ����Ǹ���һ��1��ʼ���±�����������Ĵ�ͷ��Ӧ�û���ȥ1
flag_first_dead2 = 0;
flag_teenth_dead2 = 0;
flag_all_dead2 = 0;
% �����ڵ���
dead2 = 0;
first_dead2 = 0;
teenth_dead2 = 0;
all_dead2 = 0;
% ��ڵ���
alive2 = n;
% ���䵽��վ�ʹ�ͷ�ı��ؼ�����
packets_TO_BS2 = 0;
packets_TO_CH2 = 0;
% (1)ѭ��ģʽ�趨
for r = 0:rmax     % �� for ѭ������������г���������ڣ�ֱ����� end �Ž���ѭ��
    %r
    % ÿ��һ����ת����(������Ϊ10��)ʹ���ڵ��S(i).G�������ò������ں���Ĵ�ѡ�٣��ڸ���ת�������ѵ�ѡ����ͷ�Ľڵ㲻���ٵ�ѡ���ָ�Ϊ��
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S2(i).G = 0;
        end
    end
    % (2)�����ڵ���ģ��
    dead = 0;
    for i = 1:n
        % ������������ڵ�
        if S2(i).E <= 0
            dead = dead+1;
            % (3)��һ�������ڵ�Ĳ���ʱ��(���ִα�ʾ)
            % ��һ���ڵ�����ʱ��
            if dead == 1
                if flag_first_dead2 == 0
                    first_dead2 = r;
                    flag_first_dead2 = 1;
                end
            end
            % 10%�Ľڵ�����ʱ��
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
    % (4)��ͷѡ��ģ��
    countCHs2 = 0;
    cluster2 = 1;
    for i = 1:n
            if S2(i).E > 0
                temp_rand=rand;
                if S2(i).G <= 0
                    % ��ͷ��ѡ�٣���ѡ�Ĵ�ͷ��Ѹ�������Ŵ�����������������ı�����
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
                        % �����ͷ����packetLength bit���ݵ���վ���������ģ�����Ӧ�����нڵ������ͷÿһ�ַ���packetLength bit���ݣ�
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
    % (5)���ڳ�Աѡ���ͷģ��(���ص��γ�ģ��)
    % ���ڳ�Ա�Դ�ͷ��ѡ�񣨼��ص��γɣ��㷨
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
                    % ���ڽڵ㣨����packetLength bit���ݣ���������
                    if min_dis > do
                        S2(i).E=S2(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S2(i).E=S2(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % ��ͷ�����պ��ں���һ���ڽڵ�packetLength bit���ݣ�����������
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
%%%%% ��ͼ�Ƚ�
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
%STATISTICS���ṹ�����飬���������5��������
%countCHs(r+1��,ÿһ����ѡ���Ĵ�ͷ��Ŀ;
%packets_TO_BS(r+1),��վ�յ������ݰ�����;
%PACKETS_TO_CH(r+1),��ͷ�յ������ݰ�����;
%first_dead,��һ���ڵ�������ʱ��;
%teenth_dead=r,10%�Ľڵ�������ʱ�䣻
%dead(r+1),ÿһ�ֵ������ڵ�����
%alive(r+1),ÿһ�ֵĻ�ڵ�����

