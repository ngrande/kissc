{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }
const	TAB = ^I;
		CR = ^M;
		LF = ^J;

type	Symbol = string[8];
		SymTab = array[1..1000] of Symbol;
		TabPtr = ^SymTab;
		SymType = (IfSym, ElseSym, EndifSym, EndSym, Ident, Number, Operator_);

const KwList: array [1..4] of Symbol = ('IF', 'ELSE', 'ENDIF', 'END');

{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char; { Lookahead Character }
	Token: SymType;
	Value: string[16];

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

function IsOp(c: char): boolean;
begin
	IsOp := c in ['+', '-', '*', '/', '<', '>', ':', '='];
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
procedure GetName;
var k: integer;
begin
	Value := '';
	if not IsAlpha(Look) then Expected('Name');
	while IsAlNum(Look) do begin
		Value := Value + UpCase(Look);
		GetChar;
	end;
	k := Lookup(Addr(KwList), Value, 4);
	if k = 0 then
		Token := Ident
	else
		Token := SymType(k-1);
end;

{--------------------------------------------------------------}
{ Get a Number }
procedure GetNum;
begin
	Value := '';
	if not IsDigit(Look) then Expected('Integer');
	while IsDigit(Look) do begin
		Value := Value + Look;
		GetChar;
	end;
	Token := Number;
end;

procedure GetOp;
begin
	Value := '';
	if not IsOp(Look) then Expected('Operator');
	while IsOp(Look) do begin
		Value := Value + Look;
		GetChar;
	end;
	Token := Operator_;
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

procedure Scan;
var k: integer;
begin
	while Look = CR do
		Fin;

	if IsAlpha(Look) then
		GetName
	else if IsDigit(Look) then
		GetNum
	else if IsOp(Look) then
		GetOp
	else begin
		Value := Look;
		Token := Operator_;
		GetChar;
	end;
	SkipWhite;
end;

{--------------------------------------------------------------}
{ Main Program }
begin
	Init;
	repeat
		Scan;
		case Token of
			Ident: Write('Ident ');
			Number: Write('Number ');
			Operator_: Write('Operator');
			IfSym, ElseSym, EndifSym, EndSym: Write('Keyword ');
		end;
		WriteLn(Value);
	until Token = EndSym;
end.
{--------------------------------------------------------------}
