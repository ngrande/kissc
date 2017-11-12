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
	ST: array['A'..'Z'] of char;

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

function InTable(n: char): boolean;
begin
	InTable := ST[n] <> ' ';
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
function GetNum: integer;
var Val: integer;
begin
	Val := 0;
	if not IsDigit(Look) then Expected('Integer');
	while IsDigit(Look) do begin
		Val := 10 * Val + Ord(Look) - Ord('0');
		GetChar;
	end;
	GetNum := Val;
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
var i: char;
begin
	{ init symbol table }
	for i := 'A' to 'Z' do
		ST[i] := ' ';
	GetChar;
end;

procedure Undefined(n: string);
begin
	Abort('Undefined Identifier ' + n);
end;

procedure PostLabel(s: string);
begin
	WriteLn(s, ':');
end;

procedure Clear;
begin
	EmitLn('CLR D0');
end;

procedure Negate;
begin
	EmitLn('NEG D0');
end;

procedure LoadConst(n: integer);
begin
	Emit('MOVE #');
	WriteLn(n, ',D0');
end;

procedure LoadVar(Name: char);
begin
	if not InTable[Name] then Undefined(Name);
	EmitLn('MOVE ' + Name + ' (PC),D0');
end;

procedure Push;
begin
	EmitLn('MOVE D0,-(SP)');
end;

procedure PopAdd;
begin
	EmitLn('ADD (SP)+,D0');
end;

procedure PopSub;
begin
	EmitLn('SUB (SP)+,D0');
	EmitLn('NEG D0');
end;

procedure PopMul;
begin
	EmitLn('MULS (SP)+,D0');
end;

procedure PopDiv;
begin
	EmitLn('MOVE (SP)+,D7');
	EmitLn('EXT.L D7');
	EmitLn('DIVS D0,D7');
	EmitLn('MOVE D7,D0');
end;

procedure Store(Name: char);
begin
	if not InTable[Name] then Undefined(Name);
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
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

procedure Assignment;
begin
	GetChar;
end;

procedure Block;
begin
	while Look <> 'e' do
		Assignment;
end;

procedure Main;
begin
	Match('b');
	Prolog;
	Block;
	Match('e');
	Epilog;
end;

procedure Alloc(N: char);
begin
	if InTable(N) then Abort('Duplicate Variable Name ' + N);
	ST[N] := 'v';
	Write(N, ':', TAB, 'DC ');
	if Look = '=' then begin
		Match('=');
		if Look = '-' then begin
			Write(Look);
			Match('-');
		end;
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
