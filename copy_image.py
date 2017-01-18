

import nltk
import os
import shutil
print('Loading visual genome data...')
import import_data as imported_data
print('Done loading visual genome data')
print('Total predicate num: ' + str(len(imported_data.predicate_count)));

data_root = '../VG_100K_images'
output_root = '../cleansed_data'
selected_relationships = {}
selected_predicate = [];
predicate_select_thres = 200;

print('Start building annotation dataset...')
for idx, predicate in enumerate(imported_data.predicate_dataset.keys()):
    if imported_data.predicate_count[predicate] > predicate_select_thres:
        selected_predicate.append(predicate)
        print('Predicate: ' + predicate + ' Added! (' + str(imported_data.predicate_count[predicate]) + ' instances)');
        for phrase_id, pair in enumerate(imported_data.predicate_dataset[predicate]['index']):
            relationship_item = {};
            relationship_item['object'] = imported_data.predicate_dataset[predicate]['object'][phrase_id];
            relationship_item['subject'] = imported_data.predicate_dataset[predicate]['subject'][phrase_id];
            relationship_item['sub_box'] = imported_data.predicate_dataset[predicate]['sub_box'][phrase_id];
            relationship_item['obj_box'] = imported_data.predicate_dataset[predicate]['obj_box'][phrase_id];
            relationship_item['predicate'] = predicate;
            if pair[0] in selected_relationships.keys():
                selected_relationships[pair[0]]['relationships'].append(relationship_item)
            else:
                selected_relationships[pair[0]] = {};
                selected_relationships[pair[0]]['relationships'] = [relationship_item];
                selected_relationships[pair[0]]['path'] = \
                    str(imported_data.image_data[pair[0]]['image_id']) + '.jpg'
                selected_relationships[pair[0]]['width'] = imported_data.image_data[pair[0]]['width'];
                selected_relationships[pair[0]]['height'] = imported_data.image_data[pair[0]]['height'];

print('Done building annotation dataset!')
print('Total ' + str(len(selected_predicate)) + ' selected!')


print('Output predicate list!')
f = open('predicate_list.txt', 'w')
predicate2index = {};
for idx, predicate in enumerate(selected_predicate):
    predicate2index[predicate] = idx;
    f.write(str(idx) +' ' + predicate + '\n');
f.close();
print('Done output predicate list')


# print('Preparing words list!')
# f = open('words_list.txt');
# object_list = [];
# for line in f:
#     object_list.append(line)
# f.close();
# print('Done loading words list!')

#  total_image_num = len(selected_relationships)
#  counter = 0;
#  f = open('selected_relationships.txt', 'w');
#  for image in selected_relationships:
#      counter += 1;
#      f.write('# ' + str(image) + '\n');
#      f.write(selected_relationships[image]['path'] + '\n');
#      f.write(str(selected_relationships[image]['height']) + '\n');
#      f.write(str(selected_relationships[image]['width']) + '\n');
#      f.write(str(len(selected_relationships[image]['relationships'])) + '\n');
#      for r in selected_relationships[image]['relationships']:
#          f.write(r['subject'].replace(' ', '_'))
#          f.write(' ' + r['predicate'].replace(' ', '_'))
#          f.write(' ' + r['object'].replace(' ', '_'))
#          for item in r['sub_box']:
#              f.write(' ' + str(item))
#          for item in r['obj_box']:
#              f.write(' ' + str(item))
#          f.write('\n')
#      if counter % 100 == 0:
#          print(str(counter) + ' images copied, ' + str(total_image_num - counter) + ' images left.')
#  f.close()
