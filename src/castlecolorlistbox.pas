{
  Copyright (c) 2026 Serufu Yua
  --------------------------------------------------
}

{ List Box with Colors }
{ Set colors via property List in hex format }

unit CastleColorListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles,
  CastleGLImages, CastleVectors, CastleColors, CastleListBoxBase;

type
  TCastleColorListBox = class(TCastleListBoxBase)
  protected
    FColors: Array of TCastleColor;
    FShowText, FShowTextLeft: Boolean;
    FTextWidth: Single;
    FColorBox, FColorFrame: TCastleImagePersistent;
    FColorBoxMargin: TBorder;
    procedure ListChange(Sender: TObject); override;
    procedure CalcTextWidth;
  public
    const
      DefaultShowText = False;
      DefaultShowTextLeft = False;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FontChanged; override;
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    procedure SetColor(const AIndex: Integer; const AValue: TCastleColor);
    function GetColor(const AIndex: Integer): TCastleColor;
  published
    property ShowText: Boolean read FShowText write FShowText
             {$ifdef FPC}default DefaultShowText{$endif};
    property ShowTextLeft: Boolean read FShowTextLeft write FShowTextLeft
             {$ifdef FPC}default DefaultShowTextLeft{$endif};
    property ColorBox: TCastleImagePersistent read FColorBox;
    property ColorFrame: TCastleImagePersistent read FColorFrame;
    property ColorBoxMargin: TBorder read FColorBoxMargin;
end;

implementation

uses
  CastleComponentSerialize, CastleUtils, CastleGLUtils;

constructor TCastleColorListBox.Create(AOwner: TComponent);
begin
  inherited;

  FTextWidth:= 0.0;
  FShowText:= DefaultShowText;
  FShowTextLeft:= DefaultShowTextLeft;

  FColorBox:= TCastleImagePersistent.Create;
  FColorFrame:= TCastleImagePersistent.Create;

  FColorBoxMargin:= TBorder.Create(nil);
  FColorBoxMargin.SetSubComponent(true);
end;

destructor TCastleColorListBox.Destroy;
begin
  if Assigned(FColorBox) then
    FreeAndNil(FColorBox);

  if Assigned(FColorFrame) then
    FreeAndNil(FColorFrame);

  if Assigned(FColorBoxMargin) then
    FreeAndNil(FColorBoxMargin);

  inherited;
end;

procedure TCastleColorListBox.FontChanged;
begin
  inherited;
  CalcTextWidth;
end;

procedure TCastleColorListBox.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
var
  FinalColor, FinalColorFrame: TCastleImagePersistent;
  DrawColor: TCastleColor;
  TextRect, ColorBoxRect: TFloatRectangle;
  Text: String;
  NeedText: Boolean;
  si: Single;
begin
  inherited;
  si:= FTextMargin * UIScale;
  NeedText:= FShowText AND (ARect.Width > (ARect.Height + FTextWidth + 2.0 * si));

  { color box }
  if NeedText then
  begin
    { text }
    if FShowTextLeft then
    begin
      TextRect:= ARect.LeftPart(FTextWidth);
      TextRect.Left:= TextRect.Left + si;
    end
    else
    begin
      TextRect:= ARect.RightPart(FTextWidth);
      TextRect.Left:= TextRect.Left - si;
    end;

    Text:= '#' + FList[AIndex];
    Font.PrintRect(TextRect, Color, Text, hpLeft, vpMiddle);

    {$if defined(CASTLE_DESIGN_MODE)}
    DrawRectangleOutline(TextRect, Orange, 1);
    {$endif}

    { color box rectangle }
    if FShowTextLeft then
      ColorBoxRect:= ARect.RightPart(ARect.Width - FTextWidth - 2.0 * si)
    else
      ColorBoxRect:= ARect.LeftPart(ARect.Width - FTextWidth - 2.0 * si);
  end
  else
    ColorBoxRect:= ARect;

  ColorBoxRect.Left:= ColorBoxRect.Left + FColorBoxMargin.TotalLeft;
  ColorBoxRect.Bottom:= ColorBoxRect.Bottom + FColorBoxMargin.TotalBottom;
  ColorBoxRect.Width:= ColorBoxRect.Width - FColorBoxMargin.TotalWidth;
  ColorBoxRect.Height:= ColorBoxRect.Height - FColorBoxMargin.TotalHeight;

  { Color Box }
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
end;

procedure TCastleColorListBox.ListChange(Sender: TObject);
var
  i: Integer;
begin
  inherited;

  { prepare colors }
  SetLength(FColors, FList.Count);
  for i:= 0 to (FList.Count - 1) do
    FColors[i]:= HexToColor(FList[i]);

  CalcTextWidth;
end;

procedure TCastleColorListBox.SetColor(const AIndex: Integer; const AValue: TCastleColor);
begin
  if ((AIndex > -1) AND (AIndex < FList.Count)) then
    FList[AIndex]:= ColorToHex(AValue);
end;

function TCastleColorListBox.GetColor(const AIndex: Integer): TCastleColor;
begin
  if ((AIndex > -1) AND (AIndex < FList.Count)) then
    Result:= FColors[AIndex]
  else
    Result:= Fuchsia;
end;

procedure TCastleColorListBox.CalcTextWidth;
begin
  FTextWidth:= Font.MaxTextWidth(FList) + Font.TextWidth('#');
end;

function TCastleColorListBox.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'TextMargin', 'ShowText', 'ShowTextLeft', 'ColorBox', 'ColorFrame',
       'ColorBoxMargin'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleColorListBox, ['List', 'Color List Box']);
end.

