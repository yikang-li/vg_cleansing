load(fullfile(pwd, 'catagories', 'intersect_obj_pred_list.mat'))
pred_counter = struct();
obj_counter = struct();
for i = 1:length(object_list)
    obj_counter.(object_list{i}) = 0;
end
for i = 1:length(predicate_list)
    pred_counter.(predicate_list{i}) = 0;
end

subset = 'train';

load(fullfile(pwd, 'data_annotation_deps', ['vg_relationship_', subset, '.mat']), 'data');
new_data = struct('id', [], 'filename', [], 'width', [], 'height', [], 'relationship', []);
counter = 0;
for i = 1:1:length(data)
    relationship_is_add = false(length(data(i).relationship), 1);
    for j = 1:1:length(data(i).relationship)
        if isfield(obj_counter, data(i).relationship{j}.phrase{1}) &&...
                isfield(pred_counter, data(i).relationship{j}.phrase{2}) && ...
                isfield(obj_counter, data(i).relationship{j}.phrase{3})
            relationship_is_add(j) = true;
            pred_counter.(data(i).relationship{j}.phrase{2}) = ...
                pred_counter.(data(i).relationship{j}.phrase{2}) + 1;
            obj_counter.(data(i).relationship{j}.phrase{1}) = ...
                obj_counter.(data(i).relationship{j}.phrase{1}) + 1;
            obj_counter.(data(i).relationship{j}.phrase{3}) = ...
                obj_counter.(data(i).relationship{j}.phrase{3}) + 1;
        end
    end
    if any(relationship_is_add)
        counter = counter + 1;
        new_data(counter) = data(i);
        new_data(counter).relationship = new_data(counter).relationship(relationship_is_add);
    end
    
    if mod(i, 100) == 0
        fprintf('%d images processed, %d left. \n', i, length(data) - i);
    end
end

fprintf('Finally, %d images filtered, %d images remaining!\n', length(data) - counter, counter);

data = new_data;
save(fullfile(pwd, 'data_annotation_deps', ['vg_intersect_relationship_', subset, '.mat']), 'data');