%% Input the initial positions (x, y, 0) and the goal position (x, y, 0)
init_pos = [170, 0, 0];
goal_pos = [0, 170, 0];
grasp_h = 70; % Set the grasp height of the grasper
grasp_d = 60; % Set the grasp deep value
%% Set the t0, tf, and timestep for long distance movement
t0 = 0;
tf = 2;
timestep = 0.05;
% Set the t00 tff and timesteps and movestep for the short distance movement
t00 = 0;
timesteps = 0.1;
movestep = 2;
tff = grasp_d*timesteps/movestep;

init_up= init_pos + [0, 0, grasp_h];
init_grasp_pos = init_pos + [0, 0, grasp_h - grasp_d];
goal_up = goal_pos + [0, 0, grasp_h];
goal_grasp_pos = goal_pos + [0, 0, grasp_h - grasp_d];
startup_rvc;
%% Build the robot model
MDH = modified_DH();
d1 = MDH(1, 1);
d2 = MDH(2, 1);
d3 = MDH(3, 1);
d4 = MDH(4, 1);
d5 = MDH(5, 1);
d6 = MDH(6, 1);

a0 = MDH(1, 2);
a1 = MDH(2, 2);
a2 = MDH(3, 2);
a3 = MDH(4, 2);
a4 = MDH(5, 2);
a5 = MDH(6, 2);

alpha0 = MDH(1, 3);
alpha1 = MDH(2, 3);
alpha2 = MDH(3, 3);
alpha3 = MDH(4, 3);
alpha4 = MDH(5, 3);
alpha5 = MDH(6, 3);
% Build the links
%      theta   d        a        alpha
L1=Link([0     d1       a0       alpha0     ],'modified');L1.offset = 0;
L2=Link([0     d2       a1       alpha1     ],'modified');L2.offset = -pi/2;
L3=Link([0     d3       a2       alpha2     ],'modified');L3.offset = -pi/2;
L4=Link([0     d4       a3       alpha3     ],'modified');L4.offset = 0;
L5=Link([0     d5       a4       alpha4     ],'modified');L5.offset = pi/2;
L6=Link([0     d6       a5       alpha5     ],'modified');
robot=SerialLink([L1 L2 L3 L4 L5 L6],'name','Steve');
robot.teach;%展示机器人模型
hold on;
%% Generate the trajectory
%% From HOME position to GRASP_UP position
p0 = [0 0 0 0 0 0];
v0 = [0 0 0 0 0 0];
Ti = [1, 0, 0, init_up(1);
      0, -1, 0, init_up(2);
      0, 0, -1, init_up(3)];
pf = my_inv(Ti);
vf = [0 0 0 0 0 0];
[q1] = LSPBTrajectory(p0, v0, pf, vf, t0, tf, timestep);
%[q1] = CubicTrajectory(p0, v0, pf, vf, t0, tf, timestep);


%% 这一步需要优化，走的步数 From  GRASP_UP position to GRASP position
%% 抓取深度，the grasp deep h
p_up = init_up;
take_or_place = 0; % if this value is 0, moving down 
[q2] = Task_Space_Trajectory(p_up, t00, tff,timesteps, movestep,take_or_place);
q = [q1; q2];
%% From GRASP position to GRASP_UP position
p_offset = init_grasp_pos;
take_or_place = 1;
[q3] = Task_Space_Trajectory(p_offset, t00, tff,timesteps,movestep, take_or_place);
q = [q; q3];
%% From GRASP_UP position to GOAL_UP position

L = size(q);
p0 = q(L(1),:);
v0 = [0 0 0 0 0 0];
vf = [0 0 0 0 0 0];
Ti = [1, 0, 0, goal_up(1);
      0, -1, 0, goal_up(2);
      0, 0, -1, goal_up(3)];
pf = my_inv(Ti);
[q4] = LSPBTrajectory(p0, v0, pf, vf, t0, tf, timestep);
% [q4] = CubicTrajectory(p0, v0, pf, vf, t0, tf, timestep);
q = [q;q4];
%% From GOAL_UP position to REAlSE position
p_offset = goal_up;
take_or_place = 0;
[q5] = Task_Space_Trajectory(p_offset, t00, tff,timesteps,movestep, take_or_place);
q = [q; q5];
%% From REALSE position to GOAL_UP positiont00 = 0;
p_offset = goal_grasp_pos;
take_or_place = 1;
[q6] = Task_Space_Trajectory(p_offset, t00, tff,timesteps,movestep, take_or_place);
q = [q; q6];
%% From GOAL_UP position to HOME position
L = size(q);
p0 = q(L(1),:);
v0 = [0 0 0 0 0 0];
pf = [0, 0, 0, 0, 0, 0];
vf = [0 0 0 0 0 0];
[q7] = LSPBTrajectory(p0, v0, pf, vf, t0, tf, timestep);
% [q7] = CubicTrajectory(p0, v0, pf, vf, t0, tf, timestep);
q8 = [q;q7];

TT = robot.fkine(q8); %得到空间轨迹
p = transl(TT);%轨迹的位移部分
figure('name','Something')
plot3(p(:,1),p(:,2),p(:,3),'LineWidth',3)
robot.plot(q8);

