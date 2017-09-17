'''
A translation function for Allegheny County GIS data.

'''

    
def filterTags(attrs):
    if not attrs:
        return

    tags = {}
    if attrs['FEATURECOD'] == '210':
        tags['building'] = 'residential'
    elif attrs['FEATURECOD'] == '220':
        tags['building'] = 'commercial'
    else:
        tags['building'] = 'yes'
    
    return tags
