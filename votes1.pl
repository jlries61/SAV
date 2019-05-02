#!/usr/bin/perl
#Generate Vote file for use with sav

#Constants:
$NCAND=15;
$NSEATS=5;
$NVOTES=10000;
$VOTEFILE="votes1.txt";

open(votefile,">",$VOTEFILE)||die "Cannot open votefile $VOTEFILE\n";
for ($i=0; $i<$NVOTES; $i++)
  {$ncast=int(rand($NSEATS*2));
   for ($j=0; $j<$ncast;)
    {$cand=int(rand($NCAND)+1);
     if (!(&member($cand,$j,@cand))) 
       {if ($j>0) {print votefile " "}
        $cand[$j++]=$cand;
        print votefile $cand;}}
   print votefile "\n";}
print votefile "\n";
close votefile;

sub member {
    local ($item,$size,@list)=@_;
    local $i;

#    print "item=$item size=$size list=@list\n";
    for ($i=0; $i<$size; $i++) {
	if ($item==$list[$i]) {return(1)}}
    return(0);}


