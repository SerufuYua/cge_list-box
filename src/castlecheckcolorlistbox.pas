unit CastleCheckColorListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles, CastleGLImages,
  CastleKeysMouse, CastleVectors, CastleColors, CastleListBoxBase;

type
  TCheckEvent = procedure(Sender: TObject; AIndex: Integer; ACheck: Boolean) of object;

  TCastleCheckColorListBox = class(TCastleListBoxBase)
  protected
    FListColors: TStrings;
    FColorBoxWidth: Single;
    FColorBoxMargin: TBorder;
    FColorBox: TCastleImagePersistent;
    FColors: Array of TCastleColor;
    FCheckList: Array of Boolean;
    FPressIndex: Integer;
    FCheckRect: TFloatRectangle;
    FSquareEmpty, FSquareChecked, FSquarePressedBG: TCastleImagePersistent;
    FOnCheck: TCheckEvent;
    procedure SetListColors(const AValue: TStrings);
    procedure ListColorsChange(Sender: TObject);
    procedure ListChange(Sender: TObject); override;
    procedure UpdateColors;
    procedure CalcRectangles; override;
    procedure DoCheck(const AIndex: Integer; const ACheck: Boolean);
  public
    const
      DefaultColorBoxWidth = 24;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Press(const Event: TInputPressRelease): boolean; override;
    function Release(const Event: TInputPressRelease): boolean; override;
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    procedure SetCheck(const AIndex: Integer; const ACheck: Boolean);
    function GetCheck(const AIndex: Integer): Boolean;
    procedure SetColor(const AIndex: Integer; const AValue: TCastleColor);
    function GetColor(const AIndex: Integer): TCastleColor;
  published
    property ListColors: TStrings read FListColors write SetListColors;
    property ColorBoxWidth: Single read FColorBoxWidth write FColorBoxWidth
             {$ifdef FPC}default DefaultColorBoxWidth{$endif};
    property ColorBoxMargin: TBorder read FColorBoxMargin;
    property ColorBox: TCastleImagePersistent read FColorBox;
    property SquareEmpty: TCastleImagePersistent read FSquareEmpty;
    property SquareChecked: TCastleImagePersistent read FSquareChecked;
    property SquarePressedBack: TCastleImagePersistent read FSquarePressedBG;
    property OnCheck: TCheckEvent read FOnCheck write FOnCheck;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils, CastleUIControls, CastleGLUtils, Math;

constructor TCastleCheckColorListBox.Create(AOwner: TComponent);
begin
  inherited;

  FOnCheck:= nil;
  FPressIndex:= -1;
  FColorBoxWidth:= DefaultColorBoxWidth;

  FListColors:= TStringList.Create;
  TStringList(FListColors).OnChange:= {$ifdef FPC}@{$endif}ListColorsChange;

  FSquareEmpty:= TCastleImagePersistent.Create;
  FSquareChecked:= TCastleImagePersistent.Create;
  FSquarePressedBG:= TCastleImagePersistent.Create;
  FColorBox:= TCastleImagePersistent.Create;

  FColorBoxMargin:= TBorder.Create(nil);
  FColorBoxMargin.SetSubComponent(true);
end;

destructor TCastleCheckColorListBox.Destroy;
begin
  if Assigned(FSquareEmpty) then
    FreeAndNil(FSquareEmpty);

  if Assigned(FSquareChecked) then
    FreeAndNil(FSquareChecked);

  if Assigned(FSquarePressedBG) then
    FreeAndNil(FSquarePressedBG);

  if Assigned(FColorBox) then
    FreeAndNil(FColorBox);

  if Assigned(FColorBoxMargin) then
    FreeAndNil(FColorBoxMargin);

  if Assigned(FListColors) then
    FreeAndNil(FListColors);

  inherited;
end;

function TCastleCheckColorListBox.Press(const Event: TInputPressRelease): boolean;
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


function TCastleCheckColorListBox.Release(const Event: TInputPressRelease): boolean;
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

procedure TCastleCheckColorListBox.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
var
  FinalSquare, FinalBack: TCastleImagePersistent;
  SquareColor: TCastleColor;
  i, len: Integer;
  CheckRect, ColorBoxRect, TextRect: TFloatRectangle;
  Text: String;
  si, ColorAreaWidth: Single;
begin
  { CheckBox }
  CheckRect.Height:= Font.Height;
  CheckRect.Width:= CheckRect.Height;
  CheckRect.Bottom:= ARect.Bottom + (ARect.Height - CheckRect.Height) / 2.0;
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

  { Color Box }
  ColorAreaWidth:= FColorBoxWidth * UIScale;
  ColorBoxRect.Left:= ARect.Left + ARect.Height + FColorBoxMargin.TotalLeft;
  ColorBoxRect.Bottom:= ARect.Bottom + FColorBoxMargin.TotalBottom;
  ColorBoxRect.Width:= ColorAreaWidth - FColorBoxMargin.TotalWidth;
  ColorBoxRect.Height:= ARect.Height - FColorBoxMargin.TotalHeight;

  if FColorBox.Empty then
  begin
    DrawRectangle(ColorBoxRect, FColors[AIndex]);
    DrawRectangleOutline(ColorBoxRect, FColorBox.Color, 2);
  end
  else
  begin
    FColorBox.DrawUiBegin(UIScale);
    FColorBox.Color:= FColors[AIndex];
    FColorBox.Draw(ColorBoxRect);
    FColorBox.DrawUiEnd;
  end;

  { Text }
  si:= ARect.Height + ColorAreaWidth + FTextMargin * UIScale;
  TextRect:= ARect.RightPart(ARect.Width - si);

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

procedure TCastleCheckColorListBox.SetListColors(const AValue: TStrings);
begin
  FListColors.Assign(AValue);
end;

procedure TCastleCheckColorListBox.ListColorsChange(Sender: TObject);
begin
  UpdateColors;
end;

procedure TCastleCheckColorListBox.ListChange(Sender: TObject);
var
  i: Integer;
begin
  inherited;

  SetLength(FCheckList, FList.Count);
  for i:= 0 to High(FCheckList) do
    FCheckList[i]:= True;

  UpdateColors;
end;

procedure TCastleCheckColorListBox.UpdateColors;
var
  i: Integer;
begin
  SetLength(FColors, Math.Max(FList.Count, FListColors.Count));
  for i:= 0 to (FListColors.Count - 1) do
    FColors[i]:= HexToColor(FListColors[i]);
end;

procedure TCastleCheckColorListBox.CalcRectangles;
begin
  inherited;

  { move area }
  FClickRect:= FMoveRect.RightPart(FMoveRect.Width - FLineHeight);

  { check area }
  FCheckRect:= FMoveRect.LeftPart(FLineHeight);
end;

procedure TCastleCheckColorListBox.SetCheck(const AIndex: Integer; const ACheck: Boolean);
begin
  if ((AIndex > -1) AND (AIndex <= High(FCheckList))) then
    FCheckList[AIndex]:= ACheck;
end;

function TCastleCheckColorListBox.GetCheck(const AIndex: Integer): Boolean;
begin
  if ((AIndex > -1) AND (AIndex <= High(FCheckList))) then
    Result:= FCheckList[AIndex]
  else
    Result:= False;
end;

procedure TCastleCheckColorListBox.SetColor(const AIndex: Integer; const AValue: TCastleColor);
begin
  if ((AIndex > -1) AND (AIndex < FList.Count)) then
    FListColors[AIndex]:= ColorToHex(AValue);
end;

function TCastleCheckColorListBox.GetColor(const AIndex: Integer): TCastleColor;
begin
  if ((AIndex > -1) AND (AIndex < FList.Count)) then
    Result:= FColors[AIndex]
  else
    Result:= Fuchsia;
end;

procedure TCastleCheckColorListBox.DoCheck(const AIndex: Integer; const ACheck: Boolean);
begin
  if Assigned(OnCheck) then
    OnCheck(Self, AIndex, ACheck);
end;

function TCastleCheckColorListBox.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'SquareEmpty', 'SquareChecked', 'SquarePressedBack', 'ColorBoxWidth',
       'ColorBoxMargin', 'ColorBox', 'ListColors'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleCheckColorListBox, ['Seq', 'Check Color List Box']);
end.

