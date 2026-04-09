{
  Copyright (c) 2026 Serufu Yua
  --------------------------------------------------
}

{ Box with Text Lines and Check Boxes }


unit CastleCheckListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles, CastleGLImages,
  CastleKeysMouse, CastleListBoxBase;

type
  TCheckEvent = procedure(Sender: TObject; AIndex: Integer; ACheck: Boolean) of object;

  TCastleCheckListBox = class(TCastleListBoxBase)
  protected
    FCheckList: Array of Boolean;
    FPressIndex: Integer;
    FCheckRect: TFloatRectangle;
    FCheckEmpty, FCheckChecked, FCheckPressedBG: TCastleImagePersistent;
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
    property CheckEmpty: TCastleImagePersistent read FCheckEmpty;
    property CheckChecked: TCastleImagePersistent read FCheckChecked;
    property CheckPressedBack: TCastleImagePersistent read FCheckPressedBG;
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
  FCheckEmpty:= TCastleImagePersistent.Create;
  FCheckChecked:= TCastleImagePersistent.Create;
  FCheckPressedBG:= TCastleImagePersistent.Create;
end;

destructor TCastleCheckListBox.Destroy;
begin
  if Assigned(FCheckEmpty) then
    FreeAndNil(FCheckEmpty);

  if Assigned(FCheckChecked) then
    FreeAndNil(FCheckChecked);

  if Assigned(FCheckPressedBG) then
    FreeAndNil(FCheckPressedBG);

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
  end
  else
  if (Event.EventType = itKey) then
  begin
    if Event.IsKey(keySpace) then
    begin
      FCheckList[Index]:= NOT FCheckList[Index];
      DoCheck(Index, FCheckList[Index]);
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
    if FCheckPressedBG.Empty then
      FinalBack:= Theme.ImagesPersistent[tiSquarePressedBackground]
    else
      FinalBack:= FCheckPressedBG;

    FinalBack.DrawUiBegin(UIScale);
    FinalBack.Color:= FCheckPressedBG.Color;
    FinalBack.Draw(CheckRect);
    FinalBack.DrawUiEnd;
  end;


  { CheckBox Square }
  if FCheckList[AIndex] then
  begin
    SquareColor:= FCheckChecked.Color;
    if FCheckChecked.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareChecked]
    else
      FinalSquare:= FCheckChecked;
  end
  else
  begin
    SquareColor:= FCheckEmpty.Color;
    if FCheckEmpty.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareEmpty]
    else
      FinalSquare:= FCheckEmpty;
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
begin
  inherited;

  { set Check list }
  SetLength(FCheckList, FList.Count);
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
       'CheckRight', 'CheckEmpty', 'CheckChecked', 'CheckPressedBack'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleCheckListBox, ['List', 'Check List Box']);
end.

