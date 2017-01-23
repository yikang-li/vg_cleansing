
raw_relationship_path = fullfile('output', 'relationship_with_specific_predicate_300_500.txt');
raw_relationship_mat = fullfile('output', 'vg_relationship_data_google_dense.mat');
annotations_dir = '../data_annotation_vg_small';
data_dir = '../VG_100K_images';
new_dataset_dir = '../extracted_dataset/vg_small';

fprintf('============ convert annotation ========\n');
extract_annotation(raw_relationship_path, raw_relationship_mat, annotations_dir);
fprintf('========================================\n\n');

fprintf('========= Partition the dataset ========\n');
partition_dataset(data_dir, annotations_dir, new_dataset_dir)
fprintf('========================================\n');
