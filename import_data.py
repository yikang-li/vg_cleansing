import os, sys
import nltk
import json, pprint
import enchant # for spelling check
from nltk.corpus import wordnet as wn


os.chdir('/home/ykli/DATA/')
sys.path.append('/home/ykli/DATA/visual_genome_python_driver')


## Loading data
image_data = json.load(open('image_data.json'))
print('image data length: ' + str(len(image_data)))
#objects_data = json.load(open('objects.json'))
#print('objects length: ' + str(len(objects_data)))
#attributes_data = json.load(open('attributes.json'))
#print('attribute data length: ' + str(len(attributes_data)))
relationships_data = json.load(open('relationships.json'))
print('relationship data length: ' + str(len(relationships_data)))

## The subject and object should be none
en_dict = enchant.Dict("en_US")
nouns = {x.name().split('.', 1)[0] for x in wn.all_synsets('n')}



relationship_count = 0
predicate_count = {}
predicate_dataset = {}

spelling_error_counter = 0
length_matching_counter = 0


for d_id,rs in enumerate(relationships_data):
    for r_id,r in enumerate(rs['relationships']):
        try:

            print('({}, {}): [{}]-[{}]-[{}]\n'.format(d_id, r_id, r['subject']['name'], r['predicate'], r['object']['name']))

            normalized_predicate = ' '.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'v') for x in
                                             r['predicate'].strip().encode('ascii').split(' ')])
            normalized_subject = ' '.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'n') for x in
                                           r['subject']['name'].strip().encode('ascii').split(' ')])
            normalized_object = ' '.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'n') for x in
                                           r['object']['name'].strip().encode('ascii').split(' ')])
            if (not en_dict.check(normalized_predicate.replace(' ', '-'))) or \
                    (not en_dict.check(normalized_subject.replace(' ', '-'))) or \
                    (not en_dict.check(normalized_object.replace(' ', '-'))):
                spelling_error_counter += 1
                print('Wrong spelling:{}-{}-{}\n'.format(normalized_subject, normalized_predicate, normalized_object));
                continue

            normalized_predicate = '_'.join(normalized_predicate.lower().split(' '))
            normalized_subject = '_'.join(normalized_subject.lower().split(' '))
            normalized_object = '_'.join(normalized_object.lower().split(' '))

            if len(normalized_predicate) <= 1 or len(normalized_subject) <=1 or len(normalized_object) <=1:
                length_matching_counter += 1
                print('length not matched:{}-{}-{}\n'.format(r['subject']['name'], r['predicate'], r['object']['name']));
                continue
            #  if normalized_object not in nouns or normalized_subject not in nouns:
            #      print('Subject or Object no in Nouns:{}-{}-{}\n'.format(r['subject']['name'], r['predicate'], r['object']['name']));
            #      continue
            if normalized_predicate in predicate_count.keys():
                predicate_count[normalized_predicate]+=1;
                predicate_dataset[normalized_predicate]['index'].append((d_id, r_id))
                predicate_dataset[normalized_predicate]['subject'].append(normalized_subject);
                predicate_dataset[normalized_predicate]['object'].append(normalized_object);
                predicate_dataset[normalized_predicate]['sub_box'].append( \
                    (r['subject']['x'], r['subject']['y'], r['subject']['x'] + r['subject']['w'], \
                     r['subject']['y'] + r['subject']['h']));
                predicate_dataset[normalized_predicate]['obj_box'].append( \
                    (r['object']['x'], r['object']['y'], r['object']['x'] + r['object']['w'], \
                     r['object']['y'] + r['object']['h']));
            else :
                predicate_count[normalized_predicate] = 1;
                predicate_dataset[normalized_predicate] = {};
                predicate_dataset[normalized_predicate]['index'] = [(d_id, r_id)]
                predicate_dataset[normalized_predicate]['subject'] = [normalized_subject];
                predicate_dataset[normalized_predicate]['object'] = [normalized_object];
                predicate_dataset[normalized_predicate]['sub_box'] = [\
                    (r['subject']['x'], r['subject']['y'], r['subject']['x'] + r['subject']['w'], \
                     r['subject']['y'] + r['subject']['h'])];
                predicate_dataset[normalized_predicate]['obj_box'] = [\
                    (r['object']['x'], r['object']['y'], r['object']['x'] + r['object']['w'], \
                     r['object']['y'] + r['object']['h'])];

            relationship_count += 1
        except:
            raw_input('Press Enter to continue...')
            pass
    if d_id%1000 == 0:
        print(str(d_id) + ' images processed, ' + str(relationship_count) + ' relationships');

del relationships_data;
print('Currently, we have ' + str(relationship_count) + ' relationship tuples\n');
print('Currently, we have ' + str(len(predicate_count)) + ' predicates\n');
print('Spelling error: {}\n'.format(spelling_error_counter))
print('Length matching error: {}'.format(length_matching_counter))
