{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const TAB = ^I;
const CR = ^M;
const LF = ^J;

{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char; { Lookahead Character }

{--------------------------------------------------------------}
{ Read New Character From Input Stream }
procedure GetChar;
begin
	Read(Look);
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

procedure PostLabel(L: string);
begin
	WriteLn(L, ':');
end;

procedure Declarations;
begin
end;

procedure Statements;
begin
end;

procedure DoBlock(Name: char);
begin
	Declarations;
	PostLabel(Name);
	Statements;
end;

procedure Prolog;
begin
	{ for OS SK*DOS }
	EmitLn('WARMST EQU $A01E');
end;

procedure Epilog(Name: char);
begin
	{ for OS SK*DOS }
	EmitLn('DC WARMST');
	EmitLn('END ' + Name);
end;

procedure Prog;
var Name: char;
begin
	Match('p');
	Name := GetName;
	Prolog;
	DoBlock(Name);
	Match('.');
	Epilog(Name);
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	Prog;
end.
{--------------------------------------------------------------}
