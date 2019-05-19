Program SAV;
{Implementation of single allocatable voting}
{by John L. Ries}
{Copyright (C) 2009 by John L. Ries}

{This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.}

uses Queues, RankList;

const
   electwidth  = 10;                 {Width of election indicator field}
   MaxFileName = 255;                {Maximum length of a file name}
   MaxCandName = 30;                 {Maximum candidate name length}
   version     = '1.0';              {Version number}
   votewidth   = 12;                 {Width of voting field in table}
type
   CandName		= string(MaxCandName);            {Candidate name}
   CandStatus		= (Elected, Eliminated, Neither); {Candidate status}
   CandRecord		= record
                             Name	: CandName;
                             RawVote	: integer;    {# persons voted for}
                             Allocation : integer;    {# votes assigned to}
                             Status	: CandStatus; {Candidate Status}
                             VoteQ	: Qtype;      {List of assigned votes}
                          end;
   CandArray(N:integer) = array[1..N] of CandRecord;  {Array of Cand Records}
   CandArrayPtr	= ^CandArray;
   FileName		= string(MaxFileName);
   RankCriterion	= (Raw, Alloc); {Which set of votes do we use to rank candidates?}
   VoteType(N:integer)  = array [1..N] of boolean; {true for candidates voted for; false otherwise}
   VoteTypePtr          = ^VoteType;

Procedure AssignVote(	 VoteFor : VoteTypePtr;  {Vote to assign}
                     var CandRec  : CandRecord;   {Record of candidate to whom to assign vote}
                         Quota	  : integer;      {# votes required to elect}
                     var Nelect   : integer);     {# candidates elected}
{Assign vote to candidate}
{Update number of candidates elected, if necessary}
begin
   with CandRec do begin
      Allocation:=Allocation+1;
      if (Status<>Elected) and (Allocation>=Quota) then begin
         Status:=Elected;
         Nelect:=Nelect+1;
      end;
      Enqueue(Voteq,VoteFor);
   end;
end; { AssignVote }

Procedure TransferVote(var CandRec  : CandRecord;   {Record of candidate from whom to transfer vote}
                       var VoteFor  : VoteTypePtr;  {Transferred vote}
                           Quota    : integer );    {# votes required to elect}
{Transfer Vote from candidate}
{Return null vote if candidate has been elected and is at quota, or if there
 are no votes to transfer}
begin
   VoteFor:=nil;
   with CandRec do begin
      if Allocation<=0 then return;  {No votes to transfer}
      if (Status=Elected) and (Allocation<=quota) then return;
      Dequeue(Voteq,VoteFor);
      Allocation:=Allocation-1;
   end;
end; { TransferVote }

Function CandSort(const CandList : CandArray;      {Candidate array}
                        RankBy   : RankCriterion   {Ranking criterion}
                 )               : RankArrayPtr;
{Return pointer to list of candidate indeces, sorted in descending order of
 vote}
var
   Index	: integer;                   {Candidate index}
   NCand	: integer value CandList.N;  {Number of candidates}
   RankList	: RankArrayPtr value nil;    {Points to ranked list of indeces}
begin
   {Initialize list}
   RankList:=InitRankList(NCand,int);
   if RankList=nil then begin
      writeln("Out of memory in CandSort");
      return(RankList);
   end;
   {Determine what ranking criterion to use}
   for Index:=1 to NCand do
      with CandList[Index] do begin
         if RankBy=Raw then RankSetKey(RankList^,Index,@RawVote)
         else RankSetKey(RankList^,Index,@Allocation);
      end;
   RankSort(RankList^);
   return(RankList);
end; { CandSort }

Procedure Alloc1(var   VoteQ	: QType;        {vote queue}
                 var   CandList : CandArray;    {array of candidate records}
                 const CandRank : RankArray;    {ranking array}
                       NVotes	: integer;      {Number of persons voting}
                       Quota	: integer;      {# votes needed to elect}
                 var   NElect	: integer);     {# candidates elected}
{Initial assignment of votes:
   Allocate each vote to the highest ranked candidate voted for who has not
   yet reached quota.  If all candidates voted for have reached quota,
   allocate to the highest ranked candidate}
var
   Index   : integer;                   {Candidate index}
   NCand   : integer value CandList.N;  {# Candidates}
   Rank    : integer;                   {Candidate rank}
   Seq	   : integer;                   {Vote sequence}
   TransTo : integer;                   {Candidate to whom to assign vote}
   VoteFor : VoteTypePtr;               {Points to vote vector}
begin
   for seq:=1 to nvotes do begin
      TransTo:=0;
      Dequeue(VoteQ,VoteFor);
      {Determine candidate to whom to assign vote}
      for Rank:=1 to NCand do begin
         Index:=RankIndex(CandRank,Rank);
         if index=0 then begin
            writeln("Rank out of range in alloc1");
            return;
         end;
         if not VoteFor^[Index] then continue;   {Didn't vote for this one}
         if TransTo=0 then TransTo:=Index;       {Highest ranked candidate voted for}
         if CandList[Index].Status=Elected then continue; {Prefer candidates that have not yet
                                                           reached quota}
         TransTo:=Index; {Pick this one}
         break;
      end;
      if TransTo=0 then begin
         writeln("Unassignable vote in alloc1");
         return;
      end;
      AssignVote(VoteFor,CandList[TransTo],Quota,NElect);
   end;
   return;
end; { Alloc1 }

procedure Alloc2(var   CandList     : CandArray;   {array of candidate recs}
                 const CandRank     : RankArray;   {rankings by raw vote}
                       Quota	    : integer;     {# votes needed to elect}
                       NSeats	    : integer;     {# seats to fill}
                 var   AllocRank    : RankArray;   {rankings by allocation}
                 var   NElect	    : integer);    {# candidates elected}
{Second stage allocation of votes}
   {If not all seats are filled, transfer votes from the candidate with the
    highest allocation who has already reached quota to the highest-ranked
    candidate who has not yet reached quota; stop when either all seats are
    filled, or there are no more votes to transfer}
var
   Index	     : integer;     {Candidate index}
   NCand	     : integer value CandList.N;        {Number of candidates}
   NTrans	     : array[1..CandList.N] of integer; {# transferrable votes}
   Rank	     : integer;     {Rank index}
   TransFrom,TransTo : integer;     {Indeces of parties to transfer}
   VoteFor	     : VoteTypePtr; {Vote to transfer}
begin
   {Can't transfer more votes than one has}
   for Index:=1 to NCand do NTrans[Index]:=CandList[Index].Allocation;
   {Main Loop}
   while (NElect<NSeats) do begin
      {Select candidate from whom to transfer vote}
      TransFrom:=0;
      for Rank:=1 to NCand do begin
         Index:=RankIndex(AllocRank,Rank);
         if CandList[Index].Status<>Elected then continue; {no more votes}
         if NTrans[Index]<=0 then continue; {no more votes}
         TransFrom:=Index;  {pick this one}
         break;
      end;
      if TransFrom=0 then return;    {No more votes can be transferred}
      TransferVote(CandList[TransFrom],VoteFor,Quota);
      if VoteFor=nil then return;   {No more votes can be transferred}
      NTrans[TransFrom]:=NTrans[TransFrom]-1;
      {Select candidate to whom to transfer vote}
      TransTo:=0;
      for Rank:=1 to NCand do begin
         Index:=RankIndex(CandRank,Rank);
         if Index=TransFrom then continue;     {Skip candidate from whom vote was transferred}
         if not VoteFor^[Index] then continue; {Didn't vote for this one}
         if TransTo=0 then Transto:=Index;     {Highest ranked remaining candidate voted for}
         if CandList[index].Status=Elected then continue; {Prefer non-elected candidates}
         TransTo:=Index; {Pick this one}
         break;
      end;
      if TransTo=0 then TransTo:=TransFrom  {Can't transfer vote}
      else NTrans[TransTo]:=NTrans[TransTo]+1;
      AssignVote(VoteFor,CandList[TransTo],Quota,Nelect);
      RankSort(AllocRank);
      end;
   end; { Alloc2 }

procedure Alloc3(var   CandList    : CandArray;  {Candidate Records}
                 const CandRank    : RankArray;  {Rankings by raw vote}
                       NSeats	   : integer;    {# seats to fill}
                       Quota	   : integer;    {# votes required to elect}
                 var   AllocRank   : RankArray;  {Rankings by allocation}
                 var   NElect	   : integer);   {# candidates elected}
{Third stage allocation of votes}
   {If not all seats are filled, "eliminate" the candidate with the lowest
    allocation and transfer as many votes as possible from that candidate
    to the highest ranking candidate who has neither reached quota, nor has
    been "eliminated", until all seats are filled.  If no more votes can be
    transfered from this candidate, repeat the process with the candidate with
    the next lowest allocation until either all seats are filled, or until
    all non-elected candidates have been "eliminated"}
var
   Index	     : integer;                  {Candidate index}
   NCand	     : integer value CandList.N; {# candidates}
   NTrans	     : integer;                  {# transferrable votes}
   RankFrom,RankTo   : integer;                  {Candidate rank}
   TransFrom,TransTo : integer;                  {Parties to vote transfer}
   VoteFor	     : VoteTypePtr;              {Points to transferring vote}
begin
   for RankFrom:=NCand downto 1 do begin
      if NElect>=NSeats then break;  {All seats are filled}
      TransFrom:=RankIndex(AllocRank,RankFrom);
      with CandList[TransFrom] do begin
         if Status=Elected then continue;
         Status:=Eliminated;
      end;
      for NTrans:=CandList[TransFrom].Allocation downto 1 do begin
         if NElect>=NSeats then break;  {All seats are filled}
         TransferVote(CandList[TransFrom],VoteFor,Quota);
         {Select candidate to whom to transfer vote}
         TransTo:=0;
         for RankTo:=1 to NCand do begin
            Index:=RankIndex(CandRank,RankTo);
            if not ((CandList[Index].Status=Neither) and (VoteFor^[Index])) then continue;
            TransTo:=Index;
            break;
         end;
         if TransTo=0 then TransTo:=TransFrom; {Can't transfer vote}
         AssignVote(VoteFor,CandList[TransTo],Quota,NElect);
      end;
      RankSort(AllocRank);
   end;
end; {Alloc3}

procedure FinalStatus(var   CandList : CandArray; {List of candidate records}
                      const CandRank : RankArray; {List of candidate rankings}
                      var   NElect   : integer;   {# candidates elected}
                            NSeats   : integer;   {# seats to fill}
                            Runoff   : boolean);  {Allow runoff}
{Determine the final status of each candidate}
   {If not all seats are filled, there are 2 options:}
     {1.  Declare the "eliminated" candidates with the largest allocations
          to have been elected}
     {2.  Hold a runoff between the "eliminated" candidates with the largest
          allocations.  Twice as many candidates will qualify for the runoff
          as there are seats remaining to be filled.  If, after the runoff,
          there are still seats remaining to be filled, declare elected the
          remaining candidates with the largest allocations in the runoff}
var
   Index,Rank : integer;                   {Candidate index, rank}
   NCand      : integer value CandList.n;  {# candidates}
   NRoff      : integer;                   {# candidates in runoff}
begin
   {Determine number of candidates to qualify for runoff}
   if Runoff and (NElect<NCand) then NRoff:=2*(NSeats-NElect)
    else NRoff:=0;
   {Main loop}
   for Rank:=1 to NCand do begin
      Index:=RankIndex(CandRank,Rank);
      with CandList[Index] do begin
         if Status=Elected then continue;
         if NRoff>0 then begin
            Status:=Neither;
            NRoff:=NRoff-1;
         end
      else if (not Runoff) and (NElect<NSeats) then begin
         Status:=Elected;
         NElect:=NElect+1;
      end
      else Status:=Eliminated;
      end;
   end;
end; { FinalStatus }

procedure FreePtr(var Item : pointer);
{Free pointer and set to nil}
begin
   if Item=nil then return;
   dispose(Item);
   Item:=nil;
   end; { FreePtr }

procedure FreeCandArray(var CandList : CandArrayPtr);
{Free array of candidate records}
var
   Index : integer;                      {Candidate index}
   NCand : integer value CandList^.n;    {# candidates}
   Seq	 : integer;                      {Vote sequence}
   Vote  : VoteTypePtr;                  {Points to vote vector}
begin
   for Index:=1 to NCand do
      with CandList^[Index] do begin
         if Allocation<=0 then continue;
         for Seq:=1 to Allocation do begin
            Dequeue(VoteQ,Vote);
            dispose(vote);
         end;
      end;
   FreePtr(CandList);
end; { FreeCandArray }

procedure Help;
{Print help screen}
begin
   writeln;
   writeln("SAV ",version);
   writeln("Copyright (C) 2009 by John L. Ries");
   writeln("Distributed under the terms of the GNU General Public License,");
   writeln("version 2, or at the recipient's option, any later version.");
   writeln("See the file COPYING, or http://www.gnu.org/licenses/ for details.");
   writeln;
   writeln("Tabluates and prints election results according to");
   writeln("Single Allocatiable Voting (SAV).");
   writeln;
   writeln("Usage:");
   writeln(ParamStr(0)," <control deck> <vote file>");
   writeln;
   writeln("The control deck will be a text file.  The first line will");
   writeln("contain the number of seats to be filled, followed by the runoff");
   writeln("field, which will be 1 of a runoff is permitted, and 0");
   writeln("otherwise.  The remaining lines will contain the names of the");
   writeln("candidates, one per line in the order of the indeces used in the");
   writeln("vote file.");
   writeln;
   writeln("The vote file will be a text file, with one vote per line.");
   writeln("Each vote record will consist of the indeces of the");
   writeln("candidates voted for, delimited by spaces.");
   writeln;
   end; { Help }

function PctWin(var CandList : CandArray):real;
{Return the percentage of voters who chose at least one winning candidate}
var
   I,J,K  : integer;                  {indeces}
   NCand  : integer value CandList.N; {# candidates}
   NVotes : integer value 0;          {# persons voting}
   NWin	  : integer value 0;  {# persons voting for at least one winning candidate}
   VoteFor : VoteTypePtr;             {Points to vote vector}
begin
   for I:=1 to NCand do begin
      with CandList[I] do begin
         if Allocation<=0 then continue;  {No votes to count}
         NVotes:=NVotes+Allocation;       {Add entire allocation to NVotes}
         {If elected, add entire allocation to NWin, otherwise, determine which
          of the assigned votes were cast for winning candidates}
         if Status=Elected then NWin:=NWin+Allocation
         else for J:=1 to Allocation do begin
            Dequeue(VoteQ,VoteFor);  {Remove a vote vector from the queue}
            for K:=1 to NCand do     {See if any winning candidates were picked}
               if VoteFor^[K] and (CandList[K].Status=Elected) then begin
                  NWin:=NWin+1;
                  break;
               end;
            Enqueue(VoteQ,VoteFor); {Return the vote vector to the queue}
         end;
      end;
   end;
   return(100*NWin/NVotes);
end; { PctWin }

procedure PrintResults(CandList : CandArray;   {List of candidate records}
                       CandRank : RankArray;   {List of candidate rankings}
                       Nseats	: integer;     {# seats to fill}
                       NVotes	: integer;     {# persons voting}
                       Quota	: integer);    {# votes required to elect}
   {Print a table with the following columns:}
     {1.  Candidate name}
     {2.  Raw vote}
     {3.  Allocated vote}
     {4.  Elected? (* if yes; + if qualifies for runoff; blank if no)}
     {Below the table will appear the total number of persons voting and the
      number of votes required for election}
     {The candidates will be ranked in order of their final allocations}
var
   Index,Rank : integer;                  {Candidate index, rank}
   NCand      : integer value CandList.N; {# candidates}
   NRoff      : integer value 0;          {# candidates in runoff}
begin
   writeln;
   writeln("Number of seats to fill: ",NSeats);
   writeln("Number of votes cast: ",NVotes);
   writeln("Election Quota: ",Quota);
   writeln;
   writeln("Candidate":MaxCandName,"Raw vote":VoteWidth, "Allocation":VoteWidth,
           "Status":ElectWidth);
   for Rank:=1 to NCand do begin
      index:=RankIndex(CandRank,Rank);
      if Index=0 then begin
         writeln("Bad index in PrintResults");
         return;
      end;
      with CandList[Index] do begin
         if RawVote>0 then begin
            write(Name:MaxCandName,RawVote:VoteWidth,Allocation:VoteWidth);
            if Status=Elected then write("*":ElectWidth)
            else if Status=Neither then begin
               write("+":ElectWidth);
               NRoff:=NRoff+1;
            end;
            writeln;
         end;
      end;
   end;
   writeln("% votes cast for winning candidates:", PctWin(CandList):6:2);
   writeln;
   writeln("*Elected");
   if NRoff>0 then writeln("+Qualified for runoff");
end; { PrintResults }

procedure ReadCtlDeck(var CtlDeck      : Text;         {Control deck file}
                      var CandList     : CandArrayPtr; {Ptr to candidate array}
                      var NSeats,Ncand : integer;      {# seats, candidates}
                      var Runoff       : boolean);     {Allow runoff?}
{Read the control deck and pass back the number of candidates,
 the candidate array, the number of seats to be filled,
 and the runoff indicator}
var
   Index : integer;     {Candidate index}
   YesNo : integer;     {1=yes; 0=no}
   Name	 : CandName;    {Candidate name}
begin
   {First pass: Read number of seats to be filled and runoff indicator;
                determine number of candidates}
   read(CtlDeck,NSeats);
   {Read runoff field; if there isn't one, accept default from main program}
   if not eoln(CtlDeck) then begin
      read(CtlDeck,YesNo);
      Runoff:=(YesNo>0);
   end;
   {Count number of candidates}
   readln(CtlDeck);
   NCand:=0;
   while not eof(CtlDeck) do begin
      readln(CtlDeck,Name);
      if length(Name)>0 then NCand:=NCand+1; {Ignore blank lines}
   end;
   {Second pass: Create candidate record list}
   reset(CtlDeck);
   readln(CtlDeck);  {Ignore first line}
   new(CandList,NCand);
   for Index:=1 to NCand do begin
      with CandList^[Index] do begin
         repeat    {Skip blank lines}
            readln(CtlDeck,Name);
         until length(Name)>0;
         RawVote:=0;
         Allocation:=0;
         Status:=Neither;
         InitQ(VoteQ);
      end;
   end;
end; { ReadCtlDeck }

Procedure ReadVotes(var VoteFile : text;       {Vote file}
                    var CandList : CandArray;  {Candidate array}
                    var VoteQ	 : Qtype;      {List of votes cast}
                    var NVotes	 : integer);   {# votes cast}
{Read vote file, consisting of one line per vote; each line is a
 space-delimited list of the indeces of the candidates voted for}
{Blank votes are ignored, as are out-of-range indeces}
{Pass back a list of votes cast, and the number of votes cast}
{CandList is updated with the numbers of persons voting for each candidate}
{At present, this procedure will fail if a line ends with a space}
var
   Index    : integer;                  {Candidate index}
   NCand    : integer value CandList.N; {Number of candidates}
   NVoteFor : integer;                  {# candidates voted for by person}
   Vote     : integer;                  {Index of person voted for}
   VoteFor  : VoteTypePtr;              {Points to vote vector}
begin
   {Initializations}
   NVotes:=0;
   InitQ(VoteQ);
   {Main loop}
   while not eof(VoteFile) do begin
      {Initialize vote}
      new(VoteFor,NCand);
      for Index:=1 to NCand do
         VoteFor^[Index]:=false;
      NVoteFor:=0;
      {Read vote}
      while not eoln(VoteFile) do begin
         read(VoteFile,Vote);
         {Ignore any out-of-range votes}
         if (Vote>0) and (Vote<=NCand) then begin
            VoteFor^[Vote]:=true;
            with CandList[Vote] do RawVote:=RawVote+1;
            NVoteFor:=NVoteFor+1;
         end;
      end;
      {Record vote, if not blank}
      if NVoteFor>0 then begin
        NVotes:=NVotes+1;
        Enqueue(VoteQ,VoteFor);
      end;
      if not eof(VoteFile) then readln(VoteFile);
   end;
end; { ReadVotes }

{Main Program}
var
   AllocRank : RankArrayPtr value nil; {Ptr to array of candidate indeces in order of allocation}
   CandList  : CandArrayPtr value nil; {Ptr to candidate record list}
   CandRank  : RankArrayPtr value nil; {Ptr to array of candidate indeces in order of raw vote}
   CtlDeck	: Text;                 {Control deck}
   CtlDeckName	: FileName;             {Name of control deck}
   NArgs	: integer value 0;      {Number of command-line args}
   NCand	: integer value 0;      {Number of candidates}
   NElect       : integer value 0;      {Number of candidates elected}
   NSeats	: integer value 0;      {Number of seats to be filled}
   NVotes       : integer value 0;      {Number of persons voting}
   Quota        : integer value 0;      {# votes required for election}
   Runoff	: boolean value false;  {Allow runoff}
   VoteFile	: Text;                 {Vote file}
   VoteFileName : FileName;             {Name of vote file}
   VoteQ        : QType;                {General vote queue}
begin
   {Read arguments; give help screen if not enough}
   NArgs:=ParamCount;
   if NArgs<2 then begin
      Help;
      exit;
    end
    else begin
       CtlDeckName:=ParamStr(1);
       VoteFileName:=ParamStr(2);
    end;
   {Read data; get raw vote counts; count number of voters}
   reset(CtlDeck,CtlDeckName);
   ReadCtlDeck(CtlDeck,CandList,NSeats,NCand,Runoff);
   close(CtlDeck);
   reset(VoteFile,VoteFileName);
   ReadVotes(VoteFile,CandList^,VoteQ,NVotes);
   close(VoteFile);
   {Calculate droop quota; rank candidates by raw vote}
   Quota:=(NVotes div (NSeats+1))+1;
   CandRank:=CandSort(CandList^,Raw);
   if CandRank=nil then begin
      writeln("Out of memory after reading votes");
      exit;
      end;
   {Initial assignment of votes}
   Alloc1(VoteQ,CandList^,CandRank^,NVotes,Quota,NElect);
   if not EmptyQ(VoteQ) then begin
      writeln("Internal error:");
      writeln("Vote queue not empty after initial assignment of votes");
      exit;
      end;
   {Rank candidates by allocation}
   AllocRank:=CandSort(CandList^,Alloc);
   if AllocRank=nil then begin
      writeln("Out of memory after initial assignment of votes");
      exit;
   end;
   {If not all seats are filled, do second-stage assignment of votes}
   if NElect<NSeats then Alloc2(CandList^,CandRank^,Quota,NSeats,AllocRank^,NElect);
   {If not all seats are filled, do third-stage assignment of votes}
   if NElect<NSeats then Alloc3(CandList^,CandRank^,NSeats,Quota,AllocRank^,NElect);
   {Determine the final status of each candidate}
   FinalStatus(CandList^,AllocRank^,NElect,NSeats,Runoff);
   {Print Election Results}
   PrintResults(CandList^,CandRank^,NSeats,NVotes,Quota);
   {Free all dynamic data structures and exit}
   FreePtr(AllocRank);
   FreeCandArray(CandList);
   FreePtr(CandRank);
end.
