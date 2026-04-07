unit CastleCheckListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles, CastleGLImages,
  CastleKeysMouse, CastleListBox;

type
  TCheckEvent = procedure(Sender: TObject; AIndex: Integer; ACheck: Boolean) of object;

  TCastleCheckListBox = class(TCastleListBox)
  protected
    FCheckList: Array of Boolean;
    FPressIndex: Integer;
    FCheckRect: TFloatRectangle;
    FSquareEmpty, FSquareChecked, FSquarePressedBG: TCastleImagePersistent;
    FCheckRight: Boolean;
    FOnCheck: TCheckEvent;
    procedure ListChange(Sender: TObject); override;
    procedure CalcRectangles; override;
    procedure DoCheck(const AIndex: Integer; const ACheck: Boolean);
  public
  const
    DefaultCheckRight = False;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Press(const Event: TInputPressRelease): boolean; override;
    function Release(const Event: TInputPressRelease): boolean; override;
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    procedure SetCheck(const AIndex: Integer; const ACheck: Boolean);
    function GetCheck(const AIndex: Integer): Boolean;
  published
    property CheckRight: Boolean read FCheckRight write FCheckRight
             {$ifdef FPC}default DefaultCheckRight{$endif};
    property SquareEmpty: TCastleImagePersistent read FSquareEmpty;
    property SquareChecked: TCastleImagePersistent read FSquareChecked;
    property SquarePressedBack: TCastleImagePersistent read FSquarePressedBG;
    property OnCheck: TCheckEvent read FOnCheck write FOnCheck;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils, CastleUIControls, CastleColors
  {$if defined(CASTLE_DESIGN_MODE)}
  , CastleGLUtils
  {$endif};

constructor TCastleCheckListBox.Create(AOwner: TComponent);
begin
  inherited;

  FOnCheck:= nil;
  FPressIndex:= -1;
  FCheckRight:= DefaultCheckRight;
  FSquareEmpty:= TCastleImagePersistent.Create;
  FSquareChecked:= TCastleImagePersistent.Create;
  FSquarePressedBG:= TCastleImagePersistent.Create;
end;

destructor TCastleCheckListBox.Destroy;
begin
  if Assigned(FSquareEmpty) then
    FreeAndNil(FSquareEmpty);

  if Assigned(FSquareChecked) then
    FreeAndNil(FSquareChecked);

  if Assigned(FSquarePressedBG) then
    FreeAndNil(FSquarePressedBG);

  inherited;
end;

function TCastleCheckListBox.Press(const Event: TInputPressRelease): boolean;
var
  h: Single;
begin
  Result:= inherited;
  if Result then Exit;

  if (Event.EventType = itMouseButton) then
  begin
    Result:= True;

    if FCheckRect.Contains(Event.Position) then
    begin
      h:= FAreaRect.Height - (Event.Position.Y - FAreaRect.Bottom);
      FPressIndex:= Trunc(h / FLineHeight);
    end;
  end;
end;


function TCastleCheckListBox.Release(const Event: TInputPressRelease): boolean;
var
  h: Single;
  i: Integer;
begin
  Result:= inherited;
  if Result or (Event.EventType <> itMouseButton) then Exit;

  FPressIndex:= -1;
  if ((NOT FMoveStarted) AND FCheckRect.Contains(Event.Position)) then
  begin
    Result:= True;
    h:= FAreaRect.Height - (Event.Position.Y - FAreaRect.Bottom);
    i:= Trunc(h / FLineHeight);
    FCheckList[i]:= NOT FCheckList[i];
    DoCheck(i, FCheckList[i]);
  end;
end;

procedure TCastleCheckListBox.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
var
  FinalSquare, FinalBack: TCastleImagePersistent;
  SquareColor: TCastleColor;
  i, len: Integer;
  CheckRect, TextRect: TFloatRectangle;
  Text: String;
  si: Single;
begin
  { CheckBox }
  CheckRect.Height:= Font.Height;
  CheckRect.Width:= CheckRect.Height;
  CheckRect.Bottom:= ARect.Bottom + (ARect.Height - CheckRect.Height) / 2.0;

  if FCheckRight then
    CheckRect.Left:= ARect.Right - ARect.Height + (ARect.Height - CheckRect.Width) / 2.0
  else
    CheckRect.Left:= ARect.Left + (ARect.Height - CheckRect.Width) / 2.0;

  { CheckBox Background }
  if (AIndex = FPressIndex) then
  begin
    if FSquarePressedBG.Empty then
      FinalBack:= Theme.ImagesPersistent[tiSquarePressedBackground]
    else
      FinalBack:= FSquarePressedBG;

    FinalBack.DrawUiBegin(UIScale);
    FinalBack.Color:= FSquarePressedBG.Color;
    FinalBack.Draw(CheckRect);
    FinalBack.DrawUiEnd;
  end;


  { CheckBox Square }
  if FCheckList[AIndex] then
  begin
    SquareColor:= FSquareChecked.Color;
    if FSquareChecked.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareChecked]
    else
      FinalSquare:= FSquareChecked;
  end
  else
  begin
    SquareColor:= FSquareEmpty.Color;
    if FSquareEmpty.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareEmpty]
    else
      FinalSquare:= FSquareEmpty;
  end;

  FinalSquare.DrawUiBegin(UIScale);
  FinalSquare.Color:= SquareColor;
  FinalSquare.Draw(CheckRect);
  FinalSquare.DrawUiEnd;

  { Text }
  if FCheckRight then
  begin
    si:= FTextMargin * UIScale;
    TextRect.Left:= ARect.Left + si;
    TextRect.Width:= ARect.Width - si - ARect.Height;
    TextRect.Bottom:= ARect.Bottom;
    TextRect.Height:= ARect.Height;
  end
  else
  begin
    si:= ARect.Height + FTextMargin * UIScale;
    TextRect:= ARect.RightPart(ARect.Width - si);
  end;

  { adjust Text length to line width }
  Text:= FList[AIndex];
  len:= Length(Text);
  for i:= 1 to len do
    if (Font.TextWidth(Text) > TextRect.Width) then
      SetLength(Text, Length(Text) - 1)
    else
      Break;

  Font.PrintRect(TextRect, Color, Text, hpLeft, vpMiddle);

  {$if defined(CASTLE_DESIGN_MODE)}
  DrawRectangleOutline(TextRect, Orange, 1);
  {$endif}
end;

procedure TCastleCheckListBox.ListChange(Sender: TObject);
var
  i: Integer;
begin
  inherited;

  SetLength(FCheckList, FList.Count);
  for i:= 0 to High(FCheckList) do
    FCheckList[i]:= True;
end;

procedure TCastleCheckListBox.CalcRectangles;
begin
  inherited;

  { move area }
  if FCheckRight then
    FClickRect:= FMoveRect.LeftPart(FMoveRect.Width - FLineHeight)
  else
    FClickRect:= FMoveRect.RightPart(FMoveRect.Width - FLineHeight);

  { check area }
  if FCheckRight then
    FCheckRect:= FMoveRect.RightPart(FLineHeight)
  else
    FCheckRect:= FMoveRect.LeftPart(FLineHeight);
end;

procedure TCastleCheckListBox.SetCheck(const AIndex: Integer; const ACheck: Boolean);
begin
  if ((AIndex > -1) AND (AIndex <= High(FCheckList))) then
    FCheckList[AIndex]:= ACheck;
end;

function TCastleCheckListBox.GetCheck(const AIndex: Integer): Boolean;
begin
  if ((AIndex > -1) AND (AIndex <= High(FCheckList))) then
    Result:= FCheckList[AIndex]
  else
    Result:= False;
end;

procedure TCastleCheckListBox.DoCheck(const AIndex: Integer; const ACheck: Boolean);
begin
  if Assigned(OnCheck) then
    OnCheck(Self, AIndex, ACheck);
end;

function TCastleCheckListBox.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'CheckRight', 'SquareEmpty', 'SquareChecked', 'SquarePressedBack'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleCheckListBox, ['Seq', 'Check List Box']);
end.

