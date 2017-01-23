
raw_relationship_path = 'selected_relationships_google.txt';
output_dir = './data_annotation_google_dense';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
word_vec_phrase_path = fullfile('word_vec', 'word_vectors', 'word_vec_google_pretrain.mat');
output_path = 'vg_relationship_data_google_dense.mat';
object_list_path = fullfile(output_dir, 'obj_list.mat');
predicate_list_path = fullfile(output_dir, 'predicate_list.mat');

try 
    fprintf('Try loading processed data: %s\n', output_path);
    load(output_path);
    fprintf('Done loading.\n');
catch
    fprintf('Fail to load the processed data.\nStart now...\n');
    load(word_vec_phrase_path, 'word_vec');
    fprintf('Done loading word2vec model\n');

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
            if isfield(word_vec, subject) && isfield(word_vec, predicate) && isfield(word_vec, object)
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

    potential_object_names = fieldnames(temp_var_objects);
    potential_predicate_names = fieldnames(temp_var_predicates);
    % potential_object_counter = cellfun(@(x) temp_var_objects.(x), potential_object_names, ...
    %     'UniformOutput', true);
    for i = 1:1:length(potential_object_names)
        if temp_var_objects.(potential_object_names{i}) < 5
            temp_var_objects = rmfield(temp_var_objects, potential_object_names{i});
        end
    end
    for i = 1:1:length(potential_predicate_names)
        if temp_var_predicates.(potential_predicate_names{i}) < 3
            temp_var_predicates = rmfield(temp_var_predicates, potential_predicate_names{i});
        end
    end

    fprintf('Done counting! We have %d objects labels and %d predicate labels.\n',...
            length(fieldnames(temp_var_objects)), length(fieldnames(temp_var_predicates)));

    % determine final relationships
    fprintf('Filtering the labels iteratively...\n');
    for local_index = 1:1:10
        potential_object_names = fieldnames(temp_var_objects);
        potential_predicate_names = fieldnames(temp_var_predicates);
        old_label_num = length(fieldnames(temp_var_objects));
        fprintf('Iter #%d...\n', local_index);
        for i = 1:1:length(fieldnames(temp_var_objects))
            temp_var_objects.(potential_object_names{i}) = 0;
        end
        for i = 1:1:length(fieldnames(temp_var_predicates))
            temp_var_predicates.(potential_predicate_names{i}) = 0;
        end
        for i = 1:1:length(filtered_relationships)
            for j = 1:1:length(filtered_relationships(i).relationship)
                try
                    new_value_1 = temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{1}) + 1;
                    new_value_2 = temp_var_predicates.(filtered_relationships(i).relationship{j}.phrase{2}) + 1;
                    new_value_3 = temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{3}) + 1;
                    temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{1}) = new_value_1;
                    temp_var_predicates.(filtered_relationships(i).relationship{j}.phrase{2})  = new_value_2;
                    temp_var_objects.(filtered_relationships(i).relationship{j}.phrase{3}) = new_value_3;
                catch

                end
            end  
        end
        potential_object_names = fieldnames(temp_var_objects);
        potential_predicate_names = fieldnames(temp_var_predicates);
        % potential_object_counter = cellfun(@(x) temp_var_objects.(x), potential_object_names, ...
        %     'UniformOutput', true);
        for i = 1:1:length(potential_object_names)
            if temp_var_objects.(potential_object_names{i}) < 5
                temp_var_objects = rmfield(temp_var_objects, potential_object_names{i});
            end
        end
        for i = 1:1:length(potential_predicate_names)
            if temp_var_predicates.(potential_predicate_names{i}) < 3
                temp_var_predicates = rmfield(temp_var_predicates, potential_predicate_names{i});
            end
        end

        object_list = sort(fieldnames(temp_var_objects));
        predicate_list = sort(fieldnames(temp_var_predicates));
        fprintf('Iter #%d done!\nwe have %d objects labels and %d predicate labels.\n',...
            local_index, length(object_list), length(predicate_list));
        if length(object_list) == old_label_num
            fprintf('Label number doesn''t change any more! Stop.\n');
            break;
        end
    end
    fprintf('Finally, we have %d objects labels and %d predicate labels\n', ...
        length(object_list), length(predicate_list));
    fprintf('Saving results...\n');

    %% Determine the final relationships data
    i = 0;
    while(i < length(filtered_relationships))
        i = i + 1;
        for j = 1:1:length(filtered_relationships(i).relationship)
            if ~isfield(temp_var_objects, filtered_relationships(i).relationship{j}.phrase{1}) ...
                    || ~isfield(temp_var_predicates, filtered_relationships(i).relationship{j}.phrase{2}) ...
                    || ~isfield(temp_var_objects, filtered_relationships(i).relationship{j}.phrase{3})
                filtered_relationships(i).relationship{j} = [];
            end
        end  
        filtered_relationships(i).relationship = filtered_relationships(i).relationship(~cellfun('isempty', filtered_relationships(i).relationship));
        if isempty(filtered_relationships(i).relationship)
            fprintf('Discard image #%d\n', filtered_relationships(i).id);
            filtered_relationships(i) = [];
            i = i - 1;
            continue;
        end
    end


    %% saving results
    save(output_path, 'filtered_relationships', '-v7.3');
    save(object_list_path, 'object_list');
    save(predicate_list_path, 'predicate_list');
    fprintf('Done!\n');
end


%% saving the corresponding word_vec
fprintf('Saving word vectors...\n');
if ~exist('word_vec', 'var')
    load(word_vec_phrase_path, 'word_vec');
end
load(object_list_path, 'object_list');
load(predicate_list_path, 'predicate_list');
obj2vec = zeros(length(object_list), 300);
pred2vec = zeros(length(predicate_list), 300);
for i = 1:1:length(object_list)
    obj2vec(i, :) = word_vec.(object_list{i});
end
for i = 1:1:length(predicate_list)
    pred2vec(i, :) = word_vec.(predicate_list{i});
end
save(fullfile(output_dir, 'obj2vec.mat'), 'obj2vec');
save(fullfile(output_dir, 'pred2vec.mat'), 'pred2vec');
fprintf('Done saving word vectors!\n');

%% partition it to training and validation set
training_percentage = 0.7;
validation_percentage = 0.1;
% test_percentage = 0.2;

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
valset_end_index = round(length(filtered_relationships) * (training_percentage + validation_percentage));
train_set = randomized_index(1:trainset_end_index);
val_set = randomized_index((trainset_end_index+1):(valset_end_index));
test_set = randomized_index((valset_end_index+1):end);

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
fprintf('Done validation training set!\n');
fprintf('Saving testing set: %s\n', test_data_path);
data = filtered_relationships(test_set);
image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
save(test_data_path, 'data', '-v7.3');
save(test_ids_path, 'image_ids');
fprintf('Done saving testing set!\n');

