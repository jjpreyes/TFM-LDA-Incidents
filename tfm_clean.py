import nltk
import os
import os.path
import string
import re
import unicodedata

INPUTDIR  = "Inc"
OUTPUTDIR = "IncProcess"

STOPWORDS = nltk.corpus.stopwords.words('spanish')
PUNCTUATIONS = list(string.punctuation)
EXCLUTIONS = ['_','#','@','&','www','ip','luis','otrs','cibercentro','fax','interno','ping','org','=','juan','jose','manuel','estimado']

def textify(s):
  sentences = nltk.sent_tokenize(s)
  words = []
  for sentence in sentences:
    ws = nltk.word_tokenize(sentence)
    for w in ws:
      if ('_' not in w) and ('#' not in w) and ('@' not in w) and ('&' not in w) and ('otrs' not in w) and ('rigs' not in w) and ('cibercentro' not in w) and ('ping' not in w) and ('org' not in w) and ('=' not in w):  
         if (len(w) > 4) and (len(w) <= 14):
            if w.decode('utf-8') in STOPWORDS: continue
            if w.replace(",", "").replace(".", "").isdigit(): continue
            if w not in PUNCTUATIONS:
               words.append(w)
  return " ".join(x for x in words)

# build parser for each content type to extract title and body
for file in os.listdir(INPUTDIR):
  print "Parseando el fichero: %s" % (file)
  fin = open(os.path.join(INPUTDIR, file), 'rb')
  ofn = OUTPUTDIR + "/" + file
  fout = open(ofn, 'wb')
  try:
     for line in fin:
        for x in line.strip().split("\n"):
           fout.write("%s\n" % (textify(x)))
  except ValueError as e:
     print "ERROR: ", e
     continue
  fout.close()
  fin.close()
