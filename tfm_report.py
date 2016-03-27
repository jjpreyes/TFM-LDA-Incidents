import operator
import string

#WORK_LOCAL_DIR="/jperez/tfm-work-local/tfm-lda/vectordump"
WORK_LOCAL_DIR="/jperez/tfm-work-local/tfm-lda/topictermdump"
terms = {}

f = open(WORK_LOCAL_DIR, 'rb')
ln = 0
for line in f:
  if len(line.strip()) == 0: continue
  if ln == 0:
    # make {id,term} dictionary for use later
    tn = 0
    for term in line.strip().split(","):
      terms[tn] = term
      tn += 1
  else:
    # Parsear los temas y sus probabilidades
    topic, probs = line.strip().split("\t")
    termProbs = {}
    pn = 0
    for prob in probs.split(","):
      termProbs[terms[pn]] = float(prob)
      pn += 1
    toptermProbs = sorted(termProbs.iteritems(),
      key=operator.itemgetter(1), reverse=True)
    print "Temas: %s" % (topic)
    print "\n".join([(" "*3 + x[0]) for x in toptermProbs[0:10]])
  ln += 1
f.close()
