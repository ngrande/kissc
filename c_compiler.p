{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const TAB = ^I;
const CR = ^M;
const LF = ^J;

{--------------------------------------------------------------}
{ Variable Declarations }
var Look:	char; { Lookahead Character }
	Class:	char;
	Sign:	char;
	Typ:	char;

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

procedure GetClass;
begin
	{ auto, eXtern and static }
	if Look in ['a', 'x', 's'] then begin
		Class := Look;
		GetChar;
		end
	else Class := 'a';
end;

procedure GetType;
begin
	Typ := ' ';
	if Look = 'u' then begin
		Sign := 'u';
		Typ := 'i';
		GetChar;
		end
	else Sign := 's';
	if Look in ['i', 'l', 'c'] then begin
		Typ := Look;
		GetChar;
	end;
end;

procedure DoFunc(n: char);
begin
	Match('(');
	Match(')');
	Match('{');
	Match('}');
	if Typ = ' ' then Typ := 'i';
	WriteLn(Class, Sign, Typ, ' function ', n);
end;

procedure DoData(n: char);
begin
	if Typ = ' ' then Expected('Type declaration');
	WriteLn(Class, Sign, Typ, ' data ', n);
	while Look = ',' do begin
		Match(',');
		n := GetName;
		WriteLn(Class, Sign, Typ, ' data ', n);
	end;
	Match(';');
end;

procedure TopDecl;
var Name: char;
begin
	Name := GetName;
	if Look = '(' then
		DoFunc(Name)
	else
		DoData(Name);
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	while Look <> ^Z do begin
		GetClass;
		GetType;
		TopDecl;
	end;
end.
{--------------------------------------------------------------}
