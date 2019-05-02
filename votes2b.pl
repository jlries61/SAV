#!/usr/bin/perl
#Generate Vote file for use with sav

#Constants:
$NCAND=4;
$NSEATS=2;
$NVOTES=10000;
$INFILE="votes1.txt";
$VOTEFILE="votes2b.txt";
$map{8}=1;
$map{3}=2;
$map{7}=3;
$map{13}=4;
@map=(8,3,7,13);

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
      if ($map=$map{$vote}) 
        {$cand[$ncast++]=$map;
         if ($ncast>1) {print votefile " "}
         print votefile "$vote";}}
  print votefile "\n";}
close(infile);
close(outfile);

