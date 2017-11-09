program KISS;

const	TAB = ^I;
		CR	= ^M;
		LF	= ^J;

type	Symbol = string[8];
		SymTab = array[1..1000] of Symbol;
		TabPtr = ^SymTab;

var		Look	: char;
		Token	: char;
		Value	: string[16];
		Lcount	: integer;

const	KWList: array[1..4] of Symbol = ('IF', 'ELSE', 'ENDIF', 'END');
		KWCode: string[5] = 'xilee';

procedure GetChar;
begin
	Read(Look);
end;

procedure Error(s: string);
begin
	WriteLn;
	WriteLn(^G, 'Error: ', s, '.');
end;

procedure Abort(s: string);
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
	IsDigit := c in ['0'..'9'];
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

function Lookup(T: TabPtr; s: string; n: integer): integer;
var i: integer;
	found: boolean;
begin
	found := false;
	i := n;
	while (i > 0) and not found do
		if s = T^[i] then
			found := true
		else
			dec(i);
	Lookup := i;
end;

procedure GetName;
begin
	while Look = CR do
		Fin;
	if not IsAlpha(Look) then Expected('Name');
	Value := '';
	while IsAlNum(Look) do begin
		Value := Value + UpCase(Look);
		GetChar;
	end;
	SkipWhite;
end;

procedure GetNum;
begin
	if not IsDigit(Look) then Expected('Integer');
	Value := '';
	while IsDigit(Look) do begin
		Value := Value + Look;
		GetChar;
	end;
	Token := '#';
	SkipWhite;
end;

procedure Scan;
begin
	GetName;
	Token := KWCode[Lookup(Addr(KWList), Value, 4) + 1];
end;

procedure MatchString(x: string);
begin
	if Value <> x then Expected('''' + x + '''');
end;

function NewLabel: string;
var s: string;
begin
	Str(LCount, s);
	NewLabel := 'L' + s;
	Inc(LCount);
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
begin
	GetName;
	if Look = '(' then begin
		Match('(');
		Match(')');
		EmitLn('BSR ' + Value);
		end
	else
		EmitLn('MOVE ' + Value + ' (PC),D0');
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
	else begin
		GetNum;
		EmitLn('MOVE #' + Value + ',D0');
	end;
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
	EmitLn('MULS (SP)-,D0');
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
	Condition;
	L1 := NewLabel;
	L2 := L1;
	EmitLn('BEQ ' + L1);
	Block;
	if Token = 'l' then begin
		L2 := NewLabel;
		EmitLn('BRA ' + L2);
		PostLabel(L1);
		Block;
	end;
	PostLabel(L2);
	MatchString('ENDIF');
end;

procedure Assignment;
var Name: string;
begin
	Name := Value;
	Match('=');
	Expression;
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
end;

procedure Block;
begin
	Scan;
	while not (Token in ['e', 'l']) do begin
		case Token of
		'i': DoIf;
		else Assignment;
		end;
		Scan;
	end;
end;

procedure DoProgram;
begin
	Block;
	MatchString('END');
	EmitLn('END');
end;

procedure Init;
begin
	LCount := 0;
	GetChar;
end;

begin
	Init;
	DoProgram;
end.
