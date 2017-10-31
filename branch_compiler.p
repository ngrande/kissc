{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const TAB = ^I;

{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char; { Lookahead Character }
	LCount: integer; { Label Counter }

{--------------------------------------------------------------}
{ Read New Character From Input Stream }
procedure GetChar;
begin
	Read(Look);
end;

{--------------------------------------------------------------}
{ Report an Error }
procedure Error(s: string);
begin
	WriteLn;
	WriteLn(^G, 'Error: ', s, '.');
end;

{--------------------------------------------------------------}
{ Report Error and Halt }
procedure Abort(s: string);
begin
	Error(s);
	Halt;
end;

{--------------------------------------------------------------}
{ Report What Was Expected }
procedure Expected(s: string);
begin
	Abort(s + ' Expected');
end;

{--------------------------------------------------------------}
{ Match a Specific Input Character }
procedure Match(x: char);
begin
	if Look = x then GetChar
	else Expected('''' + x + '''');
end;

{--------------------------------------------------------------}
{ Recognize an Alpha Character }
function IsAlpha(c: char): boolean;
begin
	IsAlpha := upcase(c) in ['A'..'Z'];
end;

{--------------------------------------------------------------}
{ Recognize a Decimal Digit }
function IsDigit(c: char): boolean;
begin
	IsDigit := c in ['0'..'9'];
end;

{--------------------------------------------------------------}
{ Get an Identifier }
function GetName: char;
begin
	if not IsAlpha(Look) then Expected('Name');
	GetName := UpCase(Look);
	GetChar;
end;

{--------------------------------------------------------------}
{ Get a Number }
function GetNum: char;
begin
	if not IsDigit(Look) then Expected('Integer');
	GetNum := Look;
	GetChar;
end;

{--------------------------------------------------------------}
{ Output a String with Tab }
procedure Emit(s: string);
begin
	Write(TAB, s);
end;

{--------------------------------------------------------------}
{ Output a String with Tab and CRLF }
procedure EmitLn(s: string);
begin
	Emit(s);
	WriteLn;
end;

{--------------------------------------------------------------}
{ Initialize }
procedure Init;
begin
	GetChar;
end;

function NewLabel: string;
var S: string;
begin
	Str(LCount, S);
	NewLabel := 'L' + S;
	Inc(LCount);
end;

procedure PostLabel(L: string);
begin
	WriteLn(L, ':');
end;

procedure Other;
begin
	EmitLn(GetName);
end;

procedure Block;
begin
	while not(Look in ['e']) do begin
		Other;
	end;
end;

procedure DoProgram;
begin
	Block;
	if Look <> 'e' then Expected('End');
	EmitLn('END');
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	DoProgram;
end.
{--------------------------------------------------------------}
