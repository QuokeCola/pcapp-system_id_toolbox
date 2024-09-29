clear;clc;close all;
addpath("../ADXLLib")
s1 = ADXLInterface("COM4",115200);
s1.start_reading()
h = animatedline;
lastindex = 1;
pause(1)
for i = 1:1000
    % pause(0.001)
    addpoints(h,s1.received_data(1,lastindex:end),...
                s1.received_data(2,lastindex:end));
    lastindex = size(s1.received_data,2);
    drawnow
end
s1.stop_reading()
s1.count
