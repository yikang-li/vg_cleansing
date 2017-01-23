% load vg_intersect_relationship_test;
% data_test = data;
% load vg_intersect_relationship_val;
% data_val = data;
% load vg_intersect_relationship_train;
% data_train = data;
% clear data;

data_dir = fullfile(pwd, 'VG_100K_images');

%% settings 
output_dir = fullfile(pwd, '..', 'visual_genome_intersect');
% if ~exist(output_dir, 'dir')
%     mkdir(output_dir);
% end
% all_data = cat(1, data_test', data_val', data_train');


%% partition it to training and validation set
training_percentage = 0.7;
validation_percentage = 0.1;
% test_percentage = 0.2;

filename = fullfile(output_dir, 'annotations', 'vg_relationship_');
train_data_path = [filename, 'train.mat'];
train_ids_path = [filename, 'train_ids.mat'];
val_data_path = [filename, 'val.mat'];
val_ids_path = [filename, 'val_ids.mat'];
test_data_path = [filename, 'test.mat'];
test_ids_path = [filename, 'test_ids.mat'];

% rng(1); % set the rng seed, in order to keep the partition stable
% randomized_index = randperm(length(all_data));
% trainset_end_index = round(length(all_data) * training_percentage);
% valset_end_index = round(length(all_data) * (training_percentage + validation_percentage));
% train_set = randomized_index(1:trainset_end_index);
% val_set = randomized_index((trainset_end_index+1):(valset_end_index));
% test_set = randomized_index((valset_end_index+1):end);
% 
% fprintf('Saving training set: %s\n', train_data_path);
% data = all_data(train_set);
% image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
% save(train_data_path, 'data', '-v7.3');
% save(train_ids_path, 'image_ids');
% fprintf('Done saving training set!\n');
% fprintf('Saving validation set: %s\n', val_data_path);
% data = all_data(val_set);
% image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
% save(val_data_path, 'data', '-v7.3');
% save(val_ids_path, 'image_ids');
% fprintf('Done validation training set!\n');
% fprintf('Saving testing set: %s\n', test_data_path);
% data = all_data(test_set);
% image_ids = arrayfun(@(x) x.filename, data, 'UniformOutput', false);
% save(test_data_path, 'data', '-v7.3');
% save(test_ids_path, 'image_ids');
% fprintf('Done saving testing set!\n');


%% copy the images

output_data_dir_train = fullfile(output_dir, 'vg_train_images');
loaded_dataset = load(train_ids_path);
mkdir(output_data_dir_train);
for i = 1:1:length(loaded_dataset.image_ids)
    copyfile(fullfile(data_dir, loaded_dataset.image_ids{i}), ...
            fullfile(output_data_dir_train, loaded_dataset.image_ids{i}));
        if mod(i, 100) == 0
            fprintf('%d images copied, %d left\n', i, length(loaded_dataset.image_ids) - i);
        end
end


output_data_dir_val = fullfile(output_dir, 'vg_val_images');
loaded_dataset = load(val_ids_path);
mkdir(output_data_dir_val);
for i = 1:1:length(loaded_dataset.image_ids)
    copyfile(fullfile(data_dir, loaded_dataset.image_ids{i}), ...
            fullfile(output_data_dir_val, loaded_dataset.image_ids{i}));
        if mod(i, 100) == 0
            fprintf('%d images copied, %d left\n', i, length(loaded_dataset.image_ids) - i);
        end
end


output_data_dir_test = fullfile(output_dir, 'vg_test_images');
loaded_dataset = load(test_ids_path);
mkdir(output_data_dir_test);
for i = 1:1:length(loaded_dataset.image_ids)
    copyfile(fullfile(data_dir, loaded_dataset.image_ids{i}), ...
            fullfile(output_data_dir_test, loaded_dataset.image_ids{i}));
        if mod(i, 100) == 0
            fprintf('%d images copied, %d left\n', i, length(loaded_dataset.image_ids) - i);
        end
end
