function idx = findNearest(array, value)
    % Compute the absolute difference between each element in the array and the specified value
    diff = abs(array - value);
    
    % Find the index of the minimum value in the difference array
    [~, idx] = min(diff);
end
