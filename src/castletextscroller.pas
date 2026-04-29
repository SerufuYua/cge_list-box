unit CastleTextScroller;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleControls, CastleColors, CastleClassUtils,
  CastleRectangles;

type
  TCastleTextScroller = class(TCastleUserInterfaceFont)
  protected
    FHAlignment: THorizontalPosition;
    FAutoSizeWidth: Boolean;
    FAutoSizeHeightByLines: Integer;
    FSpeed, FSpacing, FZoom: Single;
    FLineHeight, FFlowIndex, FFlowLinePos: Single;
    FIndex: Integer;
    FList: TStrings;
    FColor: TCastleColor;
    FColorPersistent: TCastleColorPersistent;
    function GetColorForPersistent: TCastleColor;
    procedure SetColorForPersistent(const AValue: TCastleColor);
    procedure ListChange(Sender: TObject); virtual;
    procedure SetList(const AValue: TStrings);
    procedure PreferredSize(var PreferredWidth, PreferredHeight: Single); override;
    function TextScale(const AIndex, ABaseIndex: Single): Single;
    function LinePos(const AIndex: Integer; const ABaseIndex: Single): Single;
  public
    const
      DefaultScrollBarLeft = False;
      DefaultIndex = 0;
      DefaultSpeed = 16.0;
      DefaultSpacing = 12.0;
      DefaultZoom = 1.5;
      DefaultHAlignment = hpMiddle;
      DefaultAutoSizeWidth = True;
      DefaultAutoSizeHeightByLines = 0;
      DefaultColor: TCastleColor = (X: 1.0; Y: 1.0; Z: 1.0; W: 1.0);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single;
                     var HandleInput: boolean); override;
    procedure Render; override;
    procedure FontChanged; override;
    procedure EditorAllowResize(out ResizeWidth, ResizeHeight: Boolean;
                                out Reason: String); override;
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
    property HorizontalAlignment: THorizontalPosition read FHAlignment write FHAlignment
             {$ifdef FPC}default DefaultHAlignment{$endif};
    property AutoSizeWidth: Boolean read FAutoSizeWidth write FAutoSizeWidth
             {$ifdef FPC}default DefaultAutoSizeWidth{$endif};
    property AutoSizeHeightByLines: Integer read FAutoSizeHeightByLines write FAutoSizeHeightByLines
             {$ifdef FPC}default DefaultAutoSizeHeightByLines{$endif};
    property ColorPersistent: TCastleColorPersistent read FColorPersistent;
  end;

implementation

uses
  CastleUtils, CastleComponentSerialize, CastleGLUtils, CastleStringUtils, Math;

constructor TCastleTextScroller.Create(AOwner: TComponent);
begin
  inherited;

  FSpeed:= DefaultSpeed;
  FSpacing:= DefaultSpacing;
  FIndex:= DefaultIndex;
  FHAlignment:= DefaultHAlignment;
  FAutoSizeWidth:= DefaultAutoSizeWidth;
  FAutoSizeHeightByLines:= DefaultAutoSizeHeightByLines;
  FZoom:= DefaultZoom;
  FFlowIndex:= Single(DefaultIndex);
  FFlowLinePos:= 0.0;
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
  Move, Idx, LPos: Single;
begin
  inherited;

  { flow Index to target }
  if (Speed > 0.0) then
  begin
    Move:= SecondsPassed * Speed;
    Move:= Clamped(Move, 0.0, 1.0);

    { move index }
    idx:= Single(Index);
    if (System.Abs(Idx - FFlowIndex) > Epsilon) then
      FFlowIndex:= Lerp(Move, FFlowIndex, idx);

    { move lines }
    LPos:= LinePos(Index, FFlowIndex);
    if (System.Abs(LPos - FFlowLinePos) > Epsilon) then
      FFlowLinePos:= Lerp(Move, FFlowLinePos, LPos);
  end
  else
  begin
    { hard set index }
    FFlowIndex:= Single(Index);

    { hard set lines }
    FFlowLinePos:= LinePos(Index, FFlowIndex);
  end;
end;

procedure TCastleTextScroller.Render;
var
  i: Integer;
  TextRect: TFloatRectangle;
  TextColor: TCastleColor;
  LPos: Single;
begin
  inherited;

  TextRect.Left:= RenderRect.Left;
  TextRect.Width:= RenderRect.Width;

  LPos:= FFlowLinePos;
  for i:= 0 to (FList.Count - 1) do
  begin
    FontScale:= TextScale(Single(i), FFlowIndex);

    TextRect.Bottom:= RenderRect.Top - LPos - FLineHeight;
    TextRect.Height:= FLineHeight;

    TextColor:= Color;
    TextColor.W:= FontScale / Zoom;

    DrawRectangleOutline(TextRect, Green, 1);

    if ((TextRect.Bottom < RenderRect.Top) AND (TextRect.Top > RenderRect.Bottom)) then
      Font.PrintRect(TextRect, TextColor, FList[i], HorizontalAlignment, vpMiddle);

    LPos:= LPos + TextRect.Height;
  end;
end;

function TCastleTextScroller.TextScale(const AIndex, ABaseIndex: Single): Single;
const
  X0 = 0.0; Y0 = 1.0;
  X1 = 1.0; Y1 = 0.5;
  X2 = 2.0; Y2 = 0.15;
  X3 = 3.0; Y3 = 0.0;
var
  Diff, Proximity: Single;
begin
  Diff:= System.Abs(AIndex - ABaseIndex);
  if      ((X0 <= Diff) AND (Diff < X1)) then Proximity:= Lerp(Diff - X0, Y0, Y1)
  else if ((X1 <= Diff) AND (Diff < X2)) then Proximity:= Lerp(Diff - X1, Y1, Y2)
  else if ((X2 <= Diff) AND (Diff < X3)) then Proximity:= Lerp(Diff - X2, Y2, Y3)
  else                                        Proximity:= Y3;

  Result:= 1.0 + Zoom * Proximity;
end;

function TCastleTextScroller.LinePos(const AIndex: Integer;
                                     const ABaseIndex: Single): Single;
var
  i: Integer;
begin
  Result:= 0.0;
  for i:= 0 to (AIndex - 1) do
  begin
    FontScale:= TextScale(Single(i), ABaseIndex);
    Result:= Result - FLineHeight;
  end;
end;

procedure TCastleTextScroller.FontChanged;
begin
  inherited;
  FLineHeight:= Font.Height + Spacing * UIScale;
end;

procedure TCastleTextScroller.ListChange(Sender: TObject);
begin

end;

procedure TCastleTextScroller.SetList(const AValue: TStrings);
begin
  FList.Assign(AValue);
end;

procedure TCastleTextScroller.PreferredSize(var PreferredWidth, PreferredHeight: Single);
begin
  if AutoSizeWidth then
  begin
    FontScale:= 1.0 + Zoom;
    PreferredWidth:= Font.MaxTextWidth(FList);
  end;

  if (AutoSizeHeightByLines > 0) then
  begin
    PreferredHeight:= -LinePos(AutoSizeHeightByLines, 0.0);
  end;
end;

procedure TCastleTextScroller.EditorAllowResize(out ResizeWidth, ResizeHeight: Boolean;
                                                out Reason: String);
begin
  inherited;
  if AutoSizeWidth then
  begin
    ResizeWidth:= False;
    Reason:= SAppendPart(Reason, NL, 'Turn off "TCastleTextScroller.AutoSizeWidth" to change width.');
  end;

  if (AutoSizeHeightByLines > 0) then
  begin
    ResizeHeight:= False;
    Reason:= SAppendPart(Reason, NL, 'Set "TCastleTextScroller.AutoSizeHeightByLines" to 0 to change height.');
  end;
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
       'ClipChildren', 'HorizontalAlignment'
     ]) then
    Result:= [psBasic]
  else if ArrayContainsString(PropertyName, [
       'AutoSizeWidth', 'AutoSizeHeightByLines'
     ]) then
    Result:= [psLayout]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleTextScroller, ['List', 'Text Scroller']);
end.

