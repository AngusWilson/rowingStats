/########################
/Race Info Script
/run with polar flow exports from race session in directory ./races
/Configurable race length and split distance (m) below
/outputs a table with the split breakdown for each race in the directory
/Calculates average split across the interval
/########################

raceDist:2000;
splitLength:500;


loadRace:{[file;raceDist]
	//Load and sanitise
	/Header is aggregates from session - currently ununsed
	header:2#data:read0 file;

	/Put pre-sanitised column titles on
	data:3_data;
	data:("*TIFT*IIFF*";enlist",")0: (enlist"SampleRate,Time,HR,Speed,Pace,Cadence,Altitude,StrideLength,Distances,Temperatures,Power"),data;

	/remove un-needed data
	data:delete SampleRate,Cadence,Altitude,StrideLength,Temperatures,Power from data;

	/pick out the 20 fastest 100 m segments. This will be mostly the race with some warmups
	/then pick the 10 from that set that have greatest distance - i.e. nearest end of session -> shoudl be the race
	raceSegs:exec Distances from 10#desc key 20#desc select avg Speed by 100 xbar Distances from data where not null Speed;
	
	/chose the distance to start scanning from as the largest distance- the race length
	startFrom:(max raceSegs)-raceDist;
	
	/Pick the "stakeBoat" as the distance in the session where we remain still for a period 
	stakeBoat:first exec Distances from 0!(select count i by 1 xbar Distances from data where Distances>startFrom,Distances<max raceSegs) where x=max x;
	
	/remove ticks where sitting still
	drop:(first exec count i from data where Distances<stakeBoat+1,Distances>stakeBoat)-1;
	rStart:select from (select from data where Distances>stakeBoat)where i>drop;

	/pick the race distance out
	rawRace:select from rStart where Distances<=first Distances+raceDist;
	
	/santise raw race - drop out any meters between 0.1 and 10 - cause some weirdness
	race:select from (`meter`time`split xcols delete Time,Distances,Speed,Pace from update time:Time-first Time,meter:Distances-first Distances,split:`time$Pace%120 from rawRace) where not meter within (0.1 10);
	race
	};

	/This func is the avg split across the time of the race.
	/more affected by the first 10m drop
calcAvgSplits:{[splitLength;race]	
	select `time$avg split by splitLength xbar meter from race
	};
	
	/this is just the timestamp as we cross each split
calcTimeSplits:{[splitLength;race]	
	s:select split:last time by splitLength xbar meter from race;
	update deltas split from s
	};



/pick out race csvs and load
files:`$":races/",/:string rName:key `:races;
races: loadRace[;raceDist] each files;

/calc splits, clean up times so they don't have leading zeros or too much precision, and display in console nicely as symbols
splits:calcAvgSplits[splitLength] each races;
full:flip (raze `meter,`$-4_/:string[rName])!flip(exec meter from key first splits),'flip `$-2_/:/:4_/:/:string each{exec split from x}each splits


show"Race distance set to ",string raceDist;
show"Split length set to ",string splitLength;

show"##############"
show"avg splits"
show full

/calc via time rather than avg split - other method seems to give better results.
splits:calcTimeSplits[splitLength] each races;
full:flip (raze `meter,`$-4_/:string[rName])!flip(exec meter from key first splits),'flip `$-2_/:/:4_/:/:string each{exec split from x}each splits

show"##############"
show"time marker splits"
show full
