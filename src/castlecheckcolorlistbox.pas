{
  Copyright (c) 2026 Serufu Yua
  --------------------------------------------------
}

{ Box with Text Lines, Check Boxes and Colors }
{ Set colors via property ListColors in hex format }

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
    FColorBox, FColorFrame: TCastleImagePersistent;
    FColors: Array of TCastleColor;
    FCheckList: Array of Boolean;
    FPressIndex: Integer;
    FCheckRect: TFloatRectangle;
    FCheckEmpty, FCheckChecked, FCheckPressedBG: TCastleImagePersistent;
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
    property ColorFrame: TCastleImagePersistent read FColorFrame;
    property CheckEmpty: TCastleImagePersistent read FCheckEmpty;
    property CheckChecked: TCastleImagePersistent read FCheckChecked;
    property CheckPressedBack: TCastleImagePersistent read FCheckPressedBG;
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

  FCheckEmpty:= TCastleImagePersistent.Create;
  FCheckChecked:= TCastleImagePersistent.Create;
  FCheckPressedBG:= TCastleImagePersistent.Create;
  FColorBox:= TCastleImagePersistent.Create;
  FColorFrame:= TCastleImagePersistent.Create;

  FColorBoxMargin:= TBorder.Create(nil);
  FColorBoxMargin.SetSubComponent(true);
end;

destructor TCastleCheckColorListBox.Destroy;
begin
  if Assigned(FCheckEmpty) then
    FreeAndNil(FCheckEmpty);

  if Assigned(FCheckChecked) then
    FreeAndNil(FCheckChecked);

  if Assigned(FCheckPressedBG) then
    FreeAndNil(FCheckPressedBG);

  if Assigned(FColorBox) then
    FreeAndNil(FColorBox);

  if Assigned(FColorFrame) then
    FreeAndNil(FColorFrame);

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
  FinalSquare, FinalBack, FinalColor, FinalColorFrame: TCastleImagePersistent;
  DrawColor: TCastleColor;
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
    DrawColor:= FCheckChecked.Color;
    if FCheckChecked.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareChecked]
    else
      FinalSquare:= FCheckChecked;
  end
  else
  begin
    DrawColor:= FCheckEmpty.Color;
    if FCheckEmpty.Empty then
      FinalSquare:= Theme.ImagesPersistent[tiSquareEmpty]
    else
      FinalSquare:= FCheckEmpty;
  end;

  FinalSquare.DrawUiBegin(UIScale);
  FinalSquare.Color:= DrawColor;
  FinalSquare.Draw(CheckRect);
  FinalSquare.DrawUiEnd;

  { Color Box }
  ColorAreaWidth:= FColorBoxWidth * UIScale;
  ColorBoxRect.Left:= ARect.Left + ARect.Height + FColorBoxMargin.TotalLeft;
  ColorBoxRect.Bottom:= ARect.Bottom + FColorBoxMargin.TotalBottom;
  ColorBoxRect.Width:= ColorAreaWidth - FColorBoxMargin.TotalWidth;
  ColorBoxRect.Height:= ARect.Height - FColorBoxMargin.TotalHeight;

  DrawColor:= FColors[AIndex] * FColorBox.Color;

  if FColorBox.Empty then
  begin
    DrawRectangle(ColorBoxRect, DrawColor);
  end
  else
  begin
    FinalColor:= FColorBox;
    FinalColor.DrawUiBegin(UIScale);
    FinalColor.Color:= DrawColor;
    FinalColor.Draw(ColorBoxRect);
    FinalColor.DrawUiEnd;
  end;

  { Color Box Frame }
  if FColorFrame.Empty then
  begin
    DrawRectangleOutline(ColorBoxRect, FColorFrame.Color, 2);
  end
  else
  begin
    FinalColorFrame:= FColorFrame;
    FinalColorFrame.DrawUiBegin(UIScale);
    FinalColorFrame.Color:= FColorFrame.Color;
    FinalColorFrame.Draw(ColorBoxRect);
    FinalColorFrame.DrawUiEnd;
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
  i, len: Integer;
begin
  inherited;

  { set Check list }
  SetLength(FCheckList, FList.Count);
  for i:= 0 to High(FCheckList) do
    FCheckList[i]:= True;

  { enlarge color list if needed }
  len:= FList.Count - FListColors.Count;
  if (len > 0) then
    for i:= 1 to len do
      FListColors.Add('FF00FF'); { Fuchsia }

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
  if ((AIndex > -1) AND (AIndex < FListColors.Count)) then
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
       'CheckEmpty', 'CheckChecked', 'CheckPressedBack', 'ColorBoxWidth',
       'ColorBoxMargin', 'ColorBox', 'ColorFrame', 'ListColors'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleCheckColorListBox, ['Seq', 'Check Color List Box']);
end.

