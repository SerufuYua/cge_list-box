unit CastleTextScroller;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleControls, CastleColors, CastleClassUtils;

type
  TCastleTextScroller = class(TCastleUserInterfaceFont)
  protected
    FSpeed, FSpacing, FZoom: Single;
    FLineHeight, FFlowIndex: Single;
    FIndex: Integer;
    FList: TStrings;
    FColor: TCastleColor;
    FColorPersistent: TCastleColorPersistent;
    function GetColorForPersistent: TCastleColor;
    procedure SetColorForPersistent(const AValue: TCastleColor);
    procedure ListChange(Sender: TObject); virtual;
    procedure SetList(const AValue: TStrings);
  public
    const
      DefaultScrollBarLeft = False;
      DefaultIndex = 0;
      DefaultSpeed = 16.0;
      DefaultSpacing = 12.0;
      DefaultZoom = 0.5;
      DefaultColor: TCastleColor = (X: 1.0; Y: 1.0; Z: 1.0; W: 1.0);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single;
                     var HandleInput: boolean); override;
    procedure Render; override;
    procedure FontChanged; override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    property Color: TCastleColor read FColor write FColor;
  published
    property List: TStrings read FList write SetList;
    property Speed: Single read FSpeed write FSpeed
             {$ifdef FPC}default DefaultSpeed{$endif};
    property Zoom: Single read FZoom write FZoom
             {$ifdef FPC}default DefaultZoom{$endif};
    property Spacing: Single read FSpacing write FSpacing
             {$ifdef FPC}default DefaultSpacing{$endif};
    property Index: Integer read FIndex write FIndex
             {$ifdef FPC}default DefaultIndex{$endif};
    property ColorPersistent: TCastleColorPersistent read FColorPersistent;
  end;

implementation

uses
  CastleUtils, CastleComponentSerialize, CastleRectangles, CastleGLUtils, Math;

constructor TCastleTextScroller.Create(AOwner: TComponent);
begin
  inherited;

  FSpeed:= DefaultSpeed;
  FSpacing:= DefaultSpacing;
  FIndex:= DefaultIndex;
  FZoom:= DefaultZoom;
  FFlowIndex:= Single(DefaultIndex);
  FontChanged;

  FList:= TStringList.Create;
  TStringList(FList).OnChange:= {$ifdef FPC}@{$endif}ListChange;

  { Persistent for ColorBGLow }
  FColor:= DefaultColor;
  FColorPersistent:= TCastleColorPersistent.Create(nil);
  FColorPersistent.SetSubComponent(true);
  FColorPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorForPersistent;
  FColorPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorForPersistent;
  FColorPersistent.InternalDefaultValue:= Color;
end;

destructor TCastleTextScroller.Destroy;
begin
  if Assigned(FColorPersistent) then
    FreeAndNil(FColorPersistent);

  if Assigned(FList) then
    FreeAndNil(FList);

  inherited;
end;

procedure TCastleTextScroller.Update(const SecondsPassed: Single;
                                     var HandleInput: boolean);
const
  Epsilon = 0.05;
var
  Move, Idx: Single;
begin
  inherited;

  { flow Index to target }
  if (Speed > 0.0) then
  begin
    idx:= Single(Index);
    if (System.Abs(Idx - FFlowIndex) > Epsilon) then
    begin
      Move:= SecondsPassed * Speed;
      Move:= Clamped(Move, 0.0, 1.0);
      FFlowIndex:= Lerp(Move, FFlowIndex, idx);
    end;
  end
  else
    FFlowIndex:= idx;

end;

procedure TCastleTextScroller.Render;
var
  i: Integer;
  TextRect: TFloatRectangle;
  TextColor: TCastleColor;
  TempScale, LinePos: Single;
begin
  inherited;

  TextRect.Left:= RenderRect.Left;
  TextRect.Width:= RenderRect.Width;

  LinePos:= 0.0;
  FontScale:= 1.0;
  for i:= 1 to Index do
  begin
    TempScale:= Power(Zoom, System.Abs(Single(i) - FFlowIndex));
    LinePos:= LinePos - FLineHeight * TempScale;
  end;

  for i:= 0 to (FList.Count - 1) do
  begin
    FontScale:= 1.0 * Power(Zoom, System.Abs(Single(i) - FFlowIndex));

    TextRect.Bottom:= RenderRect.Top - LinePos - FLineHeight;
    TextRect.Height:= FLineHeight;

    TextColor:= Color;
    TextColor.W:= FontScale;

    DrawRectangleOutline(TextRect, Red, 1);

    Font.PrintRect(TextRect, TextColor, FList[i], hpMiddle, vpMiddle);

    LinePos:= LinePos + TextRect.Height;
  end;
end;

procedure TCastleTextScroller.FontChanged;
begin
  FLineHeight:= Font.Height + Spacing * UIScale;
end;

procedure TCastleTextScroller.ListChange(Sender: TObject);
begin

end;

procedure TCastleTextScroller.SetList(const AValue: TStrings);
begin
  FList.Assign(AValue);
end;

function TCastleTextScroller.GetColorForPersistent: TCastleColor;
begin
  Result:= Color;
end;

procedure TCastleTextScroller.SetColorForPersistent(const AValue: TCastleColor);
begin
  Color:= AValue;
end;

function TCastleTextScroller.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'List', 'Speed', 'Spacing', 'Index', 'ColorPersistent', 'Zoom',
       'ClipChildren'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleTextScroller, ['List', 'Text Scroller']);
end.

