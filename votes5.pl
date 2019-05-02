#!/usr/bin/perl
#Generate Vote file for use with sav

#Constants:
$BASELOYAL=.95;
$NCAND=15;
$NPARTY=3;
$NSEATS=5;
$NVOTES=10000;
$nvotes=0;
@PARTY=("Air","Fire","Water");
$PERPARTY=int($NCAND/$NPARTY);
$PIND=.1;
$PSTRAIGHT=.5;
$VOTEFILE="votes5.txt";
for ($party=0; $party<$NPARTY; $party++) {$voteby[$party]=0}

open(votefile,">",$VOTEFILE)||die "Cannot open votefile $VOTEFILE\n";
for ($i=0; $i<$NVOTES; $i++)
  {$indy=(rand(1)<$PIND);
   if (!$indy) 
     {$party=int(rand($NPARTY));
      if (rand(1)<$PSTRAIGHT) {$loyal=1}
       else {$loyal=rand(1-$BASELOYAL)+$BASELOYAL;}}
   $ncast=$NSEATS;
   if ($ncast>0) {$nvotes++}
   for ($j=0; $j<$ncast;)
    {if ($indy||(rand(1)>$loyal))
      {$cand=int(rand($NCAND)+1)}
     else
      {$cand=$party*$PERPARTY+int(rand($NCAND/$NPARTY))+1}
     if (!(&member($cand,$j,@cand))) 
       {if ($j>0) {print votefile " "}
        $party=int(($cand-1)/$PERPARTY);
        $voteby[$party]+=1/$ncast;
        $cand[$j++]=$cand;
        print votefile $cand;}}
   print votefile "\n";}
print votefile "\n";
close votefile;

for ($party=0; $party<$NPARTY; $party++)
  {$pct=100*$voteby[$party]/$nvotes;
   printf("%s: %8.2f votes (%6.2f%%)\n",$PARTY[$party],$voteby[$party],$pct);}

sub member {
    local ($item,$size,@list)=@_;
    local $i;

    for ($i=0; $i<$size; $i++) {
	if ($item==$list[$i]) {return(1)}}
    return(0);}


