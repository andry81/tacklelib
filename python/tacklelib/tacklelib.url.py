# pure python module for commands w/o extension modules usage

import sys, re

# portable url module import
if sys.version_info[0] >= 3:
  import urllib.parse as urllib
  from urllib.parse import ParseResult
else:
  import urlparse as urllib
  from urlparse import ParseResult

# DESCRIPTION:
#   Reimplement urlparse/urlnoparse functions to avoid requirement to
#   explicitly import of additional types from the same module (python 3.x):
#     _coerce_args, _noop, urlsplit, _parse_cache, MAX_CACHE_SIZE, scheme_chars
#     and etc
#
def urlparse(*args, **kwargs):
  return urllib.urlparse(*args, **kwargs)

def urlunparse(*args, **kwargs):
  return urllib.urlunparse(*args, **kwargs)

def extract_urls(str, scheme_regex = 'http[s]?'):
  urls = re.findall('(?:' + scheme_regex + ')://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', str.lower())
  urls_arr = []
  for url in urls:
    lastChar = url[-1] # get the last character
    # if the last character is not (^ - not) an alphabet, or a number,
    # or a '/' (some websites may have that. you can add your own ones), then enter IF condition
    if (bool(re.match(r'[^a-zA-Z0-9/]', lastChar))): 
      urls_arr.append(url[:-1]) # stripping last character, no matter what
    else:
      urls_arr.append(url) # else, simply append to new list
  return urls_arr
