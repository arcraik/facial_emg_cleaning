function [centroids_summary] = Code_getBA(taly_coords,brodmann_pick)

brodmann_areas_files = dir(char("BA_coordinates/" + brodmann_pick + "/"));

centroids_summary = cell(size(taly_coords,1),2);
for i = 1:size(taly_coords,1)
    centroid_taly = taly_coords(i,:);
    centroid_BA_summary = cell(length(brodmann_areas_files)-2, 2);
    for j = 3:length(brodmann_areas_files)
        brodman_coords = readmatrix("BA_coordinates/" + brodmann_pick + "/" + brodmann_areas_files(j).name);
        distances_BA_taly = sqrt((centroid_taly(1)-brodman_coords(:,2)).^2 + (centroid_taly(2)-brodman_coords(:,3)).^2 + (centroid_taly(3)-brodman_coords(:,4)).^2);
        centroid_BA_summary{j-2,1} = brodmann_areas_files(j).name;
        centroid_BA_summary{j-2,2} = min(distances_BA_taly);
    end
    [min_distance, BA_index] = min(cell2mat(centroid_BA_summary(:,2)));
    centroids_summary{i, 1} = centroid_BA_summary{BA_index,1};
    centroids_summary{i, 2} = min_distance;
end