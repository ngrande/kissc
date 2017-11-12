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

procedure PostLabel(s: string);
begin
	WriteLn(s, ':');
end;

procedure Header;
begin
	{ what is needed to start the program on a SK*DOS machine }
	WriteLn('WARMST', TAB, 'EQU $A01E');
end;

procedure Prolog;
begin
	PostLabel('MAIN');
end;

procedure Epilog;
begin
	EmitLn('DC WARMST');
	EmitLn('END MAIN');
end;

procedure Main;
begin
	Match('b');
	Prolog;
	Match('e');
	Epilog;
end;

procedure Alloc(n: char);
begin
	Write(n, ':', TAB, 'DC ');
	if Look = '=' then begin
		Match('=');
		WriteLn(GetNum);
		end
	else
		WriteLn('0');
end;

procedure Decl;
var Name: char;
begin
	Match('v');
	Alloc(GetName);
	while Look = ',' do begin
		GetChar;
		Alloc(GetName);
	end;
end;

procedure TopDecls;
begin
	while Look <> 'b' do
		case Look of
		 'v': Decl;
		else Abort('Unrecognized Keyword ''' + Look + '''');
		end;
end;

procedure Prog;
begin
	Match('p');
	Header;
	TopDecls;
	Main;
	Match('.');
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	Prog;
	if Look <> CR then Abort('Unexpected data after ''.''');
end.
{--------------------------------------------------------------}
