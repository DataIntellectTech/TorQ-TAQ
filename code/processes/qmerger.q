hdbdir:@[value;`hdbdir;`:hdb]
tempdbdir:@[value;`tempdbdir;`:tempdb]
mergedir:@[value;`mergedir;`:mergedir]

// reset temp hdb and update merged table
reset:{
  .lg.o[`quotemerger;"creating date partition ",string x[`tabledate]];
  `merged upsert ([date:26#x[`tabledate];split:`$'.Q.A]status:26#0b);
  empty:select from (get x[`tablepath]) where ticktime<x[`tabledate];  
  y set empty;
  .lg.o[`quotemerger;"date partition created"];
  };

// base merge function
merge:{
  .lg.o[`quotemerger;"Merging split ",string x[2]];
  x[3] upsert @[get;x[0];{[e] [.lg.e[`merge;errmsg:"Failed merge:",e];'splitnonexistant]}];
  .lg.o[`quotemerger;string[x[2]]," merged"];
  merged[(x[1];x[2])]:1b;
  return:1b
  };

// quote merge function
mergesplit:{
  pardir:` sv tempdbdir,`final, `$string x[`tabledate];
  quotedir:` sv pardir,`quote,`;
  // extract split letter, path of form `:/path/to/quoteA/date/table 
  split:`$first vs["/";reverse string x[`tablepath]][2];
  // check if date has entries in merged table
  c:count a:exec distinct date from merged;
  if[c=a?x[`tabledate];reset[x;quotedir]];
  // attempt to merge and key result
  .lg.o[`quotemerger;"Attempting to merge split ",string split];
  $[merged[(x[`tabledate];split)][`status];.lg.o[`quotemerger;"unsuccessful: already merged"];];
  a:$[merged[(x[`tabledate];split)][`status];
    (0b;"unsuccessful: already merged";.z.P);
    @[{(merge x;"success";.z.P)};
      (x[`tablepath];x[`tabledate];split;quotedir);
      {(0b;"unsuccessful:",x;.z.P)}
     ]
    ];
  result:`mergestatus`mergemessage`mergeendtime!a;
  // save merged table for use in orchestrator process
  save mergedir;
  syscmd["rm -r ",1_"/" sv -2_vs["/";string x[`tablepath]]];
  // build return dictionary
  b:`=(merged?0b)[`split];
  returnkeys:`loadid`mergelocation`fullmergestatus;
  return:result,returnkeys!(x[`loadid];quotedir;b)
  };

// move merged quotes to date partition in hdb
movepartohdb:{[date;loadfiles]
  makeemptyschema[loadfiles];
  pardir:` sv tempdbdir,`final, `$string date;
  .lg.o[`quotemerger;"moving merged quote data to hdb"]
  syscmd[" " sv ("mv";.os.pth pardir;.os.pth hdbdir)];
  .lg.o[`quotemerger;"quote data moved to hdb"];
  .lg.o[`quotemerger;"clearing ",string date, " from temporary database"];
  syscmd["rm -r ",string pardir];
<<<<<<< HEAD
  .lg.o[`quotemerger;"temporary db cleared"];
=======
  .lg.0[`quotemerger;"temporary db cleared"];
<<<<<<< HEAD
>>>>>>> test movetohdb output
=======
>>>>>>> 917d23a54b8ce5b7acceb9e0a928d9079db280c1
  :1b
  };

manmovetohdb:{[date;filetype]
  pardir:` sv tempdbdir,`final, `$string date, `$string filetype;
  syscmd["mv ",(.os.pth pardir)," ",(.os.pth hdbdir),string date];
  };

// function which makes empty schema for tables that are not selected for download
makeemptyschema:{[loadfiles;pardir]
    pardir:` sv tempdbdir,`final, `$string date;
    f:`trade`quote`nbbo;
    a:f except loadfiles;
    emptytaqschema[]; 
    b:.Q.dd[pardir]each a,'`;
  // need to save empty schemas in tempdb/final, will add soon
  // this will be called in moveparttohdb, empty schemas will be made for files not in loadfiles variable
  };

// attempt to load merged table, create it if it doesnt exist
merged:@[{get x};mergedir;{([date:"d"$();split:"s"$()]status:"b"$())}]