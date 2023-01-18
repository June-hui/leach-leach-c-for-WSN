clc;
clear;
%% 1.��ʼ�����趨ģ��
%.�������ڵ��������(��λ m)
xm = 100;
ym = 100;
% (1)��۽��������
sink.x = 0.5*xm;
sink.y = 1.35*ym;
% �����ڴ�������
n = 100;
% ��ͷ�Ż���������ѡ��ͷ�ĸ��ʣ�
p = 0.1;
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
    S(i).xd = rand(1,1)*xm;
    S(i).yd = rand(1,1)*ym;
    S(i).G = 0;
    S(i).E = Eo;
    % initially there are no cluster heads only nodes
    S(i).type = 'N';
end
S(n+1).xd = sink.x;
S(n+1).yd = sink.y;

%% 3.��������ģ��
% ��ͷ�ڵ���
countCHs = 0;
cluster = 1;% �˶����Ŀ�Ľ����Ǹ���һ��1��ʼ���±�����������Ĵ�ͷ��Ӧ�û���ȥ1
flag_first_dead = 0;
flag_teenth_dead = 0;
flag_all_dead = 0;
% �����ڵ���
dead = 0;
first_dead = 0;
teenth_dead = 0;
all_dead = 0;
% ��ڵ���
alive = n;
% ���䵽��վ�ʹ�ͷ�ı��ؼ�����
packets_TO_BS = 0;
packets_TO_CH = 0;
% (1)ѭ��ģʽ�趨
for r = 0:rmax     % �� for ѭ������������г���������ڣ�ֱ����� end �Ž���ѭ��
    %r
    % ÿ��һ����ת����(������Ϊ10��)ʹ���ڵ��S(i).G�������ò������ں���Ĵ�ѡ�٣��ڸ���ת�������ѵ�ѡ����ͷ�Ľڵ㲻���ٵ�ѡ���ָ�Ϊ��
    if mod(r, round(1/p)) == 0
        for i = 1:n
            S(i).G = 0;
        end
    end
    % (2)�����ڵ���ģ��
    dead = 0;
    Et = 0;
    for i = 1:n
        % ������������ڵ�
        if S(i).E <= 0
            dead = dead+1;
            % (3)��һ�������ڵ�Ĳ���ʱ��(���ִα�ʾ)
            % ��һ���ڵ�����ʱ��
            if dead == 1
                if flag_first_dead == 0
                    first_dead = r;
                    flag_first_dead = 1;
                end
            end
            % 10%�Ľڵ�����ʱ��
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
    % (4)��ͷѡ��ģ��
    countCHs = 0;
    cluster = 1;
    for i = 1:n
        if Ea > 0
            if S(i).E > 0
                temp_rand=rand;
                if S(i).G <= 0
                    % ��ͷ��ѡ�٣���ѡ�Ĵ�ͷ��Ѹ�������Ŵ�����������������ı�����
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
                        % �����ͷ����packetLength bit���ݵ���վ���������ģ�����Ӧ�����нڵ������ͷÿһ�ַ���packetLength bit���ݣ�
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
    % (5)���ڳ�Աѡ���ͷģ��(���ص��γ�ģ��)
    % ���ڳ�Ա�Դ�ͷ��ѡ�񣨼��ص��γɣ��㷨
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
                    % ���ڽڵ㣨����packetLength bit���ݣ���������
                    if min_dis > do
                        S(i).E=S(i).E- (ETX*packetLength + Emp*packetLength*min_dis^4);
                    else
                        S(i).E=S(i).E- (ETX*packetLength + Efs*packetLength*min_dis^2);
                    end
                    % ��ͷ�����պ��ں���һ���ڽڵ�packetLength bit���ݣ�����������
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

%% ��ͼ�Ƚ�
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
%STATISTICS���ṹ�����飬���������5��������
%countCHs(r+1��,ÿһ����ѡ���Ĵ�ͷ��Ŀ;
%packets_TO_BS(r+1),��վ�յ������ݰ�����;
%PACKETS_TO_CH(r+1),��ͷ�յ������ݰ�����;
%first_dead,��һ���ڵ�������ʱ��;
%teenth_dead=r,10%�Ľڵ�������ʱ�䣻
%dead(r+1),ÿһ�ֵ������ڵ�����
%alive(r+1),ÿһ�ֵĻ�ڵ�����

