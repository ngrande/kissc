program Cradle;

const TAB = ^I;
const CR = ^M;
const MAX_STR_LEN = 8;

var Look: char;

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
	IsAlpha := upcase(c) in ['A'..'Z'];
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

function GetName: string;
var Token: string;
begin
	Token := '';
        if not IsAlpha(Look) then Expected('Name');
	while IsAlNum(Look) do begin
		Token := Token + UpCase(Look);
		GetChar;
	end;
        GetName := Token;
	SkipWhite;
end;

function GetNum: integer;
begin
	if not IsDigit(Look) then Expected('Integer');
	GetNum := Ord(Look) - Ord('0');
	GetChar;
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
	GetChar;
	SkipWhite;
end;

procedure Ident;
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
end;

function Expression: integer;
var Value: integer;
begin
	if IsAddop(Look) then
		Value := 0
	else
		Value := GetNum;
	while IsAddop(Look) do begin
		case Look of
			'+': begin
				Match('+');
				Value := Value + GetNum;
			end;
			'-': begin
				Match('-');
				Value := Value - GetNum;
			end;
		end;
	end;
	Expression := Value;
end;

procedure Assignment;
var Name: string[MAX_STR_LEN];
begin
	Name := GetName;
	Match('=');
	Expression;
	EmitLn('LEA ' + Name + '(PC),A0');
	EmitLn('MOVE D0,(A0)');
end;

{MAIN ENTRY POINT}
begin
	Init;
	//Assignment;
	Writeln(Expression);
	if Look <> CR then Expected('Newline');
end.
