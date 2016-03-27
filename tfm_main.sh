#!/bin/bash
#
#
#
clear

if [ "$1" = "--help" ] || [ "$1" = "--?" ]; then
  echo "Este script se encarga de automatizar el procesamiento LDA del fichero de peticiones proveniente del Call Center."
  exit
fi

WORKFILE="IncProcess/Inc*.txt"
DFSRM="hdfs dfs -rm -r -skipTrash"
DFS="hdfs dfs"
MAHOUT="mahout"
WORK_LOCAL_DIR=/jperez/tfm-work-local
WORK_DIR=/jperez/tfm-work

algorithm=( lda clean)
if [ -n "$1" ]; then
  choice=$1
else
  echo "Por favor, seleccione la opción a ejecutar"
  echo "1. ${algorithm[0]} - Algoritmo Latent Dirichlet Allocation" 
  echo "2. ${algorithm[1]} - Limpiar espacio de trabajo"
  read -p "Selecciona la opcion : " choice
fi

echo "La opcion selecciona ha sido ${algorithm[$choice-1]}. Por favor, espere..."
clustertype=${algorithm[$choice-1]}

if [ "x$clustertype" == "xclean" ]; then
  echo "Borrando directorios..."
  rm -rf ${WORK_LOCAL_DIR}
  $DFSRM ${WORK_DIR}
  exit 1
else
  echo "Creando los directorios de trabajo..."
  $DFS -mkdir -p ${WORK_DIR}
  $DFS -mkdir $WORK_DIR/tfm-out
  mkdir -p ${WORK_LOCAL_DIR}/tfm-out
  cp ${WORKFILE} ${WORK_LOCAL_DIR}/tfm-out
  echo "Directorios de trabajo creados en ${WORK_LOCAL_DIR} y ${WORK_DIR}..."
fi

if [ "x$clustertype" != "xclean" ]; then
   if [ ! -e ${WORK_DIR}/tfm-out-seqdir ]; then
      echo "Copiando información a Hadoop..."
      set +e
      $DFS -put ${WORK_LOCAL_DIR}/tfm-out ${WORK_DIR}
      set -e
   
      echo "Convertiendo a Sequence Files..."
      $MAHOUT seqdirectory -i ${WORK_DIR}/tfm-out -o ${WORK_DIR}/tfm-out-seqdir -c UTF-8 -chunk 64 -xm sequential
   fi

   if [ "x$clustertype" == "xlda" ]; then
      echo "Procesando algoritmo LDA..."

      $MAHOUT seq2sparse \
         -i ${WORK_DIR}/tfm-out-seqdir/ \
         -o ${WORK_DIR}/tfm-out-seqdir-sparse-lda -ow --maxDFPercent 85 --namedVector --weight tf \
      && \
      $MAHOUT rowid \
         -i ${WORK_DIR}/tfm-out-seqdir-sparse-lda/tf-vectors \
         -o ${WORK_DIR}/tfm-out-matrix \
      && \
      rm -rf ${WORK_DIR}/tfm-lda ${WORK_DIR}/tfm-lda-topics ${WORK_DIR}/tfm-lda-model \
      && \
      $MAHOUT cvb \
         -i ${WORK_DIR}/tfm-out-matrix/matrix \
         -o ${WORK_DIR}/tfm-lda -k 10 -ow -x 20 -a 1 -e 1 \
         -dict ${WORK_DIR}/tfm-out-seqdir-sparse-lda/dictionary.file-0 \
         -dt ${WORK_DIR}/tfm-lda-topics \
         -mt ${WORK_DIR}/tfm-lda-model \
      && \
      $MAHOUT vectordump \
         -i ${WORK_DIR}/tfm-lda \
         -o ${WORK_LOCAL_DIR}/tfm-lda/topictermdump \
         -vs 10 -p true \
         -d ${WORK_DIR}/tfm-out-seqdir-sparse-lda/dictionary.file-0 \
         -dt sequencefile \
         -sort ${WORK_DIR}/tfm-lda \
         -c csv \
      && \
      $MAHOUT vectordump \
         -i ${WORK_DIR}/tfm-lda-topics/part-m-00000 \
         -o ${WORK_LOCAL_DIR}/tfm-lda/vectordump \
         -vs 10 -p true \
         -d ${WORK_DIR}/tfm-out-seqdir-sparse-lda/dictionary.file-0 \
         -dt sequencefile \
         -sort ${WORK_DIR}/tfm-lda-topics/part-m-00000 \
         -c csv \
      && \
      cat ${WORK_LOCAL_DIR}/tfm-lda/vectordump
   fi
fi
