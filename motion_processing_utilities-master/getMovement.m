% dTheta is rotation in radians, distance is distance travelled in cm,
% dxdy is delta in x and y directions, and direction is the net direction
% of the distance vector. Also, positive dTheta = rotating clockwise!
% positive dxdy are rightward and forward, respectively
function [distance, rel_direction, dxdy, dTheta] = getMovement(data)
%%data should be in form: (dx dy dx dy;
%                         dr dTheta dPhi 0;
%                        [vM.x vM.y vM.z vM.omega]; ...). We onlyd use the
%                        first row.

unitsPer2PiRotationL = 865.2385; % -765.5977 -929.6576 -877.4440 -982.9513 -877.1354; 952.8061  815.5043  799.9931  876.1295  775.1660 
unitsPer2PiRotationR = 929.7473; % -973.4640 -856.4687 -895.6260 -963.4010 -957.7862; 1.0e+03 * [1.1038    1.0120    0.7676    0.8820    0.8853]


unitsPerRotationL = 958.9967; %average of three complete rotations
unitsPerRotationR = 625.6511; %average of three complete rotations
ballCircumferenceIn = 25.125; %measured in lab
ballCircumferenceCm = ballCircumferenceIn*2.54; %definition
ballRadiusCm  = ballCircumferenceCm/(2*pi); %definition
sensorAngleDegrees = 78; %measured in lab
sensorAngleRadians = sensorAngleDegrees*2*pi/360; %definition


cmPerUnitL = ballCircumferenceCm/unitsPerRotationL;
cmPerUnitR = ballCircumferenceCm/unitsPerRotationR;

dl = squeeze(data(1,2,:))*cmPerUnitL; %convert measurements to units of cm
dr = squeeze(data(1,4,:))*cmPerUnitR; %convert measurements to units of cm

dThetaL = squeeze(data(1,1,:))*2*pi/unitsPer2PiRotationL;
dThetaR = squeeze(data(1,3,:))*2*pi/unitsPer2PiRotationR;

dTheta = (dThetaL + dThetaR)/2;

% next part: we want to project the movement of the mouse onto a plane
% above the surface of the ball.


% Let one axis travel toward the plane of the right sensor, and let movement in this direction be called dy. Let the other
% axis travel orthogonally to this first sensor, and let movement in this
% direction be dx. So, we can decompose each time period as having one rotation around axis dy,
% and one rotation around axis dx. 


dy = dr; %distance toward right sensor

% Next, find the sums of the projections of readings from both axes is the
% the left sensor measurement: this will be the rotation around the dx axis.
% Changes in dy can only be read by the left sensor. 
% dx = dl/ sin(sensorAngleRadians); % cm travelled/time on axis orthogonal to right sensor

% 10:18 pm 27 August 2016
dx = (dl-dr*cos(sensorAngleRadians))/cos(pi/2-sensorAngleRadians);

% compute the magnitude of the velocity vector
distance = sqrt(dx.^2+dy.^2); % cm travelled orthogonally from right sensor

% compute the angle relative to the dx axis
rel_direction = atan2(dy,dx); % angle from axis of left sensor
rel_direction = rel_direction+(-141*2*pi/360); %rotate the axis
rel_direction = wrapTo2Pi(rel_direction);

% now, combine direction with information from rotations

% get dx and dy coordinates from this new coordinate space
dy = sin(rel_direction).*distance;
dx = cos(rel_direction).*distance;
dxdy = [dx dy];
end