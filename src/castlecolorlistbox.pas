unit CastleColorListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles,
  CastleGLImages, CastleVectors, CastleColors, CastleListBoxBase;

type
  TCastleColorListBox = class(TCastleListBoxBase)
  protected
    FShowText, FShowTextLeft: Boolean;
    FTextMargin, FTextWidth: Single;
    FColorBox: TCastleImagePersistent;
    FColorBoxMargin: TBorder;
    procedure ListChange(Sender: TObject); override;
    procedure CalcTextWidth;
  public
    const
      DefaultTextMargin = 12;
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
    property TextMargin: Single read FTextMargin write FTextMargin
             {$ifdef FPC}default DefaultTextMargin{$endif};
    property ColorBox: TCastleImagePersistent read FColorBox;
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
  FTextMargin:= DefaultTextMargin;

  FColorBox:= TCastleImagePersistent.Create;

  FColorBoxMargin:= TBorder.Create(nil);
  FColorBoxMargin.SetSubComponent(true);
end;

destructor TCastleColorListBox.Destroy;
begin
  if Assigned(FColorBox) then
    FreeAndNil(FColorBox);

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
  TextRect, ColorBoxRect: TFloatRectangle;
  Text: String;
  NeedText: Boolean;
  si: Single;
  LineColor: TCastleColor;
begin
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

  LineColor:= HexToColor(FList[AIndex]);

  if FColorBox.Empty then
  begin
    DrawRectangle(ColorBoxRect, LineColor);
    DrawRectangleOutline(ColorBoxRect, FColorBox.Color, 2);
  end
  else
  begin
    FColorBox.DrawUiBegin(UIScale);
    FColorBox.Color:= LineColor;
    FColorBox.Draw(ColorBoxRect);
    FColorBox.DrawUiEnd;
  end;
end;

procedure TCastleColorListBox.ListChange(Sender: TObject);
begin
  inherited;
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
    Result:= HexToColor(FList[AIndex])
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
       'TextMargin', 'ShowText', 'ShowTextLeft', 'ColorBox', 'ColorBoxMargin'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleColorListBox, ['Seq', 'Color List Box']);
end.

