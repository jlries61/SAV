#!/usr/bin/perl
#Generate Vote file for use with sav

#Constants:
$NCAND=4;
$NSEATS=2;
$NVOTES=10000;
$INFILE="votes1.txt";
$VOTEFILE="votes2.txt";
$map{8}=1;
$map{3}=2;
$map{7}=3;
$map{13}=4;

open(infile,$INFILE)||die "Cannot open input file $INFILE\n";
open(votefile,">",$VOTEFILE)||die "Cannot open votefile $VOTEFILE\n";
for ($i=0; $i<$NVOTES; $i++)
  {$line=<infile>;
   chop $line;
   @votefor=split(/ /,$line);
   $nvote=@votefor;
   $ncast=0;
   for ($j=0; $j<$nvote; $j++)
     {$vote=$votefor[$j];
      $map=$map{$vote};
      if ($map>0) 
        {$cand[$ncast++]=$map;
         if ($ncast>1) {print votefile " "}
         print votefile "$map";}}
   $nvote=$ncast;
   $ncast=max(int(rand($NSEATS*2)),$nvote);
   if ($ncast>$nvote)
     {for ($j=$nvote; $j<$ncast;)
       {$cand=int(rand($NCAND)+1);
        if (!(&member($cand,$j,@cand))) 
          {$cand[$j++]=$cand;
           if ($j>1) {print votefile " "}
           print votefile "$cand";}}}
   print votefile "\n";}
print votefile "\n";
close votefile;
close infile;

sub member {
    local ($item,$size,@list)=@_;
    local $i;

    for ($i=0; $i<$size; $i++) {
	if ($item==$list[$i]) {return(1)}}
    return(0);}

sub max {
    local ($item1,$item2)=@_;
    if ($item1>$item2) {return($item1)}
     else {return($item2)}}
