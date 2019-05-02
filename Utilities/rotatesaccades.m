function [rotated_startvals, rotated_endvals] = rotatesaccades(startvals,endvals)


startmags = sqrt((startvals(:,1) .^ 2) + (startvals(:,2) .^ 2));
startangles = atan2(startvals(:,2,:),startvals(:,1,:));

endmags = sqrt((endvals(:,1,:) .^ 2) + (endvals(:,2,:) .^ 2));
endangles = atan2(endvals(:,2,:),endvals(:,1,:));

roted_startxs = startmags;
roted_startys = zeros(size(startmags));

roted_endangles = endangles - startangles;

roted_endxs = endmags .* cos(roted_endangles);
roted_endys = endmags .* sin(roted_endangles);

rotated_startvals = [roted_startxs,roted_startys];
rotated_endvals = [roted_endxs, roted_endys];