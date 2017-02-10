function extract_annotation(raw_relationship_path, raw_relationship_mat, output_dir)
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
object_list_path = fullfile(output_dir, 'obj_list.mat');
predicate_list_path = fullfile(output_dir, 'predicate_list.mat');

try 
    fprintf('Try loading processed data: %s\n', raw_relationship_mat);
    load(raw_relationship_mat);
    fprintf('Done loading.\n');
catch
    fprintf('Fail to load the processed data.\nStart now...\n');

    fid = fopen(raw_relationship_path, 'r');
    assert(fid >= 0);
    counter = 0;
    filtered_relationships = struct();
    subject_mask = '%s %*s %*s %*d %*d %*d %*d %*d %*d %*d %*d';
    predicate_mask = '%*s %s %*s %*d %*d %*d %*d %*d %*d %*d %*d';
    object_mask = '%*s %*s %s %*d %*d %*d %*d %*d %*d %*d %*d';
    sub_box_mask = '%*s %*s %*s %d %d %d %d %*d %*d %*d %*d';
    obj_box_mask = '%*s %*s %*s %*d %*d %*d %*d %d %d %d %d';
    tic;
    object_counter = struct();
    predicate_counter = struct();

    %% loading data
    fprintf('-----------------\nLoading raw relationship data\n------------------\n');
    while(1)
        data_line = fgetl(fid);
        if data_line == -1
            fprintf('Done!\n');
            break;
        end
        assert(data_line(1) == '#');
        counter = counter + 1;
        filtered_relationships(counter).id = sscanf(data_line, '# %d');
        filtered_relationships(counter).filename = fgetl(fid);
        filtered_relationships(counter).width = str2double(fgetl(fid));
        filtered_relationships(counter).height = str2double(fgetl(fid));
        relationship_num = str2double(fgetl(fid));
        phrase_items = cell(relationship_num, 1);
        pre_filter_relationship_num = length(phrase_items);
        for i = 1:1:length(phrase_items)
            phrase_items{i} = fgetl(fid);
        end
        phrase_items = unique(phrase_items);
        temp_relationship = {};
        temp_counter = 0;
        for i = 1:length(phrase_items)
            subject = char(sscanf(phrase_items{i}, subject_mask, [1, inf]));
            predicate = char(sscanf(phrase_items{i}, predicate_mask, [1, inf]));
            object = char(sscanf(phrase_items{i}, object_mask, [1, inf]));
            temp_counter = temp_counter +1;
            temp_relationship{temp_counter}.phrase = ...
                {subject, predicate, object};
            temp_relationship{temp_counter}.subBox = ...
                sscanf(phrase_items{i}, sub_box_mask, [1, inf]);
            temp_relationship{temp_counter}.objBox = ...
                sscanf(phrase_items{i}, obj_box_mask, [1, inf]);
            if isfield(object_counter, subject)
                object_counter.(subject) = object_counter.(subject) + 1;
            else
                object_counter.(subject) = 1;
            end
            if isfield(object_counter, object)
                object_counter.(object) = object_counter.(object) + 1;
            else
                object_counter.(object) = 1;
            end
            if isfield(predicate_counter, predicate)
                predicate_counter.(predicate) = predicate_counter.(predicate) + 1;
            else
                predicate_counter.(predicate) = 1;
            end
        end
        if isempty(temp_relationship)
            fprintf('Discard image #%d\n', filtered_relationships(counter).id);
            counter = counter - 1;
            continue;
        end
        temp_relationship = temp_relationship(~cellfun('isempty', temp_relationship));
        filtered_relationships(counter).relationship = temp_relationship;
        if mod(counter, 100) == 0
            fprintf('%d images processed!(%.3fs/pic)\n', counter, toc/counter);
        end
    end
    
    %% counting the frequency of object/predicate labels
    fprintf('-----------------\ncounting the frequency of object/predicate labels\n------------------\n');
    temp_var_objects = struct();
    temp_var_predicates = struct();
    for i = 1:1:length(filtered_relationships)
        for j = 1:1:length(filtered_relationships(i).relationship)
            if ~isfield(temp_var_objects, filtered_relationships(i).relationship{j}.phrase{1})
                temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{1}) = 1;
            else
                temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{1}) ...
                    = temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{1}) + 1;
            end
            if ~isfield(temp_var_predicates, filtered_relationships(i).relationship{j}.phrase{2})
                temp_var_predicates.(filtered_relationships(i).relationship{j}.phrase{2}) = 1;
            else
                temp_var_predicates.(filtered_relationships(i).relationship{j}.phrase{2}) ...
                    = temp_var_predicates.(filtered_relationships(i).relationship{j}.phrase{2}) + 1;
            end
            if ~isfield(temp_var_objects, filtered_relationships(i).relationship{j}.phrase{3})
                temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{3}) = 1;
            else
                temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{3}) ...
                    = temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{3}) + 1;
            end
        end  
    end
    fprintf('Done counting! We have %d objects labels and %d predicate labels.\n',...
            length(fieldnames(temp_var_objects)), length(fieldnames(temp_var_predicates)));
    object_list = sort(fieldnames(temp_var_objects));
    predicate_list = sort(fieldnames(temp_var_predicates));

    %% saving results
    fprintf('Done Loading! Saving results...\n');
    save(raw_relationship_mat, 'filtered_relationships', '-v7.3');
    save(object_list_path, 'object_list');
    save(predicate_list_path, 'predicate_list');
    fprintf('Done!\n');
end

%% partition it to training and validation set
training_percentage = 0.7;
validation_percentage = 0.3;

filename = fullfile(output_dir, 'vg_relationship_');
train_data_path = [filename, 'train.mat'];
train_ids_path = [filename, 'train_ids.mat'];
val_data_path = [filename, 'val.mat'];
val_ids_path = [filename, 'val_ids.mat'];
test_data_path = [filename, 'test.mat'];
test_ids_path = [filename, 'test_ids.mat'];

rng(1); % set the rng seed, in order to keep the partition stable
randomized_index = randperm(length(filtered_relationships));
trainset_end_index = round(length(filtered_relationships) * training_percentage);
train_set = randomized_index(1:trainset_end_index);
val_set = randomized_index((trainset_end_index+1):end);

fprintf('Saving training set: %s\n', train_data_path);
data = filtered_relationships(train_set);
image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
save(train_data_path, 'data', '-v7.3');
save(train_ids_path, 'image_ids');
fprintf('Done saving training set!\n');
fprintf('Saving validation set: %s\n', val_data_path);
data = filtered_relationships(val_set);
image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
save(val_data_path, 'data', '-v7.3');
save(val_ids_path, 'image_ids');
fprintf('Done saving validation training set!\n');

end
