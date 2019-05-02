unit Queues;
{Routines and data structures for using queues}
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
   QLinkPtr = ^QLink;
   QLink    = record
		 Content  : pointer;
		 Next	  : qlinkptr;
	         end;	  
   QType    = record     
		 First : QLinkPtr;
		 Last  : QLinkPtr;
	      end;     

Procedure InitQ(var Queue : QType);
{Initialize queue}

Function EmptyQ(Queue : QType) :boolean;
{Return true if queue is empty}

Procedure Enqueue(var Queue : QType;      
		      Item  : pointer);
{Add item to queue}

Procedure Dequeue(var Queue : QType;      
		  var Item  : pointer);
{Remove item from queue}

Procedure KillQ(var Queue : QType );
{Delete all items in queue}

implementation

Procedure InitQ;
begin
  with Queue do begin
    First:=nil;
    Last:=nil;
    end;
  end; { InitQ }

function EmptyQ;
begin
   return(Queue.First=nil);
   end;   {EmptyQ}

procedure Enqueue;
  var
     Link : QLinkPtr;
  begin
     new(Link);
     with Link^ do begin
        Content:=Item;
	Next:=nil;
        end;
     with Queue do begin
	if First=nil then First:=link
	 else Last^.Next:=Link;
	Last:=Link;
       end;
     end; {Enqueue}

procedure Dequeue;
var
   Link	: QLinkptr;
begin
   if EmptyQ(Queue) then begin
      Item:=nil;
      return;
      end;
   with Queue do begin
      Link:=First;
      First:=Link^.Next;
      if First=nil then Last:=nil;
      end;
   Item:=Link^.Content;
   dispose(Link);
end; {Dequeue}

procedure killq;
var
   Item : pointer;
begin
   while(not EmptyQ(Queue)) do begin
      Dequeue(Queue,Item);
      if Item<>nil then dispose(Item);
   end;
end; { killq }

end.


