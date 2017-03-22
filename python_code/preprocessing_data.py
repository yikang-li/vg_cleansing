# -*- coding: utf-8 -*-
import os
import string
import nltk
import json
import enchant
from nltk.corpus import wordnet as wn
import numpy as np
from collections import Counter
import pdb

current_dir = os.getcwd()
os.chdir('../')


min_relationships_num = 5
min_caption_num = 20
max_caption_num = 50


# Loading data
print 'Loading image data...'
image_data = json.load(open('image_data.json'))
print('image data length: ' + str(len(image_data)))
print 'Loading Relationship data...'
relationships_data = json.load(open('relationships.json'))
print('relationship data length: ' + str(len(relationships_data)))
print 'Loading caption dataset...'
caption_data = json.load(open('region_descriptions_v2.json'))
print('caption dataset length: ' + str(len(caption_data)))

# The subject and object should be noun
en_dict = enchant.Dict("en_US")
nouns = {x.name().split('.', 1)[0] for x in wn.all_synsets('n')}

def words_preprocess(phrase):
    """ preprocess a sentence: lowercase, clean up weird chars, remove punctuation """
    replacements = {
        u'½': u'half',
        u'—': u'-',
        u'™': u'',
        u'¢': u'cent',
        u'ç': u'c',
        u'û': u'u',
        u'é': u'e',
        u'°': u' degree',
        u'è': u'e',
        u'…': u'',
      }
    for k, v in replacements.iteritems():
        phrase = phrase.replace(k, v)
    return phrase.encode('ascii', 'replace').lower().translate(None, string.punctuation)


def build_vocab(data, min_token_instances, verbose=True):
    """ Builds a set that contains the vocab. Filters infrequent tokens. """
    token_counter = Counter()
    for img in data:
        for region in img['regions']:
            if region['tokens'] is not None:
                token_counter.update(region['tokens'])
    vocab = set()
    for token, count in token_counter.iteritems():
        if count >= min_token_instances:
            vocab.add(token)

    if verbose:
        print ('Keeping %d / %d tokens with enough instances'
               % (len(vocab), len(token_counter)))

    if len(vocab) < len(token_counter):
        vocab.add('<UNK>')
        if verbose:
            print('adding special <UNK> token.')
    else:
        if verbose:
            print('no <UNK> token needed.')

    return vocab


def build_vocab_dict(vocab):
    token_to_idx, idx_to_token = {}, {}
    next_idx = 1
    for token in vocab:
        token_to_idx[token] = next_idx
        idx_to_token[next_idx] = token
        next_idx += 1

    return token_to_idx, idx_to_token


def encode_caption(tokens, token_to_idx, max_token_length):
    encoded = np.zeros(max_token_length, dtype=np.int32)
    for i, token in enumerate(tokens):
        if token in token_to_idx:
            encoded[i] = token_to_idx[token]
        else:
            encoded[i] = token_to_idx['<UNK>']
    return encoded


def encode_captions(data, token_to_idx, max_token_length):
    encoded_list = []
    lengths = []
    for img in data:
        for region in img['regions']:
            tokens = region['tokens']
            if tokens is None: continue
            tokens_encoded = encode_caption(tokens, token_to_idx, max_token_length)
            encoded_list.append(tokens_encoded)
            lengths.append(len(tokens))
    return np.vstack(encoded_list), np.asarray(lengths, dtype=np.int32)


relationship_count = 0
predicate_dataset = {}

spelling_error_counter = 0
length_matching_counter = 0
# word_mismatch_counter = 0

data = {}
ignore_small_caption, ignore_out_caption, ignore_short_caption, ignore_long_caption = 0, 0, 0, 0
ignore_image_too_many_or_less = 0
region_counter = 0

# pdb.set_trace()

for d_id, rs in enumerate(relationships_data):
    cap = caption_data[d_id]
    im_item = image_data[d_id]
    print cap['id']
    print rs['id']
    assert cap['id'] == rs['id'], 'The two image does not match'

    regions = []
    for region in cap['regions']:
        region_item = {'phrase': nltk.word_tokenize(
            words_preprocess(region['phrase'])),
            'box': (region['x'], region['y'],
                    region['x'] + region['width'] - 1,
                    region['y'] + region['height'] - 1)}
        if region_item['box'][0] < 0 or region_item['box'][1] < 0 or region_item['box'][2] >= im_item['width'] or \
                region_item['box'][3] >= im_item['height']:
            ignore_out_caption += 1
        elif region_item['box'][3] - region_item['box'][1] < 32 or region_item['box'][2] - region_item['box'][0] < 32:
            ignore_small_caption += 1
        elif len(region_item['phrase']) < 3:
            ignore_short_caption += 1
        elif len(region_item['phrase']) > 10:
            ignore_long_caption += 1
        else:
            regions.append(region_item)
    if len(regions) < min_caption_num or len(regions) > max_caption_num:
        ignore_image_too_many_or_less += 1
        continue

    relationships = []
    # prepare the relationship data
    for r_id, r in enumerate(rs['relationships']):
        try:
            normalized_predicate = '-'.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'v') for x in
                                             words_preprocess(r['predicate']).split()])
            normalized_subject = '-'.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'n') for x in
                                           words_preprocess(r['subject']['name']).split()])
            normalized_object = '-'.join([nltk.stem.WordNetLemmatizer().lemmatize(x, 'n') for x in
                                          words_preprocess(r['object']['name']).split()])

            if (not en_dict.check(normalized_predicate)) or \
                    (not en_dict.check(normalized_subject)) or \
                    (not en_dict.check(normalized_object)):
                spelling_error_counter += 1
                continue

            normalized_predicate = normalized_predicate.lower().replace('-', '_')
            normalized_subject = normalized_subject.lower().replace('-', '_')
            normalized_object = normalized_object.lower().replace('-', '_')

            if len(normalized_predicate) <= 1 or len(normalized_subject) <= 1 or len(normalized_object) <= 1:
                length_matching_counter += 1
                continue

            relationship_item = {
                'object': normalized_object,
                'subject': normalized_subject,
                'sub_box':
                    (r['subject']['x'], r['subject']['y'], r['subject']['x'] + r['subject']['w'] - 1,
                     r['subject']['y'] + r['subject']['h'] - 1),  # index starts from 0
                'obj_box': \
                    (r['object']['x'], r['object']['y'], r['object']['x'] + r['object']['w'] - 1,
                     r['object']['y'] + r['object']['h'] - 1),
                'predicate': normalized_predicate}
            if relationship_item['sub_box'][0] < 0 or relationship_item['sub_box'][1] < 0 \
                    or relationship_item['sub_box'][2] >= im_item['width'] or \
                    relationship_item['sub_box'][3] >= im_item['height'] or \
                    relationship_item['obj_box'][0] < 0 or \
                    relationship_item['obj_box'][1] < 0 or \
                    relationship_item['obj_box'][2] >= im_item['width'] or \
                    relationship_item['obj_box'][3] >= im_item['height']:
                continue
            if relationship_item['sub_box'][3] - relationship_item['sub_box'][1] < 16 or \
                    relationship_item['sub_box'][2] - relationship_item['sub_box'][0] < 16 or \
                    relationship_item['obj_box'][3] - relationship_item['obj_box'][1] < 16 or \
                    relationship_item['obj_box'][3] - relationship_item['obj_box'][1] < 16:
                continue

            relationships.append(relationship_item)
            relationship_count += 1
        except Exception as inst:
            print inst
            print d_id
            print r_id
            # raw_input("Press Enter to continue...")
            print('({}, {}): [{}]-[{}]-[{}]\n'.format(d_id, r_id, r['subject']['name'], r['predicate'], r['object']['name']))
            print('Error: [{}]-[{}]-[{}]\n'.format(r['subject']['name'].encode('ascii', 'replace'), r['predicate'].encode('ascii', 'replace'), r['object']['name'].encode('ascii', 'replace')))
            #  raw_input('Press Enter to continue...')
            pass

    if len(relationships) > min_relationships_num:
        data_item = {
            'path':  str(image_data[d_id]['image_id']) + '.jpg',
            'width': image_data[d_id]['width'],
            'height': image_data[d_id]['height'],
            'image_id': image_data[d_id]['image_id'],
            'relationships': relationships,
            'regions': regions}
        data[d_id] = data_item

    if d_id % 5000 == 0:
        print(str(d_id) + ' images processed, ' + str(relationship_count) + ' relationships')

del relationships_data, caption_data
print('Currently, we have ' + str(relationship_count) + ' relationship tuples and {} images'.format(len(relationships.keys())))
print('Spelling error: {}'.format(spelling_error_counter))
print('Length matching error: {}'.format(length_matching_counter))
# print('word mismatch error: {}'.format(word_mismatch_counter))

os.chdir(current_dir)
