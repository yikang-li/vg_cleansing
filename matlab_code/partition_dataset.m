function partition_dataset(data_dir, source_annotation_dir, output_dir)
    % this function is assumed to be placed at parent dir of 'faster_rcnn'
    
    
    if ~exist(output_dir, 'dir')
        mkdir(output_dir)
    end
    
    output_data_dir_train = fullfile(output_dir, 'vg_train_images');
    output_data_dir_val = fullfile(output_dir, 'vg_val_images');
    output_data_dir_test = fullfile(output_dir, 'vg_test_images');
    output_annotation_dir = fullfile(output_dir, 'annotations');
    
    if ~exist(output_data_dir_train, 'dir')
        mkdir(output_data_dir_train);
    end
    
    if ~exist(output_data_dir_val, 'dir')
        mkdir(output_data_dir_val);
    end
    
    if ~exist(output_data_dir_test, 'dir')
        mkdir(output_data_dir_test);
    end
    
    if ~exist(output_annotation_dir, 'dir')
        mkdir(output_annotation_dir);
    end
    
    files = dir(fullfile(source_annotation_dir, '*.mat'));
    for i = 1:1:length(files)
        copyfile(fullfile(source_annotation_dir, files(i).name), ...
            fullfile(output_annotation_dir, files(i).name));
    end
    
    
    %% copy images
    loaded_dataset = load(fullfile(source_annotation_dir, 'vg_relationship_train_ids.mat'), 'image_ids');
    for i = 1:1:length(loaded_dataset.image_ids)
        copyfile(fullfile(data_dir, loaded_dataset.image_ids{i}), ...
            fullfile(output_data_dir_train, loaded_dataset.image_ids{i}));
        if mod(i, 100) == 0
            fprintf('%d images copied, %d left\n', i, length(loaded_dataset.image_ids) - i);
        end
    end
    
    loaded_dataset = load(fullfile(source_annotation_dir, 'vg_relationship_val_ids.mat'), 'image_ids');
    for i = 1:1:length(loaded_dataset.image_ids)
        copyfile(fullfile(data_dir, loaded_dataset.image_ids{i}), ...
            fullfile(output_data_dir_val, loaded_dataset.image_ids{i}));
        if mod(i, 100) == 0
            fprintf('%d images copied, %d left\n', i, length(loaded_dataset.image_ids) - i);
        end
    end
    
end