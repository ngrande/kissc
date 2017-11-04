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
	LCount := 0;
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

procedure Condition;
begin
	{ Dummy output }
	EmitLn('<condition>');
end;

procedure Block(L: string); Forward;

procedure DoIf(L: string);
var L1, L2: string;
begin
	Match('i');
	Condition;
	L1 := NewLabel;
	L2 := L1;
	EmitLn('BEQ ' + L1);
	Block(L);
	if Look = 'l' then begin
		Match('l');
		L2 := NewLabel;
		EmitLn('BRA ' + L2);
		PostLabel(L1);
		Block(L);
	end;
	Match('e');
	PostLabel(L2);
end;

procedure DoWhile;
var L1, L2: string;
begin
	Match('w');
	L1 := NewLabel;
	L2 := NewLabel;
	PostLabel(L1);
	Condition;
	EmitLn('BEQ ' + L2);
	Block(L2);
	Match('e');
	EmitLn('BRA ' + L1);
	PostLabel(L2);
end;

procedure DoLoop;
var L1, L2: string;
begin
	Match('p');
	L1 := NewLabel;
	L2 := NewLabel;
	PostLabel(L1);
	Block(L2);
	Match('e');
	EmitLn('BRA ' + L1);
	PostLabel(L2);
end;

procedure DoRepeat;
var L1, L2: string;
begin
	Match('r');
	L1 := NewLabel;
	L2 := NewLabel;
	PostLabel(L1);
	Block(L2);
	Match('u');
	Condition;
	EmitLn('BEQ ' + L1);
	PostLabel(L2);
end;

procedure Expression;
begin
	{ saves the expression to D0 - dont get confused by DoFor using D0 because of that }
	EmitLn('<expr>');
end;

procedure DoFor;
var L1, L2: string;
	Name: char;
begin
	Match('f');
	L1 := NewLabel;
	L2 := NewLabel;
	Name := GetName;
	Match('=');
	Expression;
	EmitLn('SUBQ #1,D0');
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
	Expression;
	EmitLn('MOVE D0,-(SP)');
	PostLabel(L1);
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE (A0),D0');
	EmitLn('ADDQ #1,D0');
	EmitLn('MOVE D0,(A0)');
	EmitLn('CMP (SP),D0');
	EmitLn('BGT ' + L2);
	Block(L2);
	Match('e');
	EmitLn('BRA ' + L1);
	PostLabel(L2);
	EmitLn('ADDQ #2,SP');
end;

procedure DoDo;
var L1, L2: string;
begin
	Match('d');
	L1 := NewLabel;
	L2 := NewLabel;
	Expression;
	EmitLn('SUBQ #1,D0');
	PostLabel(L1);
	EmitLn('MOVE D0,-(SP)');
	Block(L2);
	EmitLn('MOVE (SP)+,D0');
	EmitLn('DBRA D0,' + L1);
	EmitLn('SUBQ #2,SP');
	PostLabel(L2);
	EmitLn('ADDQ #2,SP');
end;

procedure Other;
begin
	EmitLn(GetName);
end;

procedure DoBreak(L: string);
begin
	Match('b');
	if L <> '' then
		EmitLn('BRA ' + L)
	else Abort('No loop to break from');
end;

procedure Block(L: string);
begin
	while not(Look in ['e', 'l', 'u']) do begin
		case Look of
			'i': DoIf(L);
			'w': DoWhile;
			'p': DoLoop;
			'r': DoRepeat;
			'f': DoFor;
			'd': DoDo;
			'b': DoBreak(L);
			else Other;
		end;
	end;
end;

procedure DoProgram;
begin
	Block('');
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
