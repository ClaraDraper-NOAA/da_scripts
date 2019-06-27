#!/bin/sh
export VERBOSE=YES

date
# run model
export DATOUT=${datapath}/${analdatep1}

export OMP_NUM_THREADS=$fg_threads
export nprocs=`expr $fg_proc \/ $OMP_NUM_THREADS`
countproc=`python -c "import math; print ${corespernode}*int(math.ceil(float(${fg_proc})/${corespernode}))"`
echo "countproc = $countproc"
export mpitaskspernode=`expr $corespernode \/ $OMP_NUM_THREADS`

if [ -z $SLURM_JOB_ID ] && [ $machine == 'theia' ]; then
   hosts=`cat $PBS_NODEFILE`
fi

nhosts=$cores
echo "nhosts = $nhosts"

nhost1=1
nhost=$nhost1

nanal=1

while [ $nanal -le $nanals ]; do
 export charnanal="mem`printf %04i $nanal`"
 export memdir="${memdirprefix}`printf %04i $nanal`"

# check to see if output files already created.
 fhr=$FHMIN
 outfiles="${datapath}/${analdatep1}/${memdir}/INPUT/sfc_data.tile6.nc"
 while [ $fhr -le $FHMAX ]; do
    charhr="fhr`printf %02i $fhr`"
    outfiles="${outfiles} ${datapath}/${analdatep1}/${fileprefix}_${analdatep1}_${charhr}_${charnanal} ${datapath}/${analdatep1}/${bfileprefix}_${analdatep1}_${charhr}_${charnanal}"
    fhr=$((fhr+FHOUT))
 done 
 filemissing='no'
 for outfile in $outfiles; do
   if [ ! -s $outfile ]; then
     echo "${outfile} is missing"
     filemissing='yes'
   else
     echo "${outfile} is OK"
   fi
 done

 node=$nhost
 node_end=$node
 node_end=$((node_end+${countproc}-1))
 if [ $filemissing == 'yes' ]; then
   echo "nanal = ${nanal}, nhost = ${nhost}, node = ${node}, node_end = ${node_end}"
   if [ -z $SLURM_JOB_ID ] && [ $machine == 'theia' ]; then
      export HOSTFILE=${datapath2}/hostfile${node}
      /bin/rm -f $HOSTFILE
      hostindx=$nhost
      while [ $hostindx -le $node_end ]; do
         host1=`echo $hosts[$hostindx]`
         echo ${host1} >> ${HOSTFILE}
         hostindx=$((hostindx+fg_threads))
      done
      echo "HOSTFILE = $HOSTFILE"
      cat $HOSTFILE
   fi
   sh ${enkfscripts}/${rungfs} > ${current_logdir}/run_fg_${memdir}.iter${niter}.out 2>&1 &
   sleep 1
   nhost=$((nhost+countproc))
 else
   echo "skipping nanal = ${nanal}, output files already created"
 fi

 node_end_next=$((node_end+${countproc}-1))
 if [ $node_end -gt $nhosts ] || [ $node_end_next -gt $nhosts ]; then
  echo "$node_end $node_end_next $nhosts"
  echo "waiting at nanal = ${nanal} `date`"
  wait
  nhost=$nhost1
 fi

nanal=$((nanal+1))
done
echo "waiting at nanal = ${nanal} `date`"
wait
echo "all done `date`"

# check to see all files created
echo "checking output files .."`date`

nanal=1
anyfilemissing='no'
while [ $nanal -le $nanals ]; do
    export charnanal="mem`printf %04i $nanal`"
    export memdir="${memdirprefix}`printf %04i $nanal`"
    fhr=$FHMIN
    outfiles="${datapath}/${analdatep1}/${memdir}/INPUT/sfc_data.tile6.nc"
    while [ $fhr -le $FHMAX ]; do
       charhr="fhr`printf %02i $fhr`"
       outfiles="${outfiles} ${datapath}/${analdatep1}/${fileprefix}_${analdatep1}_${charhr}_${charnanal} ${datapath}/${analdatep1}/${bfileprefix}_${analdatep1}_${charhr}_${charnanal}"
       fhr=$((fhr+FHOUT))
    done
    filemissing='no'
    for outfile in $outfiles; do
      ls -l $outfile
      if [ ! -s $outfile ]; then 
        echo "${outfile} is missing"
        filemissing='yes'
        anyfilemissing='yes'
      else
        echo "${outfile} is OK"
      fi
    done 
    nanal=$((nanal+1))
done

if [ $anyfilemissing == 'yes' ]; then
    echo "there are output files missing!"
    exit 1
else
    echo "all output files seem OK"
    date
    exit 0
fi
