prefix="/home/snadi/Herodotos"
patterns=""
projects="/home/snadi/Herodotos"
results="./results"
website="./website"
findcmd="python /home/snadi/Herodotos/extract-data.py %d %p 2> %b.log > %o"
flags=""

project Kernel {
  dir = kernel
  linestyle = solid
  marktype = circle
  marksize = 2

  versions = {
	 ("v2.6.37", 01/04/2011, 12539782)
	 ("v2.6.38", 03/14/2011, 12539782)
	 ("v2.6.39", 05/18/2011, 12539782)
	 ("v3.0", 07/21/2011, 12539782)
	 ("v3.1", 10/24/2011, 12539782)	
	 ("v3.2", 01/04/2012, 12539782)
	 ("v3.3", 03/18/2012, 12539782)
	 ("v3.4", 05/20/2012, 12539782)
	 ("v3.5", 07/21/2012, 12539782)
	 ("v3.6", 09/30/2012, 12539782)
  }
}


pattern MissingDead {
 file = "*.missing.globally.dead"
 correl = strict
 color = 0 0.6 0.4
}

pattern MissingUndead {
 file = "*.missing.globally.undead"
 correl = strict
 color = 0 0 1
}


graph gr/number_deads.jgr {
 xaxis = version
 yaxis = count
 xlegend = ""

 project = Kernel

 curve pattern MissingDead
 curve pattern MissingUndead
}

graph gr/bug_occurence_missing.jgr {
 xaxis 	  = version
 yaxis 	  = occurrences
 xlegend  = ""
 filename = true
 info 	  = true
 legend   = "Missing"

 curve project Kernel pattern MissingDead
}


graph gr/average_lifetime.jgr {
   xaxis = groups
   xlegend = "Pattern"
   yaxis = avglifespan
   ylegend = "Years"

   project = Kernel 

   group pattern MissingDead
   group pattern MissingUndead
}

