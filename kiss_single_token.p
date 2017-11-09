program KISS;

const	TAB = ^I;
		CR = ^M;
		LF = ^J;

type	Symbol = string[8];
		SymTab = array[1..1000] of Symbol;
		TabPtr = ^SymTab;

var Look: char;
	Lcount: integer;

procedure GetChar;
begin
	Read(Look);
end;

procedure Error(s: string);
begin
	WriteLn;
	WriteLn(^G, 'Error: ', s, '.');
end;

procedure Abort(s: string)
begin
	Error(s);
	Halt;
end;

procedure Expected(s: string);
begin
	Abort(s + ' Expected');
end;

function IsAlpha(c: char): boolean;
begin
	IsAlpha := UpCase(c) in ['A'..'Z'];
end;

function IsDigit(c: char): boolean;
begin
	IsDigit := c in [0..9];
end;

function IsAlNum(c: char): boolean;
begin
	IsAlNum := IsAlpha(c) or IsDigit(c);
end;

function IsAddop(c: char): boolean;
begin
	IsAddop := c in ['+', '-'];
end;

function IsMulop(c: char): boolean;
begin
	IsMulop := c in ['*', '/'];
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

procedure Match(x: char);
begin
	if Look <> x then Expected('''' + x + '''');
	GetChar;
	SkipWhite;
end;

procedure Fin;
begin
	if Look = CR then GetChar;
	if Look = LF then GetChar;
	SkipWhite;
end;

function GetName: char;
begin
	while Look = CR do
		Fin;
	if not IsAlpha(Look) then Expected('Name');
	GetName := UpCase(Look);
	GetChar;
	SkipWhite;
end;

function GetNum: char;
begin
	if not IsDigit(Look) then Expected('Integer');
	GetNum := Look;
	GetChar;
	SkipWhite;
end;

function NewLabel: string;
var s: string;
begin
	Str(Lcount, s);
	NewLabel := 'L' + s;
	Inc(Lcount);
end;

procedure PostLabel(L: string);
begin
	WriteLn(L, ':');
end;

procedure Emit(s: string);
begin
	Write(TAB, s);
end;

procedure EmitLn(s: string);
begin
	Emit(s);
	WriteLn;
end;

procedure Ident;
var Name: char;
begin
	Name := GetName;
	if Look = '(' then begin
		Match('(');
		Match(')');
		EmitLn('BSR ' + Name);
		end
	else
		EmitLn('MOVE ' + Name + '(PC),D0');
end;

procedure Expression; Forward;

procedure Factor;
begin
	if Look = '(' then begin
		Match('(');
		Expression;
		Match(')');
		end
	else if IsAlpha(Look) then
		Ident
	else
		EmitLn('MOVE #' + GetNum + ',D0');
end;

procedure SignedFactor;
var s: boolean;
begin
	s := Look = '-';
	if IsAddop(Look) then begin
		GetChar;
		SkipWhite;
	end;
	Factor;
	if s then
		EmitLn('NEG D0');
end;

procedure Multiply;
begin
	Match('*');
	Factor;
	EmitLn('MULS (SP)+,D0');
end;

procedure Divide;
begin
	Match('/');
	Factor;
	EmitLn('MOVE (SP)+,D1');
	EmitLn('EXS.L D0');
	EmitLn('DIVS D1,D0');
end;

procedure Term1;
begin
	while IsMulop(Look) do begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		'*': Multiply;
		'/': Divide;
		end;
	end;
end;

procedure Term;
begin
	Factor;
	Term1;
end;

procedure FirstTerm;
begin
	SignedFactor;
	Term1;
end;

procedure Add;
begin
	Match('+');
	Term;
	EmitLn('ADD (SP)+,D0');
end;

procedure Subtract;
begin
	Match('-');
	Term;
	EmitLn('SUB (SP)+,D0');
	EmitLn('NEG D0');
end;

procedure Expression;
begin
	FirstTerm;
	while IsAddop(Look) do begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		'+': Add;
		'-': Subtract;
		end;
	end;
end;

procedure Condition;
begin
	EmitLn('Condition');
end;

procedure Block; Forward;

procedure DoIf;
var L1, L2: string;
begin
	Match('i');
	Condition;
	L1 := NewLabel;
	L2 := L1;
	EmitLn('BEQ ' + L1);
	Block;
	if Look = 'l' then begin
		Match('l');
		L2 := NewLabel;
		EmitLn('BRA ' + L2);
		PostLabel(L1);
		Block;
	end;
	PostLabel(L2);
	Match('e');
end;

procedure Assignment;
var Name: char;
begin
	Name := GetName;
	Match('=');
	Expression;
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
end;

procedure Block;
begin
	while not (Look in ['e', 'l']) do begin
		case Look of
		'i': DoIf;
		CR: while Look = CR do
			Fin;
		else Assignment;
		end;
	end;
end;

procedure DoProgram;
begin
	Block;
	if Look <> 'e' then Expected('END');
	EmitLn('END');
end;

procedure Init;
begin
	Lcount := 0;
	GetChar;
end;

begin
	Init;
	DoProgram;
end.
