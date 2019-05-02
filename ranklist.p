Unit RankList;
{Routines and data types used to create and maintain ranked lists}
{A ranked list is an array, which contains indices to elements in another array
 sorted by a key}
{This allows access to elements in the base array in a particular order without
 having to sort the array}
{Copyright (C) 2009 John L. Ries}

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

interface
type
   RankKeyType		   = (Int,Float,Char);
   RankRecord		   = record
				Index	     : integer;   {Index of record in
							   base array}
				case KeyType : RankKeyType of
				  Int	: (IKey:^integer);
				  Float	: (FKey:^real);
				  Char	: (Key:^string);
				  end;
   RankArray(Size:integer) = array[1..Size] of RankRecord;
   RankArrayPtr		   = ^RankArray;

Function InitRankList(Size    : integer;
		      KeyType : RankKeyType
		      )	      : RankArrayPtr;
   {Return a pointer to a newly created ranked list}

Function RankIndex(const RankList : RankArray;
		         Rank	  : integer
		   )	    : integer;
   {Return the index of the base array element pointed to by rank}

Procedure RankSetKey(var List	: RankArray;
			 Rank	: integer;
			 KeyPtr	: pointer);
   {Set the sort key for an element in a ranked list}

Procedure RankSort(var List : RankArray);
   {Sort a ranked list}
			 
implementation

Procedure RankSetKey;
begin
   if (Rank<1) or (Rank>List.Size) then return; {Out of range}
   with List[Rank] do
     case KeyType of
       Int   : Ikey:=KeyPtr;
       Float : Fkey:=KeyPtr;
       Char  : Key:=Keyptr;
       end;
   end; { RankSetKey }

Function InitRankList;
var
   Index : integer;
   Ranks : RankArrayPtr;

begin
   new(Ranks,Size);
   if Ranks=nil then Return(Ranks); {Out of memory}
   for Index:=1 to Size do begin
      Ranks^[Index].Index:=Index;
      Ranks^[Index].KeyType:=KeyType;
      end;
   return(Ranks);
   end; { InitRankList }

Function RankIndex;
begin
   if (Rank<1) or (Rank>RankList.Size) then return(0) {Out of range}
    else return(RankList[Rank].Index);
   end; { RankIndex }

Procedure RankSort;
var
   Lesser  : boolean;      {First element key is smaller than second}
   KeyType : RankKeyType value List[1].KeyType;
   I,J	   : integer;      {Indeces}
   Sorted  : boolean;
   TempRec : RankRecord;   {Temporary record}

begin
   repeat {Bubble sort}
      Sorted:=true;
      for I:=1 to List.Size-1 do begin
	 J:=I+1;
	 case KeyType of
	   Int	 : Lesser:=List[I].IKey^<List[J].IKey^;
	   Float : Lesser:=List[I].FKey^<List[J].FKey^;
	   Char	 : Lesser:=List[I].Key^<List[J].Key^;
	   end; { case }
	 if Lesser then begin
	    TempRec:=List[I];
	    List[I]:=List[J];
	    List[J]:=TempRec;
	    Sorted:=false;
	    end;
         end;
      until Sorted;
   end;

end.				 
	      
		     
