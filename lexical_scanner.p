{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const	TAB = ^I;
		CR = ^M;
		LF = ^J;
		ENDC = '.';


{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char; { Lookahead Character }
	Token: string[16];

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

function IsAlNum(c: char): boolean;
begin
	IsAlNum := IsAlpha(c) or IsDigit(c);
end;

function IsWhite(c: char): boolean;
begin
	IsWhite := c in [' ', TAB];
end;

procedure SkipWhite;
begin
	while IsWhite(Look) do
		GetChar;
end;

procedure Fin;
begin
	if Look = CR then GetChar;
	if Look = LF then GetChar;
end;

{--------------------------------------------------------------}
{ Get an Identifier }
function GetName: string;
var x: string[8];
begin
	x := '';
	if not IsAlpha(Look) then Expected('Name');
	while IsAlNum(Look) do begin
		x := x + UpCase(Look);
		GetChar;
	end;
	GetName := x;
	SkipWhite;
end;

{--------------------------------------------------------------}
{ Get a Number }
function GetNum: string;
{ do not know why we use 16 here despite a 64 bit integer would be 20 digits and a 32 bit integer would be 10 digits... }
var x: string[16];
begin
	x := '';
	if not IsDigit(Look) then Expected('Integer');
	while IsDigit(Look) do begin
		x := x + Look;
		GetChar;
	end;
	GetNum := x;
	SkipWhite;
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
	Token := '';
end;

function Scan: string;
begin
	if IsAlpha(Look) then
		Scan := GetName
	else if IsDigit(Look) then
		Scan := GetNum
	else begin
		Scan := Look;
		GetChar;
	end;
	SkipWhite;
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	repeat
		Token := Scan;
		WriteLn(Token);
		if Token = CR then Fin;
	until Token = ENDC;
end.
{--------------------------------------------------------------}
