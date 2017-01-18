# vg_cleasing
dataset cleansing for Visual Genome

## Introduction 

Since the relationship dataset from [Visual Genome](http://visualgenome.org/) are extracted from sentences, they look a little messy. Therefore, to make full use of the relationship dataset, I do some dataset cleansing beforehand. 

Some intermediate analyzing results are stored in [Google Sheet](https://docs.google.com/spreadsheets/d/1Exi30Qd1_s3Vmm6rQSp6vgkXeiMPvq2qz5HFVQXhYqY/edit?usp=sharing). Feel free to check it.

All the preprocessing are implemented with Python. For easy interaction, I also use [iPython notebook](https://ipython.org/notebook.html). 

For more information, don't hesitate to [contact me](mailto:allen.li.thu@gmail.com).

## File organization
For further convinience, please organize the dataset as following:

```
- ROOT_PATH (the root dir for the dataset)
	- VG_100K_images (images)
	- vg_cleansing (the python scripts for visual genome cleansing)
		- temp_data (to store some temporary data for dataset cleansing, e.g. object categories of Pascal VOC)
		- models ([optinal] to store the word2vec models)
	- Annotations (annotations for visual relationship)
	- cleansed_data (the output of our cleansing)
```

