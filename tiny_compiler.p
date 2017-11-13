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
	LCount: integer;

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

function IsMulop(c: char): boolean;
begin
	IsMulop := c in ['*', '/'];
end;

function IsAddop(c: char): boolean;
begin
	IsAddop := c in ['+', '-'];
end;

function IsOrop(c: char): boolean;
begin
	IsOrop := c in ['|', '~'];
end;

function IsRelop(c: char): boolean;
begin
	IsRelop := c in ['=', '#', '<', '>'];
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
	LCount := 0;
	{ init symbol table }
	for i := 'A' to 'Z' do
		ST[i] := ' ';
	GetChar;
end;

procedure Undefined(n: string);
begin
	Abort('Undefined Identifier ' + n);
end;

function NewLabel: string;
var S: string;
begin
	Str(LCount, S);
	NewLabel := 'L' + S;
	Inc(LCount);
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
	if not InTable(Name) then Undefined(Name);
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
	if not InTable(Name) then Undefined(Name);
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
end;

procedure NotIt;
begin
	EmitLn('NOT D0');
end;

procedure PopAnd;
begin
	EmitLn('AND (SP)+,D0');
end;

procedure PopOr;
begin
	EmitLn('OR (SP)+,D0');
end;

procedure PopXor;
begin
	EmitLn('EOR (SP)+,D0');
end;

procedure PopCompare;
begin
	EmitLn('CMP (SP)+,D0');
end;

procedure SetEqual;
begin
	EmitLn('SEQ D0');
	EmitLn('EXT D0');
end;

procedure SetNEqual;
begin
	EmitLn('SNE D0');
	EmitLn('EXT D0');
end;

procedure SetGreater;
begin
	EmitLn('SLT D0');
	EmitLn('EXT D0');
end;

procedure SetLess;
begin
	EmitLn('SGT D0');
	EmitLn('EXT D0');
end;

procedure Branch(L: string);
begin
	EmitLn('BRA ' + L);
end;

procedure BranchFalse(L: string);
begin
	EmitLn('TST D0');
	EmitLn('BEQ ' + L);
end;

procedure BoolExpression; Forward;

procedure Block; Forward;

procedure DoIf;
var L1, L2: string;
begin
	Match('i');
	BoolExpression;
	L1 := NewLabel;
	L2 := L1;
	BranchFalse(L1);
	Block;
	if Look = 'l' then begin
		Match('l');
		L2 := NewLabel;
		Branch(L2);
		PostLabel(L1);
		Block;
	end;
	PostLabel(L2);
	Match('e');
end;

procedure DoWhile;
var L1, L2: string;
begin
	Match('w');
	L1 := NewLabel;
	L2 := NewLabel;
	PostLabel(L1);
	BoolExpression;
	BranchFalse(L2);
	Block;
	Match('e');
	Branch(L1);
	PostLabel(L2);
end;

procedure Factor;
begin
	if Look = '(' then begin
		Match('(');
		BoolExpression;
		Match(')');
		end
	else if IsAlpha(Look) then
		LoadVar(GetName)
	else
		LoadConst(GetNum);
end;

procedure NegFactor;
begin
	Match('-');
	if IsDigit(Look) then
		LoadConst(-GetNum)
	else begin
		Factor;
		Negate;
	end;
end;

procedure FirstFactor;
begin
	case Look of
	 '+':	begin
				Match('+');
				Factor;
			end;
	 '-': NegFactor;
	 else Factor;
	end;
 end;

 procedure Multiply;
 begin
	 Match('*');
	 Factor;
	 PopMul;
 end;

 procedure Divide;
 begin
	 Match('/');
	 Factor;
	 PopDiv;
 end;

 procedure Term1;
 begin
	 while IsMulop(Look) do begin
		 Push;
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
	FirstFactor;
	Term1;
end;

procedure Add;
begin
	Match('+');
	Term;
	PopAdd;
end;

procedure Subtract;
begin
	Match('-');
	Term;
	PopSub;
end;

procedure Expression;
begin
	FirstTerm;
	while IsAddop(Look) do begin
		Push;
		case Look of
		 '+': Add;
		 '-': Subtract;
		end;
	end;
end;

procedure Assignment;
var Name: char;
begin
	Name := GetName;
	Match('=');
	BoolExpression;
	Store(Name);
end;

procedure Block;
begin
	while not(Look in ['e', 'l']) do begin
		case Look of
		 'i': DoIf;
		 'w': DoWhile;
		else Assignment;
		end;
	end;
end;

procedure Equals;
begin
	Match('=');
	Expression;
	PopCompare;
	SetEqual;
end;

procedure NotEquals;
begin
	Match('#');
	Expression;
	PopCompare;
	SetNEqual;
end;

procedure Less;
begin
	Match('<');
	Expression;
	PopCompare;
	SetLess;
end;

procedure Greater;
begin
	Match('>');
	Expression;
	PopCompare;
	SetGreater;
end;

procedure Relation;
begin
	Expression;
	if IsRelop(Look) then begin
		Push;
		case Look of
		 '=': Equals;
		 '#': NotEquals;
		 '<': Less;
		 '>': Greater;
		end;
	end;
end;

procedure NotFactor;
begin
	if Look = '!' then begin
		Match('!');
		Relation;
		NotIt;
		end
	else
		Relation;
end;

procedure BoolTerm;
begin
	NotFactor;
	while Look = '&' do begin
		Push;
		Match('&');
		NotFactor;
		PopAnd;
	end;
end;

procedure BoolOr;
begin
	Match('|');
	BoolTerm;
	PopOr;
end;

procedure BoolXor;
begin
	Match('~');
	BoolTerm;
	PopXor;
end;

procedure BoolExpression;
begin
	BoolTerm;
	while IsOrop(Look) do begin
		Push;
		case Look of
		 '|': BoolOr;
		 '~': BoolXor;
		end;
	end;
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
