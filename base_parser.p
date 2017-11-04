{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const TAB = ^I;

{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char; { Lookahead Character }

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

function IsAddop(c: char): boolean;
begin
	IsAddop := c in ['+', '-'];
end;

function IsOrop(c: char): boolean;
begin
	IsOrop := c in ['~', '|'];
end;

function IsBoolean(c: char): Boolean;
begin
	{T: True, F: False}
	IsBoolean := UpCase(c) in ['T', 'F'];
end;

function GetBoolean: Boolean;
begin
	if not IsBoolean(Look) then Expected('Boolean Literal');
	GetBoolean := UpCase(Look) = 'T';
	GetChar;
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

procedure Ident;
var Name: char;
begin
	Name := GetName;
	if Look = '(' then begin
		Match('(');
		MatcH(')');
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
begin
	if Look = '+' then
		GetChar;
	if Look = '-' then begin
		GetChar;
		if IsDigit(Look) then
			EmitLn('MOVE #-' + GetNum + ',D0')
		else begin
			Factor;
			EmitLn('NEG D0');
		end;
	end
	else Factor;
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

procedure Term;
begin
	SignedFactor;
	while Look in ['*', '/'] do begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		 '*': Multiply;
		 '/': Divide;
		end;
	end;
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
	Term;
	while IsAddop(Look) do begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		 '+': Add;
		 '-': Subtract;
		end;
	end;
end;

procedure Equals;
begin
	Match('=');
	Expression;
	EmitLn('CMP (SP)+,D0');
	EmitLn('SEQ D0');
end;

procedure NotEquals;
begin
	{ # is for != or <> - workaround because of the one char limitation }
	Match('#');
	Expression;
	EmitLn('CMP (SP)+,D0');
	EmitLn('SNE D0');
end;

procedure Less;
begin
	Match('<');
	Expression;
	EmitLn('CMP (SP)+,D0');
	EmitLn('SGE D0');
end;

procedure Greater;
begin
	Match('>');
	Expression;
	EmitLn('CMP (SP)+,D0');
	EmitLn('SLE D0');
end;

function IsRelop(c: char): boolean;
begin
	IsRelop := c in ['=', '#', '<', '>'];
end;

procedure Relation;
begin
	Expression;
	if IsRelop(Look) then begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		 '=': Equals;
		 '#': NotEquals;
		 '<': Less;
		 '>': Greater;
		end;
		EmitLn('TST D0');
	end;
end;

procedure BoolFactor;
begin
	if IsBoolean(Look) then
		if GetBoolean then
			{ -1 or FFFF for True }
			EmitLn('MOVE #-1,D0')
		else
			{ 0 for False }
			EmitLn('CLR D0')
	else Relation;
end;

procedure NotFactor;
begin
	if Look = '!' then begin
		Match('!');
		BoolFactor;
		EmitLn('EOR #-1,D0');
		end
	else
		BoolFactor;
end;

procedure BoolTerm;
begin
	NotFactor;
	while Look = '&' do begin
		EmitLn('MOVE D0,-(SP)');
		Match('&');
		NotFactor;
		EmitLn('AND (SP)+,D0');
	end;
end;

procedure BoolOr;
begin
	Match('|');
	BoolTerm;
	EmitLn('OR (SP)+,D0');
end;

procedure BoolXor;
begin
	Match('~');
	BoolTerm;
	EmitLn('EOR (SP)+,D0');
end;

procedure BoolExpression;
begin
	BoolTerm;
	while IsOrOp(Look) do begin
		EmitLn('MOVE D0,-(SP)');
		case Look of
		 '|': BoolOr;
		 '~': BoolXor;
		end;
	end;
end;

{--------------------------------------------------------------}
{ Initialize }
procedure Init;
begin
	GetChar;
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	BoolExpression;
end.
{--------------------------------------------------------------}
