program Cradle;

const TAB = ^I;
const CR = ^M;
const LF = ^J;
{const MAX_STR_LEN = 8;}

var Look: char;
Table: Array['A'..'Z'] of integer;

procedure InitTable;
var i: char;
begin
	for i := 'A' to 'Z' do
		Table[i] := 0;
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

function IsAddop(c: char): boolean;
begin
	IsAddop := c in ['+', '-'];
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

function IsWhite(c: char): boolean;
begin
	IsWhite := c in [' ', TAB];
end;

procedure GetChar;
begin
	Read(Look);
end;

procedure NewLine;
begin
	if Look = LF then begin
		GetChar;
		if Look = CR then
			GetChar;
	end;
end;

procedure SkipWhite;
begin
	while IsWhite(Look) do
		GetChar;
end;

procedure Match(x: char);
begin
	if Look <> x then Expected ('''' + x + '''')
	else begin
		GetChar;
		SkipWhite;
	end;
end;

function GetName: char;
begin
	if not IsAlpha(Look) then Expected('Name');
	GetName := UpCase(Look);
	GetChar;
	SkipWhite;
end;

function GetNum: integer;
var Value: integer;
begin
	Value := 0;
	if not IsDigit(Look) then Expected('Integer');
	while IsDigit(Look) do begin
		Value := 10 * Value + Ord(Look) - Ord('0');
		GetChar;
	end;
	GetNum := Value;
end;

function Expression: integer; Forward;

function Factor: integer;
begin
	if Look = '(' then begin
		Match('(');
		Factor := Expression;
		Match(')');
	end
	else if IsAlpha(Look) then
		Factor := Table[GetName]
	else
		Factor := GetNum;
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

procedure Init;
begin
	InitTable;
	GetChar;
	SkipWhite;
end;

{procedure Ident;
var Name: string[MAX_STR_LEN];
begin
	Name := GetName;
	if Look = '(' then begin
		Match('(');
		Match(')');
		EmitLn('BSR ' + Name);
		end
	else
		EmitLn('MOVE ' + Name + '(PC),D0')
end;}

{ Parse and translate a math term }
function Term: integer;
var Value: integer;
begin
	Value := Factor;
	while Look in ['*', '/'] do begin
		case Look of
			'*': begin
				Match('*');
				Value := Value * Factor;
			end;
			'/': begin
				Match('/');
				Value := Value div Factor;
			end;
		end;
	end;
	Term := Value;
end;

function Expression: integer;
var Value: integer;
begin
	if IsAddop(Look) then
		Value := 0
	else
		Value := Term;
	while IsAddop(Look) do begin
		case Look of
			'+': begin
				Match('+');
				Value := Value + Term;
			end;
			'-': begin
				Match('-');
				Value := Value - Term;
			end;
		end;
	end;
	Expression := Value;
end;

procedure Assignment;
var Name: char;
begin
	Name := GetName;
	Match('=');
	Table[Name] := Expression;
end;

procedure Input;
begin
	Match('?');
	Read(Table[GetName]);
end;

procedure Output;
begin
	Match('!');
	WriteLn(Table[GetName]);
end;

{MAIN ENTRY POINT}
begin
	Init;
	repeat
		case Look of
			'?': Input;
			'!': Output;
		else Assignment;
		end;
		NewLine;
	until Look = '.';
end.
