program Cradle;

const TAB = ^I;
const CR = ^M;

var look: char;

procedure GetChar;
begin
		Read(look);
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

procedure Match(x: char);
begin
		if look = x then GetChar
		else Expected('''' + x + '''');
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

function GetName: char;
begin
		if not IsAlpha(look) then Expected('Name');
		GetName := UpCase(look);
		GetChar;
end;

function GetNum: char;
begin
		if not IsDigit(look) then Expected('Integer');
		GetNum := look;
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
end;

procedure Expression; forward;

procedure Ident;
var Name: char;
begin
	Name := GetName;
	if look = '(' then begin
		Match('(');
		Match(')');
		EmitLn('BSR ' + Name);
		end
	else
		EmitLn('MOVE ' + Name + '(PC),D0')
end;

procedure Factor;
begin
	if look = '(' then begin
		Match('(');
		Expression;
		Match(')');
		end
	else if IsAlpha(look) then
		Ident
	else
		EmitLn('MOVE #' + GetNum + ',D0')
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
	EmitLn('DIVS D1,D0');
end;

procedure Term;
begin
	Factor;
	while look in ['*', '/'] do begin
		EmitLn('MOVE D0,-(SP)');
		case look of
		'*': Multiply;
		'/': Divide;
		else Expected('Mulop');
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
	if IsAddop(look) then
		EmitLn('CLR D0')
	else
		Term;
	while IsAddop(look) do begin
		EmitLn('MOVE D0,-(SP)');
		case look of
		'+': Add;
		'-': Subtract;
		else Expected('Addop');
		end;
	end;
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

{MAIN ENTRY POINT}
begin
		Init;
		Assignment;
	if look <> CR then Expected('Newline');
end.
