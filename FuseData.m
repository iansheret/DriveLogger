function FuseData(filename)
% Fuse GPS and inertial data in logged file

% Copyright 2013 Ian Sheret
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
% http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

% Load file
data = dlmread(filename);
isIns = data(:,1)==0;
isLoc = data(:,1)==1;
insData = data(isIns, 2:6)';
locData = data(isLoc,2:end)';

% Discard location data where the accuracy is poor
accuracy = locData(6,:);
isOk = accuracy < 50.0;
locData = locData(:,isOk);

% Calculate position in the E frame (North, East, Down)
rEarth = 6371e3;
posE = [(locData(2,:) - locData(2,1))*rEarth; (locData(3,:)-locData(3,1))*rEarth*cos(locData(2,1))];

% Get timestamps, referenced to the start of the journey
t0 = locData(1,1);
t = locData(1,:) - t0;

% Show the overall journey
figure;
plot(posE(2,:), posE(1,:));
hold on
plot(posE(2,:), posE(1,:), 'r.');
xlabel('Position east (m)');
ylabel('Position north (m)');
axis equal;

% Zoom in on the traffic lights
figure;
plot(posE(2,:), posE(1,:));
hold on
plot(posE(2,:), posE(1,:), 'r.');
xlabel('Position east (m)');
ylabel('Position north (m)');
xlim([-719.3472 -403.0515]);
ylim([10.2439, 259.7093]);
showIdxs = (271:10:321);
j = showIdxs(1);
text(posE(2,j)-15, posE(1,j)+10, ['t = ', num2str(round(t(j)))]);
plot(posE(2,j), posE(1,j), 'b.');
for i=2:length(showIdxs)
    j = showIdxs(i);
    text(posE(2,j)-5, posE(1,j)+10, num2str(round(t(j))));
    plot(posE(2,j), posE(1,j), 'b.');
end    

% Show the GPS speed through this section
figure
plot(t, locData(4,:));
xlim([235,325]);
xlabel('Time since journey start (s)');
ylabel('GPS speed (m/s)');

% Get estimate of the acceleration by differentiating the GPS data
speedDiff = diff(locData(4,:)) ./ diff(locData(1,:));
tDiff = (locData(1,1:end-1) + locData(1,2:end)) / 2 - t0;

% Smooth using a gaussian kernal
sigma = 1.2;
hw = 3;
kern = exp(-(-hw:hw).^2/(2*(sigma.^2)));
kern = kern/sum(kern);
speedDiffSmoothed = filter(kern, 1, speedDiff);
tDiffSmoothed = tDiff - hw;

% Plot
figure
xlim([235,325]);
xlabel('Time since journey start (s)');
ylabel('GPS based longitudinal acceleration (m/s^2)');
hpatch(-0.5, 0.5, [0.95, 0.95, 0.95]);
hpatch(-3, -0.5, [0.95, 0.85, 0.85]);
hpatch( 0.5, 3, [0.85, 0.95, 0.85]);
set(gca,'Layer','top')
hold on;
plot(tDiffSmoothed, speedDiffSmoothed);
text(240, 1.7, 'Acceleration', 'Fontsize', 20);
text(240, -1.7, 'Braking', 'Fontsize', 20);

% Resample the ins data onto a regular grid
deltaT = diff(insData(1,:));
dt = median(deltaT);
deltaIdx = round(deltaT / dt);
idx = [1, 1 + cumsum(deltaIdx)];
insAccE = interp1(idx, insData(2:4,:)', idx(1):idx(end), 'spline')';
angRateEz = interp1(idx, insData(5,:)', idx(1):idx(end), 'spline')';
tIns = interp1(idx, insData(1,:)', idx(1):idx(end), 'spline') - t0;

% Smooth
sigma = 10;
hw = 20;
kern = exp(-(-hw:hw).^2/(2*(sigma.^2)));
kern = kern/sum(kern);
smoothedAngRateEz = filter(kern, 1, angRateEz);
tInsSmoothed = tIns - hw*dt;

% Get estimated transverse acceleration
speed = interp1(t, locData(4,:), tInsSmoothed)';
transverseAcc = speed.*smoothedAngRateEz;

% Plot
figure;
plot(tInsSmoothed, transverseAcc);
xlim([235,325]);
xlabel('Time since journey start (s)');
ylabel('Transverse acceleration (m/s^2)');

end


function hpatch(a,b,color)

boxx = [1, 0, 0, 1, 1; ...
        0, 1, 1, 0, 0]'*xlim';
 
boxy = [1, 1, 0, 0, 1; ...
        0, 0, 1, 1, 0]'*[a;b];
 
patch(boxx, boxy, color, 'EdgeColor', 'none');

end