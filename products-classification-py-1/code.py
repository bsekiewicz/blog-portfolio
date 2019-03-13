# -*- coding: utf-8 -*-

import pandas as pd
import regex
import string
from nltk import word_tokenize, FreqDist
from nltk.corpus import stopwords


def clean_data(data):
    data = [x.lower() for x in data]
    data = [regex.sub('|\\'.join(string.punctuation), ' ', x) for x in data]
    data = [regex.sub(' ([0-9]+[^ ]{0,} )+', ' ', x) for x in data]
    data = [regex.sub('^[0-9]+[^ ]{0,} ', ' ', x) for x in data]
    data = [regex.sub(' [0-9]+[^ ]{0,}$', ' ', x) for x in data]
    return data


def prepare_freq_table(data):
    freq_table = [word_tokenize(x) for x in data]
    freq_table = [dict(FreqDist(x)) for x in freq_table]
    freq_table = pd.DataFrame.from_dict(freq_table)
    return freq_table


def prepare_perp_summary(v1, v2, term1, term2, perp_threshold=5):
    iloc = sum(v1*v2)
    size = sum(v1) + sum(v2)
    return {'term1': term1,
            'term2': term2,
            'distance': iloc,
            'is_perp': iloc < perp_threshold,
            'size': size,
            'size_term1': sum(v1),
            'size_term2': sum(v2),
            'size_prop12': sum(v1)/sum(v2),
            'size_prop21': sum(v2)/sum(v1)}


def prepare_perp_table(freq_table, sw='polish', rm_low_freq=5, rm_high_freq=5, perp_threshold=5):
    # remove short words
    data = freq_table.iloc[:, freq_table.columns.map(lambda x: len(x) > 2)]
    # remove polish stopwords
    data = data.iloc[:, ~data.columns.isin(stopwords.words(sw))]
    # remove words with low and hight frequency
    data = data.iloc[:, list(data.sum() > rm_low_freq)]
    data = data.iloc[:, list(data.sum() < data.shape[0] - rm_high_freq)]
    # convert NaN to 0, any other number to 1
    data = data.fillna(0)
    for c in data.columns:
        data[c] = data[c].map(lambda x: 1 if x > 0 else 0)

    perp_table = []
    for i in range(data.shape[1]-1):
        for j in range(i+1, data.shape[1]):
            perp_table += [prepare_perp_summary(data[data.columns[i]],
                                                data[data.columns[j]],
                                                data.columns[i],
                                                data.columns[j],
                                                perp_threshold=perp_threshold)]
    perp_table = pd.DataFrame.from_dict(perp_table)
    perp_table = perp_table[perp_table.is_perp]
    return perp_table


def find_perp_set(perp_table, input_data_len, max_proportion=3, bp=0.95):
    # find two perp words with the highest size
    curr_set = perp_table[(perp_table.size_prop12 < max_proportion) & \
                          (perp_table.size_prop21 < max_proportion)].sort_values(by=['size']).iloc[-1, :]
    curr_set = [curr_set.term1, curr_set.term2]
    p = perp_table[perp_table.term1.isin(curr_set) & perp_table.term2.isin(curr_set)]['size'].sum()/((len(curr_set)-1)*input_data_len)
    print('{} and {} get {}% size of set'.format(curr_set[0], curr_set[1], round(p*100, 2)))

    # find others words
    while p < bp:
        tmp_perp_table = perp_table[~(perp_table.term1.isin(curr_set) & perp_table.term2.isin(curr_set))]

        # find perp elements to curr_set
        tt = []
        for c in curr_set:
            t = tmp_perp_table[(tmp_perp_table.term1 == c) | (tmp_perp_table.term2 == c)]
            t = list(set(list(t.term1) + list(t.term2)))
            t.remove(c)
            tt += [t]

        # find perp elements to all words in curr_set
        perp_terms = tt[0]
        for i in range(1, len(tt)):
            perp_terms = list(set(perp_terms) & set(tt[i]))

        tmp_set = tmp_perp_table[(tmp_perp_table.term1.isin(perp_terms) | tmp_perp_table.term2.isin(perp_terms)) &
                                 ((tmp_perp_table.size_prop12 < max_proportion) &
                                  (tmp_perp_table.size_prop21 < max_proportion))].sort_values(by=['size']).iloc[-1, :]
        tmp_set = list(set(perp_terms) & set([tmp_set.term1, tmp_set.term2]))
        new_term = [x for x in tmp_set if x not in curr_set]

        # add this element to curr_set
        curr_set = list(set(curr_set + new_term))

        p = perp_table[perp_table.term1.isin(curr_set) & perp_table.term2.isin(curr_set)]['size'].sum()/((len(curr_set)-1)*input_data_len)
        print('adding {} get {}% size of set'.format(new_term, round(p*100, 2)))

    return curr_set


def test_allegro_sports_shoes():
    df = pd.read_csv("allegro-sports-shoes.csv", sep=';')
    data = list(df.iloc[:, 0])

    data = clean_data(data)
    freq_table = prepare_freq_table(data)
    perp_table = prepare_perp_table(freq_table)
    perp_set = find_perp_set(perp_table, input_data_len=df.shape[0])
    return perp_set

perp_set = test_allegro_sports_shoes()
