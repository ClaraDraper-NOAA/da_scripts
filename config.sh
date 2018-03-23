echo "running on $machine using $NODES nodes"
## ulimit -s unlimited

export exptname=C128_C384_off
export cores=`expr $NODES \* $corespernode`

# check that value of NODES is consistent with PBS_NP on theia.
if [ "$machine" == 'theia' ]; then
   if [ $PBS_NP -ne $cores ]; then
     echo "NODES = ${NODES} PBS_NP = ${PBS_NP} cores = ${cores}"
     echo "NODES set incorrectly in preamble"
     exit 1
   fi
fi
#export KMP_AFFINITY=disabled

export fg_gfs="run_ens_fv3.csh"
export ensda="enkf_run.csh"
export rungsi='run_gsi_4densvar.sh'
export rungfs='run_fv3.sh' # ensemble forecast

export recenter_anal="true" # recenter enkf analysis around GSI hybrid 4DEnVar analysis
export do_cleanup='true' # if true, create tar files, delete *mem* files.
export controlanal='true' # use gsi hybrid (if false, pure enkf is used)
export controlfcst='true' # if true, run dual-res setup with single high-res control
export cleanup_fg='true'
export cleanup_ensmean='true'
export cleanup_anal='true'
export cleanup_controlanl='true'
export cleanup_observer='true' 
export resubmit='true'
# for 'passive' or 'replay' cycling of control fcst 
# control forecast files have 'control2' suffix, instead of 'control'
# GSI observer will be run on 'control2' forecast
# this is for diagnostic purposes (to get GSI diagnostic files) 
export replay_controlfcst='true'
export replay_run_observer='true' # run observer on replay forecast
export replay_only='false' # replay nanals_replay members, don't run DA
# python script checkdate.py used to check
# YYYYMMDDHH analysis date string to see if
# full ensemble should be saved to HPSS (returns 0 if 
# HPSS save should be done)
export save_hpss_subset="true" # save a subset of data each analysis time to HPSS
export save_hpss="true"
export run_long_fcst="true"  # spawn a longer control forecast at 00 and 12 UTC
export ensmean_restart='true'
export copy_history_files=1 # save pressure level history files (and compute ens mean)

# override values from above for debugging.
#export cleanup_ensmean='false'
#export cleanup_observer='false'
#export cleanup_anal='false'
#export cleanup_controlanl='false'
#export recenter_anal="false"
#export cleanup_fg='false'
#export resubmit='false'
#export do_cleanup='false'
#export save_hpss_subset="false" # save a subset of data each analysis time to HPSS
 
if [ "$machine" == 'wcoss' ]; then
   export basedir=/gpfs/hps2/esrl/gefsrr/noscrub/${USER}
   export datadir=/gpfs/hps2/ptmp/${USER}
   export hsidir="/3year/NCEPDEV/GEFSRR/${USER}/${exptname}"
   export obs_datapath=${basedir}/gdas1bufr
elif [ "$machine" == 'theia' ]; then
   export basedir=/scratch3/BMC/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   export obs_datapath=/scratch3/BMC/gsienkf/whitaker/gdas1bufr
elif [ "$machine" == 'gaea' ]; then
   export basedir=/lustre/f1/${USER}
   export datadir=$basedir
   #export hsidir="/2year/BMC/gsienkf/whitaker/gaea/${exptname}"
   export hsidir="/3year/NCEPDEV/GEFSRR/${USER}/${exptname}"
   export obs_datapath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/gdas1bufr
elif [ "$machine" == 'cori' ]; then
   export basedir=${SCRATCH}
   export datadir=$basedir
   export hsidir="fv3_reanl/${exptname}"
   export obs_datapath=${basedir}/gdas1bufr
else
   echo "machine must be 'wcoss', 'theia', 'gaea' or 'cori', got $machine"
   exit 1
fi
export datapath="${datadir}/${exptname}"
export logdir="${datadir}/logs/${exptname}"
export corrlengthnh=1250
export corrlengthtr=1250
export corrlengthsh=1250
export lnsigcutoffnh=1.25
export lnsigcutofftr=1.25
export lnsigcutoffsh=1.25
export lnsigcutoffpsnh=1.25
export lnsigcutoffpstr=1.25
export lnsigcutoffpssh=1.25
export lnsigcutoffsatnh=1.25  
export lnsigcutoffsattr=1.25  
export lnsigcutoffsatsh=1.25  
export obtimelnh=1.e30       
export obtimeltr=1.e30       
export obtimelsh=1.e30       
export readin_localization=.true.
export massbal_adjust=.false.

# resolution of control and ensmemble.
export RES=128
export RES_CTL=384 

# model physics parameters.
export psautco="0.0008,0.0005"
export prautco="0.00015,0.00015"
#export imp_physics=99 # zhao-carr
export imp_physics=11 # GFDL MP

export NOSAT="NO" # if yes, no radiances assimilated
# model NSST parameters contained within nstf_name in FV3 namelist
# (comment out to get default - no NSST)
# nstf_name(1) : NST_MODEL (NSST Model) : 0 = OFF, 1 = ON but uncoupled, 2 = ON and coupled
export DONST="YES"
export NST_MODEL=2
# nstf_name(2) : NST_SPINUP : 0 = OFF, 1 = ON,
export NST_SPINUP=0 # (will be set to 1 if fg_only=='true')
# nstf_name(3) : NST_RESV (Reserved, NSST Analysis) : 0 = OFF, 1 = ON
export NST_RESV=0
# nstf_name(4,5) : ZSEA1, ZSEA2 the two depths to apply vertical average (bias correction)
export ZSEA1=0
export ZSEA2=0
export NSTINFO=0          # number of elements added in obs. data array (default = 0)
export NST_GSI=3          # default 0: No NST info at all;
                          #         1: Input NST info but not used in GSI;
                          #         2: Input NST info, used in CRTM simulation, no Tr analysis
                          #         3: Input NST info, used in both CRTM simulation and Tr analysis

#export NST_GSI=0          # No NST 

if [ $NST_GSI -gt 0 ]; then export NSTINFO=4; fi
if [ $NOSAT == "YES" ]; then export NST_GSI=0; fi # don't try to do NST in GSI without satellite data

if [ $imp_physics == "11" ]; then
   export ncld=5
   export nwat=6
   export cal_pre=F
   export dnats=1
   export do_sat_adj=".true."
   export random_clds=".false."
   export cnvcld=".false."
else
   export ncld=1
   export nwat=2
   export cal_pre=T
   export dnats=0
fi
export k_split=1
export n_split=6
export hydrostatic=F
if [ $hydrostatic == 'T' ];  then
   export fv3exec='fv3-hydro.exe'
   export consv_te=0
else
   export fv3exec='fv3-nonhydro.exe'
   export consv_te=1
fi
# defaults in exglobal_fcst
if [ $hydrostatic == 'T' ];  then
   export fv3exec='fv3-hydro.exe'
   export hord_mt=10
   export hord_vt=10
   export hord_tm=10
   export hord_dp=-10
   export vtdm4=0.05
   export consv_te=0
else
   export fv3exec='fv3-nonhydro.exe'
   export hord_mt=5
   export hord_vt=5
   export hord_tm=5
   export hord_dp=-5
   export vtdm4=0.06
   export consv_te=1
fi
# GFDL suggests this for imp_physics=11
#if [ $imp_physics -eq 11 ]; then 
#   export hord_mt=6
#   export hord_vt=6
#   export hord_tm=6
#   export hord_dp=-6
#   export nord=2
#   export dddmp=0.1
#   export d4_bg=0.12
#   export vtdm4=0.02
#fi

# stochastic physics parameters.
export SPPT=0.6
## export SPPT=0.8
export SPPT_TSCALE=21600.
export SPPT_LSCALE=500.e3
export SHUM=0.005
export SHUM_TSCALE=21600.
export SHUM_LSCALE=500.e3
export SKEB=0.75
export SKEB_TSCALE=21600.
export SKEB_LSCALE=500.e3
export SKEBNORM=0
export SKEB_NPASS=30
export SKEB_VDOF=5

# resolution dependent model parameters
if [ $RES -eq 384 ]; then
   export JCAP=766
   export LONB=1536
   export LATB=768
   export fv_sg_adj=600
   export dt_atmos=225
   export cdmbgwd="1.0,1.2"
elif [ $RES -eq 192 ]; then
   export JCAP=382 
   export LONB=768   
   export LATB=384  
   export fv_sg_adj=900
   export dt_atmos=450
   export cdmbgwd="0.25,2.5"
elif [ $RES -eq 128 ]; then
   export JCAP=254 
   export LONB=512   
   export LATB=256  
   export fv_sg_adj=1500
   export dt_atmos=720
   export cdmbgwd="0.15,2.75"
elif [ $RES -eq 96 ]; then
   export JCAP=188 
   export LONB=384   
   export LATB=190  
   export fv_sg_adj=1800
   export dt_atmos=900
   export cdmbgwd="0.125,3.0"
else
   echo "model parameters for ensemble resolution C$RES_CTL not set"
   exit 1
fi

if [ $RES_CTL -eq 768 ]; then
   export fv_sg_adj_ctl=600
   export dt_atmos_ctl=120
   export cdmbgwd_ctl="3.5,0.25"
   export psautco_ctl="0.0008,0.0005"
   export prautco_ctl="0.00015,0.00015"
   export LONB_CTL=3072
   export LATB_CTL=1536
elif [ $RES_CTL -eq 384 ]; then
   export fv_sg_adj_ctl=600
   export dt_atmos_ctl=225
   export cdmbgwd_ctl="1.0,1.2"
   export LONB_CTL=1536
   export LATB_CTL=768
elif [ $RES_CTL -eq 192 ]; then
   export fv_sg_adj_ctl=900
   export dt_atmos_ctl=450
   export cdmbgwd_ctl="0.25,2.0"
   export LONB_CTL=768  
   export LATB_CTL=384
elif [ $RES_CTL -eq 96 ]; then
   export fv_sg_adj_ctl=1800
   export dt_atmos_ctl=900
   export cdmbgwd_ctl="0.125,3.0"
   export LONB_CTL=384  
   export LATB_CTL=192
else
   echo "model parameters for control resolution C$RES_CTL not set"
   exit 1
fi
export FHCYC=0 # run global_cycle instead of gcycle inside model

export LONA=$LONB
export LATA=$LATB      

export ANALINC=6

export LEVS=64
export FHMIN=3
export FHMAX=9
export FHOUT=3
FHMAXP1=`expr $FHMAX + 1`
export enkfstatefhrs=`python -c "print range(${FHMIN},${FHMAXP1},${FHOUT})" | cut -f2 -d"[" | cut -f1 -d"]"`
export iaufhrs="3,6,9"
export iau_delthrs="6" # iau_delthrs < 0 turns IAU off
# dump increment in one time step (for debugging)
#export iaufhrs="6"
#export iau_delthrs=0.25
# to turn off iau, use iau_delthrs=-1
#export iau_delthrs=-1

# other model variables set in ${rungfs}
# other gsi variables set in ${rungsi}

export SMOOTHINF=35
export npts=`expr \( $LONA \) \* \( $LATA \)`
export RUN=gdas1 # use gdas obs
export reducedgrid=.false.
export univaroz=.false.

export iassim_order=0

export covinflatemax=1.e2
export covinflatemin=1.0                                            
export analpertwtnh=0.85
export analpertwtsh=0.85
export analpertwttr=0.85
export pseudo_rh=.true.
export use_qsatensmean=.true.
                                                                    
export letkf_flag=.true.
export nobsl_max=10000
export sprd_tol=1.e30
export varqc=.false.
export huber=.false.
export zhuberleft=1.e10
export zhuberright=1.e10

export biasvar=-500
if [ $controlanal == 'false' ] && [ $NOSAT == "NO" ];  then
   export lupd_satbiasc=.true.
   export numiter=4
else
   export lupd_satbiasc=.false.
   export numiter=0
fi
# iterate enkf in obspace for varqc
if [ $varqc == ".true." ]; then
  export numiter=5
fi
# use pre-generated bias files.
#export lupd_satbiasc=.false.
#export numiter=1
#export biascorrdir=<exptdir>


# turn on enkf analog of VarQC
#export sprd_tol=10.
#export varqc=.true.
#export huber=.true.
#export zhuberleft=1.1
#export zhuberright=1.1
                                                                    
export nanals=80                                                    
# replay first 10 members if replay_only "true"
# recenter nanals_replay ensemble around nanals ens mean
export nanals_replay=10 
                                                                    
export paoverpb_thresh=0.99  # set to 1.0 to use all the obs in serial EnKF
export saterrfact=1.0
export deterministic=.true.
export sortinc=.true.
                                                                    
export nitermax=2

export enkfscripts="/lustre/f1/unswept/Gary.Bates/scripts/${exptname}"
export homedir=$enkfscripts
export incdate="${enkfscripts}/incdate.sh"

if [ "$machine" == 'theia' ]; then
   export fv3gfspath=/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/scratch3/BMC/gsienkf/whitaker/gsi/ProdGSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=/scratch3/BMC/gsienkf/whitaker/gsi/branches/EXP-enkflinhx/fix/crtm_2.2.3
   export execdir=${enkfscripts}/exec_${machine}
   export enkfbin=${execdir}/global_enkf
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'gaea' ]; then
# warning - these paths need to be updated on gaea
   export fv3gfspath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/fv3gfs/global_shared.v15.0.0
## export fv3gfspath=${basedir}/fv3gfs/global_shared.v15.0.0
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/ProdGSI
## export gsipath=${basedir}/ProdGSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=${fixgsi}/crtm_v2.2.3
   export execdir=${enkfscripts}/exec_${machine}
   export enkfbin=${execdir}/global_enkf
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'wcoss' ]; then
   export fv3gfspath=/gpfs/hps3/emc/global/noscrub/emc.glopara/svn/fv3gfs
   export gsipath=/gpfs/hps2/esrl/gefsrr/noscrub/Jeffrey.S.Whitaker/gsi/ProdGSI
   export FIXFV3=${fv3gfspath}/fix_fv3
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export fixgsi=${gsipath}/fix
   export fixcrtm=${fixgsi}/crtm_v2.2.3
   export execdir=${enkfscripts}/exec_${machine}
   export enkfbin=${execdir}/global_enkf
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'cori' ]; then
   #export fv3gfspath=/project/projectdirs/refcst/whitaker/fv3_reanl/fv3gfs/global_shared.v15.0.0
   export fv3gfspath=$SCRATCH/global_shared.v15.0.0
   #export gsipath=/project/projectdirs/refcst/whitaker/fv3_reanl/ProdGSI
   export gsipath=$SCRATCH/ProdGSI
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export fixgsi=${gsipath}/fix
   export fixcrtm=${fixgsi}/crtm_v2.2.3
   export execdir=${enkfscripts}/exec_${machine}
   export enkfbin=${execdir}/global_enkf
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
else
   echo "${machine} unsupported machine"
   exit 1
fi

#export ANAVINFO=${enkfscripts}/global_anavinfo.l${LEVS}.txt
#export ANAVINFO_ENKF=${ANAVINFO}
#export HYBENSINFO=${enkfscripts}/global_hybens_info.l${LEVS}.txt
#export CONVINFO=${fixgsi}/global_convinfo.txt
#export OZINFO=${enkfscripts}/global_ozinfo.txt
# set SATINFO in main.csh

#export ANAVINFO=${enkfscripts}/global_anavinfo.l64.txt.clrsky
export ANAVINFO=${enkfscripts}/global_anavinfo.l64.txt
export ANAVINFO_ENKF=${ANAVINFO}
export HYBENSINFO=${fixgsi}/global_hybens_info.l64.txt
export CONVINFO=${enkfscripts}/global_convinfo_oper_fix.txt
export OZINFO=${enkfscripts}/global_ozinfo_oper_fix.txt
#export SATINFO=${enkfscripts}/global_satinfo.txt.clrsky
export SATINFO=${enkfscripts}/global_satinfo.txt
# comment out SATINFO in main.csh

# parameters for hybrid
export beta1_inv=0.125    # 0 means all ensemble, 1 means all 3DVar.
#export beta1_inv=0 # non-hybrid, pure ensemble
# these are only used if readin_localization=F
export s_ens_h=485      # a gaussian e-folding, similar to sqrt(0.15) times Gaspari-Cohn length
export s_ens_v=-0.485   # in lnp units.
# NOTE: most other GSI namelist variables are in ${rungsi}
#export use_prepb_satwnd=.true.
#export aircraft_bc=.false.
export use_prepb_satwnd=.false.
export aircraft_bc=.true.

cd $enkfscripts
echo "run main driver script"
if [ $replay_only == "true" ]; then
csh main_replay.csh
else
csh main2.csh
fi
