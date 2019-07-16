clear all

% SANS Kalman  Filter in
% "An integrated INS/GPS navigation system for small AUVs using an asynchronous Kalman filter"
% By Glenn  Hernandez
% 8 May 98
% edited from pdf by nicholasferguson@wingarch.com 2019

% Number of minutes  for simulated  run
minutes =  1;

% Define the  resolution of the simulation  here
delta_t =  .01;  % For 100 Hz resolution

% Number of  samples
samples =  1/delta_t * 2 * minutes;   % Gives 60000  samples at delta_t = .01 seconds

% Time Constants
tau_1 = 60;     % seconds for velocity
tau_2 = 60;     % seconds for GPS
tau_3 = 3600;  % seconds for ocean  current

% Process Noise  Vector
wl = randn(1, samples)
w2 = randn(1, samples)
w3 = randn(1, samples);
w4 = randn(1, samples);
w5 = 600 * randn(1, samples);  % Gives  a GPS standard  deviation of  3 m
w6 = 600 * randn(1,samples);  % Gives  a GPS standard  deviation of  3 m
w7 = zeros(1,samples);        % No white  noise input  for x7
w8 = zeros(1,samples);        % No white  noise input  for x8
w = [wl;w2;w3;w4;w5;w6;w7;w8];

% Measurement Noise  Vector
vl = randn(1,samples);
v2 = randn(1,samples) ;
v3 = randn(1,samples) ;
v4 = randn(1,samples) ;
v_0 = [vl;v2];         % Noise vector without  GPS input
v_l = [vl;v2;v3;v4] ;  % Noise vector with  GPS input

% Generate GPS Sampling
gps_flag = zeros(samples,1);

for g = 1:1/delta_t: samples  % Need at  least .01 seconds  between GPS fixes

j = rand;  % Normalized  random generator  between   and  1
  if j < .5
    gps_flag(g)  = 0;  % No GPS Signal Available
  else
    gps_flag(g)  = 1;  % GPS Signal Available
  end
end

'gps flags generated'

% System Matrix
A = [1/tau_1	0		 0		  0		     0		   0		 0	 0;	
      0         1/tau_1  0		  0		     0		   0		 0	  0;	
      0         0        1/tau_2  0		     0		   0		 0	  0;
      0         0        0        1/tau_2    0		   0		 0	  0;
      0         0        0        0          1/tau_3   0	     0	  0;
      0         0  	     0		  0		     0         1/tau_3   0	  0;
       1/tau_1  0        1/tau_2  0		     0	       0	     0	  0;
       0        1/tau_1  0        1/tau_2    0         0         0	  0];

% Input Noise  Matrix
B = [wl;w2 ;w3;w4;w5;w6;w7;w8 ];

% Output Matrix
C = eye(8);

D = zeros(8,samples);

% State Transition  Matrix
phi = [exp(-delta_t/tau_1) 	0 0 0 0 0 0 0;
       0  exp(-delta_t/tau_1) 0 0 0 0 0 0;
       0 0  exp(-delta_t/tau_2) 0 0 0 0 0;
       0 0 0  exp(-delta_t/tau_2) 0 0 0 0;
	   0 0 0 0  exp(-delta_t/tau_3) 0 0 0;
	   0 0 0 0 0  exp(-delta_t/tau_3) 0  0;
       tau_1*(1-exp(-delta_t/tau_1)) 0 tau_2*(1-exp(-delta_t/tau_2)) 0 0 0 0 0; 
       0  tau_1*(1-exp(-delta_t/tau_1)) 0  tau_2*(1-exp(-delta_t/tau_2)) 0 0 0 0];

Q =  [((1/(2*tau_1) )*(1-exp((-2*delta_t)/tau_1))) 0 0 0 0 0 0 0;
          0 ((1/(2*tau_1) )*(1-exp((-2*delta_t)/tau_1))) 0 0 0 0 0 0;
          0 0 ((1/(2*tau_2))*(1-exp((-2*delta_t)/tau_2))) 0 0 0 0 0;
          0 0 0 ((1/(2*tau_2))*(1-exp((-2*delta_t)/tau_2))) 0 0 0 0;
          0 0 0 0 ((1/(2*tau_3))*(1-exp((-2*delta_t)/tau_3))) 0 0 0;
          0 0 0 0 0 ((1/(2*tau_3))*(1-exp((-2*delta_t)/tau_3))) 0 0;
		  0 0 0 0 0							0				    0 0;
          0 0 0 0 0                         0                   0 0];

% Generate Process  Noise Vectors
process_noise  = sqrt(Q)*w;

% Error Covariance  Matrix
R_0 = diag([.5  .5]);      % Without  GPS signal
R_l = diag([.5  .5 0 0]);    % With  GPS signal

  

% Generate Measurement  Noise Vectors
sensor_noise_0  = sqrt(R_0) * v_0;   % Without GPS signal
sensor_noise_1  = sqrt(R_l) * v_l;   % With GPS signal

% Initial x_hat_minus
x_hat_minus (8,samples) = zeros;

% Initial x_hat_plus
x_hat_plus (8,samples) = zeros;

% Initial State  Vector
x(8,samples)  = zeros;

% Initial z as globals for graphing
z_gps = zeros(1,samples); 
z_gps1 = zeros(1,samples); 
z_gps2 = zeros(1,samples); 
z_gps3 = zeros(1,samples); 
z_gps4 = zeros(1,samples); 
z_gps_time = zeros(1,samples); 
% Initial Error  Covariance Matrix
P_minus =  [0.5 0 0 0 0 0 0 0;
             0 0.5 0 0 0 0 0 0;
             0 0 1 0 0 0 0 0;
             0 0 0 1 0 0 0 0;
             0 0 0 0 3 0 0 0;
             0 0 0 0 0 3 0 0;
             0 0 0 0 0 0 5 0;
             0 0 0 0 0 0 0 5];

time_index_a =1;    % Initial Index  forMeasurement  Vector without  GPS
time_index_b =1;    % Initial Index  forMeasurement  Vector with GPS

'Beginning Kalman  Loops'

% Begin Simulation
for k = 2:samples

% Generate State Vectors  and Measurement  Vectors
x(:,k) = phi * x(:,k-1)  + process_noise( :,k-1);

  % Kalman loop with  out GPS signal
  if gps_flag(k)  ==  0
        H =  [1 0 0 0 0 0 0 0;
             0 1 0 0 0 0 0 0];

        R = diag([.5  .5]);

        sensor_noise_0( :,k) = sqrt(R) * v_0(:,k);

        z_vell(time_index_a) = H(1,:) * x(:,k)  + sensor_noise_0(1,k)
        z_vel2(time_index_a) = H(2,:) * x(:,k)  + sensor_noise_0(2,k)

        z_vel_time(time_index_a)  = k * delta_t;

        z_vel =  [z_vell ; z_vel2];

        % Compute Ka1man  Gain
        K = P_minus * H' * inv(H * P_minus * H' + R);

      %  Update Estimate
      x_hat_p1us(:,k) = x_hat_minus(:,k-1)+K*(z_vel(:,time_index_a) - H *x_hat_minus(:,k-1));

      %  Compute Error  Covariance for Updated  Estimate
      P_p1us = (eye(8)- K * H )*P_minus;
      P_p1us = (P_p1us+ P_p1us')/2;

      time_index_a = time_index_a +1; % Increase the  measurement vector  index by  1

   else

      H=   [1 0 0 0 0 0 0 0;
            0 1 0 0 0 0 0 0;
            0 0 0 0 1 0 1 0;
            0 0 0 0 0 1 0 1];

      R =  diag([.5 .5  0 0]);                           

      z_gps1(time_index_b) = H(1,:)* x(:,k)+ sensor_noise_1(1,k);
      z_gps2(time_index_b) = H(2,:)* x(:,k)+ sensor_noise_1(2,k);
      z_gps3(time_index_b) = H(3,:)* x(:,k)+ sensor_noise_1(3,k);
      z_gps4(time_index_b) = H(4,:)* x(:,k)+ sensor_noise_1(4,k);
      z_gps  = [z_gps1  ; z_gps2 ; z_gps3  ; z_gps4];
      z_gps_time(time_index_b) = k * delta_t;

      % Compute  Ka1man Gain
      K =  P_minus * H'  * inv(H * P_minus  * H' + R);

      % Update  Estimate
      x_hat_p1us(:,k) = x_hat_minus(:,k-1)+ K *(z_gps(:,time_index_b) - H *x_hat_minus (:,k-1));

      % Compute  Error Covariance  for Updated Estimate
      P_p1us  = ( eye(8)  -  K  * H ) *  P_minus;
      P_p1us  = ( P_p1us  + P_p1us') / 2;

      time_index_b  = time_index_b  +1; % Increase the measurement vector  index by 1

   end

  pmin( :,:,k)  = P_p1us;  % Save  Matrix for  future ana1ysis

  % Project   Ahead

  x_hat_minus(:,k) =  phi * x_hat_p1us( :,k);
  P_minus  =  phi * P_p1us  * phi'  + Q;
  P_minus  =  ( P_minus  + P_minus') /  2;

  time(k)  =  k * delta_t;   %   Memorize  time index
  
  % what

end

figure(1)
subplot(3,1,1)
plot(time, x(7,:),'b-',time, x_hat_minus(7,:),'r-.',z_gps_time,z_gps3, 'g^')
xlabel('time  (seconds )')
ylabel('position  (meters)')
title('North  Position  vs Time')
axis([0  max(time)  -1.5*max(abs(z_gps3)) 1.5*max(abs(z_gps3))])

subplot(3,1,2)
plot(time,  x(8,:),'b-',time,  x_hat_minus(8,:), 'r-.',z_gps_time,z_gps4,  'g^')
xlabel('time   (seconds)')
ylabel('position  (meters)')
title('East Position  vs  Time')
axis([0  max(time)  -1.5*max(abs(z_gps4) ) 1.5*max(abs(z_gps4))])

subplot(3,1,3)
plot(x_hat_minus(7,:), x_hat_minus(8,:), 'b-')
xlabel('North  Position')
ylabel('East Position')
title('North-East  Position  plot')
axis([-1.5*max(abs(x_hat_minus(7,:)))  1.5*max(abs(x_hat_minus(7,:)))...
      -1.5*max(abs(x_hat_minus(8,:)))  1.5*max(abs(x_hat_minus(8,:)))])

orient tall