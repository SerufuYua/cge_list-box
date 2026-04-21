{
  Copyright (c) 2026 Serufu Yua
  --------------------------------------------------
}

{ simple List Box with Text Lines }


unit CastleListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles,
  CastleListBoxBase;

type
  TCastleListBox = class(TCastleListBoxBase)
  public
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); override;
  end;

implementation

uses
  CastleComponentSerialize
  {$if defined(CASTLE_DESIGN_MODE)}
  , CastleGLUtils
  , CastleColors
  {$endif};

procedure TCastleListBox.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
var
  i, len: Integer;
  TextRect: TFloatRectangle;
  Text: String;
  si: Single;
begin
  inherited;
  si:= FTextMargin * UIScale;
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

initialization
  RegisterSerializableComponent(TCastleListBox, ['List', 'List Box']);
end.

