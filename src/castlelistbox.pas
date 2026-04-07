unit CastleListBox;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleRectangles,
  CastleListBoxBase;

type
  TCastleListBox = class(TCastleListBoxBase)
  protected
    FTextMargin: Single;
  public
    const
      DefaultTextMargin = 12;

    constructor Create(AOwner: TComponent); override;
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
  published
    property TextMargin: Single read FTextMargin write FTextMargin
             {$ifdef FPC}default DefaultTextMargin{$endif};
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils
  {$if defined(CASTLE_DESIGN_MODE)}
  , CastleGLUtils
  , CastleColors
  {$endif};

constructor TCastleListBox.Create(AOwner: TComponent);
begin
  inherited;

  FTextMargin:= DefaultTextMargin;
end;

procedure TCastleListBox.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
var
  i, len: Integer;
  TextRect: TFloatRectangle;
  Text: String;
  si: Single;
begin
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

function TCastleListBox.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'TextMargin'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleListBox, ['Seq', 'List Box']);
end.

