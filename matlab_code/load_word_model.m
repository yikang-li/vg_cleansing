function load_word_model(model_path, output_path)
    if ~exist('model_path', 'var')
        model_path = fullfile(pwd, 'word2vec', 'models/GoogleNews-vectors-negative300.txt');
    end
    
    if ~exist('output_path', 'var')
        output_path = 'word_vectors/word_vec.mat';
    end
    
    fid = fopen(model_path, 'r+');
    % model_size = fscanf(fid, '%d %d');
    model_dim = 300;
    % word_num = model_size(1);
    word_vec = struct();

    read_word = '%s';
    read_vec = '%*s';
    for i = 1:1:model_dim
        read_word = [read_word, ' %*f']; %#ok<AGROW>
        read_vec = [read_vec, ' %f']; %#ok<AGROW>
    end

    while(1)
        item = fgetl(fid);
        if item == -1
            break;
        end
        word = sscanf(item, read_word, [1, inf]);
        word = lower(char(word));
        vec = sscanf(item, read_vec, [1, inf]);
        try
            word_vec.(word) = vec;
        catch
    %         warning('Unrecognized symbol: %s', char(word));
        end

    end

    save(output_path, 'word_vec', '-v7.3');
end
