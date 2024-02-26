function totalDistance = calculateTotalDistance(points, order)
    % calculateTotalDistance Returns the total closed-path distance 
    %                        traversing points in the sequence described
    %                        by order.
    %
    % Input:
    % - points: coordinates of the points to pass by with each row
    %           representing a point.
    % - order: vector describing the seqeunce of traversing the points
    %
    % Output:
    % - totalDistance: the total closed-path distance (assuming Euclidean
    %                  distance)

    arguments (Input)
        points double
        order (1, :) int64 {mustBePositive}
    end

    totalDistance = 0;
    numPoints = size(points, 1);

    if numPoints ~= length(order) && ~all(unique(order) == 1 : numPoints)
        error('Invalid order vector!');
    end

    for i = 1 : length(order)
        currentPoint = points(order(i), :);
        
        % Handle the wrap-around for the last point (closed-path).
        nextPointIndex = mod(i, numPoints) + 1;
        nextPoint = points(order(nextPointIndex), :);

        displacement = nextPoint - currentPoint;
        totalDistance = totalDistance + norm(displacement);
    end
end