hdbdir:hsym`$getenv[`KDBHDB]
filetoload:`:/home/rsketch/EQY_US_ALL_TRADE_20180730.gz // for testing

timeconverter:{"n"$sum 3600000000000 60000000000 1000000000 1*deltas[d*x div/: d]div d:10000000000000 100000000000 1000000000 1}
defaults:`chunksize`partitioncol`partitiontype`compression`gc!(`int$100*2 xexp 20;`ticktime;`date;();0b)
optionalparams:(enlist `hdbtemp) ! enlist `:/home/rsketch/testdb // for testing


// set the schema for each table
tradeparams:defaults,(!) . flip (
         (`headers;`ticktime`exch`sym`cond`size`price`stop`corr`sequence`tradeid`cts`trf`parttime);
         (`types;"JSSSIFBIJICCJ");
         (`tablename;`trade);
         (`separator;enlist"|");
         (`dbdir;hsym hdbdir);             // this parameter is defined in the top level taqloader script
         (`symdir;hsym hdbdir);            // where we enumerate against
         (`dataprocessfunc;{[params;data] `sym`ticktime`exch`cond`size`price`stop`corr`sequence`cts`trf xcols delete from
        (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data) where null ticktime});
         (`date;.z.d)
        );

quoteparams:defaults,(!) . flip (
         (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`rpi`shortsale`utpind`parttime);
         (`types;"JSSFIFISJCC  CCCC  J");
         (`tablename;`quote);
         (`separator;enlist"|");
         (`dbdir;hdbdir);               // this parameter is defined in the top level taqloader script
         (`symdir;hdbdir);              // where we enumerate against
         (`dataprocessfunc;{[params;data]
          `sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`rpi`shortsale`cqsind`utpind`parttime xcols
            update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",cqsind:" " from
             delete from
             (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ timeconverter[ticktime],parttime:params[`date]+ timeconverter[parttime] from data)
            where null ticktime});
         (`date;.z.d)
         );

nbboparams:defaults,(!) . flip (
         (`headers;`ticktime`exch`sym`bid`bidsize`ask`asksize`cond`sequence`bbo`qbbo`cqs`qcond`bbex`bbprice`bbsize`bbmmid`baex`baprice`basize`bammid`luldind`nbboind`parttime);
         (`types;"JSSFIFISJCC  CCCFI*CFI*CC J");
         (`tablename;`nbbo);
         (`separator;enlist"|");
         (`dbdir;hsym`$ .taq22.hdbdir);             // this parameter is defined in the top level taqloader script
         (`symdir;hsym`$ .taq22.hdbdir);            // where we enumerate against
         (`dataprocessfunc;{[params;data] 
	`sym`ticktime`exch`bid`bidsize`ask`asksize`cond`mmid`bidexch`askexch`sequence`bbo`qbbo`corr`cqs`qcond`bbex`bbprice`bbsize`bbmmid`bbmmloc`bbmmdeskloc`baex`baprice`basize`bammid`bammloc`bammdeskloc`luldind`nbboind`parttime xcols 
	// add in blank fields which don't exist any more 
 	update mmid:(count ticktime)#enlist "",bidexch:`,askexch:`,corr:" ",bbmmloc:`,bbmmdeskloc:" ",bammloc:`,bammdeskloc:" " from 
 	   delete from 
	   (update sym:.Q.fu[{` sv `$" " vs string x}each;sym],ticktime:params[`date]+ .taq22.timeconverter[ticktime],parttime:params[`date]+ .taq22.timeconverter[parttime] from data) 
	  where null ticktime});
         (`date;.z.d)
        );

// example use of streaming algorithm
loadfsn:{.Q.fsn[.loader.loaddata[quoteparams,(enlist`filename)!enlist filetoload];filetoload;quoteparams`chunksize]}

// example use of fifo stremaing algorithm for trades table
fifoloader:{[filetype;filetoload;optionalparams]
  
  // define params based on filetype
  params:$[
    filetype=`trade;tradeparams,optionalparams;
    filetype=`quote;quoteparams,optionalparams;
    filetype=`nbbo;nbboparams,optionalparams;
    .lg.e[`fifoloader;(string filetype)," is an unknown or unsupported filetype"]
    ];

  // if quote then partition by letter in the temp hdb
  params[`dbdir]:$[
    filetype=`trade; string params[`hdbtemp],"/",string filetype;
    filetype=`quote; `$ (string params[`hdbtemp]),"/",(string filetype), last -12 _ string filetoload;
    filetype=`nbbo; params[`dbdir];
    .lg.e[`fifoloader;(string filetype), " is an unknown or unsupported file type"]
    ];

  // make fifo with PID attached
  fifo:"/tmp/fifo",string .z.i;
  // extract date
  date:"D"$-8#-3_string filetoload;
  params[`date]:date;
  // override `dbdir to temp hdb dir
  params[`dbdir]:params[`hdbtemp];
  // remove fifo if it exists then make new one
  system"rm -f ",fifo," && mkfifo ",fifo;
  system"gunzip -c ",(1_string filetoload)," > ",fifo," &";
  .Q.fpn[.loader.loaddata[params,(enlist`filename)!enlist `$-3_string filetoload];hsym `$fifo;params`chunksize];
  system"rm ",fifo;

 };

