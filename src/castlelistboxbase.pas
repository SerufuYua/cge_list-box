{
  Copyright (c) 2026 Serufu Yua
  --------------------------------------------------
}

{ Base class of List Boxes }


unit CastleListBoxBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleControls, CastleClassUtils, CastleColors,
  CastleKeysMouse, CastleRectangles, CastleVectors, CastleGLImages;

type
  TCastleListBoxBase = class(TCastleUserInterfaceFont)
  protected
    FTextMargin: Single;
    FIndex: Integer;
    FLineFrame, FLineCursor: TCastleImagePersistent;
    FScrollbarFrame, FScrollbarSlider: TCastleImagePersistent;
    FAreaRect, FCursorRect, FMoveRect, FClickRect: TFloatRectangle;
    FCursorTargetBottom: Single;
    FScrollFrameRect, FScrollSliderRect: TFloatRectangle;
    FAreaPosY, FAreaTargetPosY, FSliderPosY, FAreaSpeed: Single;
    FLinePadding, FLineHeight, FAreaHeight, FScrollBarWidth: Single;
    FCursorSpeed: Single;
    FList: TStrings;
    FScrollbarLeft, FIndexChanged: Boolean;
    FClickStarted, FMoveStarted, FMoveMain, FMoveSlider: boolean;
    FClickStartedFinger: TFingerIndex;
    FOnClick, FOnChange, FOnClickSecond, FOnCursorArrive: TNotifyEvent;
    FColor: TCastleColor;
    FColorPersistent: TCastleColorPersistent;
    function GetColorForPersistent: TCastleColor;
    procedure SetColorForPersistent(const AValue: TCastleColor);
    procedure ListChange(Sender: TObject); virtual;
    procedure SetList(const AValue: TStrings);
    procedure SetPadding(const AValue: Single);
    procedure SetAreaPosY(const AValue: Single);
    procedure SetSliderPosY(const AValue: Single);
    procedure SetIndex(const AValue: Integer);
    procedure UpdateListPosition;
    procedure CalcLineHeight;
    procedure CalcRectangles; virtual;
    procedure DoClick;
    procedure DoClickSecond;
    procedure DoChange;
    procedure DoCursorArrive;
  public
    const
      DefaultTextMargin = 12;
      DefaultScrollBarLeft = False;
      DefaultIndex = -1;
      DefaultLinePadding = 12;
      DefaultScrollBarWidth = 24.0;
      DefaultCursorSpeed = 35.0;
      DefaultAreaSpeed = 35.0;
      DefaultColor: TCastleColor = (X: 1.0; Y: 1.0; Z: 1.0; W: 1.0);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single;
                     var HandleInput: boolean); override;
    procedure Resize; override;
    procedure FontChanged; override;
    function Press(const Event: TInputPressRelease): boolean; override;
    function Release(const Event: TInputPressRelease): boolean; override;
    function Motion(const Event: TInputMotion): boolean; override;
    procedure Render; override;
    procedure RenderLine(const ARect: TFloatRectangle; const AIndex: Integer); virtual;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    property Color: TCastleColor read FColor write FColor;
    property AreaPosY: Single read FAreaPosY write SetAreaPosY;
    property SliderPosY: Single read FSliderPosY write SetSliderPosY;
  published
    property List: TStrings read FList write SetList;
    property TextMargin: Single read FTextMargin write FTextMargin
             {$ifdef FPC}default DefaultTextMargin{$endif};
    property ScrollBarLeft: Boolean read FScrollBarLeft write FScrollBarLeft
             {$ifdef FPC}default DefaultScrollBarLeft{$endif};
    property CursorSpeed: Single read FCursorSpeed write FCursorSpeed
             {$ifdef FPC}default DefaultCursorSpeed{$endif};
    property AreaSpeed: Single read FAreaSpeed write FAreaSpeed
             {$ifdef FPC}default DefaultAreaSpeed{$endif};
    property Index: Integer read FIndex write SetIndex
             {$ifdef FPC}default DefaultIndex{$endif};
    property LineFrame: TCastleImagePersistent read FLineFrame;
    property LineCursor: TCastleImagePersistent read FLineCursor;
    property ScrollbarFrame: TCastleImagePersistent read FScrollbarFrame;
    property ScrollbarSlider: TCastleImagePersistent read FScrollbarSlider;
    property ScrollBarWidth: Single read FScrollBarWidth write FScrollBarWidth
             {$ifdef FPC}default DefaultScrollBarWidth{$endif};
    property LinePadding: Single read FLinePadding write SetPadding
             {$ifdef FPC}default DefaultLinePadding{$endif};
    property ColorPersistent: TCastleColorPersistent read FColorPersistent;
    { called when got click in list area }
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    { called when got click to selected line, it's not a double click }
    property OnClickSecond: TNotifyEvent read FOnClickSecond write FOnClickSecond;
    { called when Index is changed }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    { called when animated cursor arrive the target
      don't work when CursorSpeed:= 0.0 }
    property OnCursorArrive: TNotifyEvent read FOnCursorArrive write FOnCursorArrive;
  end;

implementation

uses
  CastleUtils, CastleGLUtils, CastleUIControls;

constructor TCastleListBoxBase.Create(AOwner: TComponent);
begin
  inherited;

  FOnClick:= nil;
  FOnChange:= nil;
  FAreaPosY:= 0.0;
  FAreaTargetPosY:= 0.0;
  FSliderPosY:= 0.0;
  FIndexChanged:= False;
  FTextMargin:= DefaultTextMargin;
  FScrollBarLeft:= DefaultScrollBarLeft;
  FCursorSpeed:= DefaultCursorSpeed;
  FAreaSpeed:= DefaultAreaSpeed;
  FIndex:= DefaultIndex;
  FLinePadding:= DefaultLinePadding;
  FScrollBarWidth:= DefaultScrollBarWidth;

  FList:= TStringList.Create;
  TStringList(FList).OnChange:= {$ifdef FPC}@{$endif}ListChange;

  FLineCursor:= TCastleImagePersistent.Create;
  FLineFrame:= TCastleImagePersistent.Create;
  FScrollbarFrame:= TCastleImagePersistent.Create;
  FScrollbarSlider:= TCastleImagePersistent.Create;

  { Persistent for ColorBGLow }
  FColor:= DefaultColor;
  FColorPersistent:= TCastleColorPersistent.Create(nil);
  FColorPersistent.SetSubComponent(true);
  FColorPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorForPersistent;
  FColorPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorForPersistent;
  FColorPersistent.InternalDefaultValue:= Color;
end;

destructor TCastleListBoxBase.Destroy;
begin
  if Assigned(FColorPersistent) then
    FreeAndNil(FColorPersistent);

  if Assigned(FLineCursor) then
    FreeAndNil(FLineCursor);

  if Assigned(FLineFrame) then
    FreeAndNil(FLineFrame);

  if Assigned(FScrollbarFrame) then
    FreeAndNil(FScrollbarFrame);

  if Assigned(FScrollbarSlider) then
    FreeAndNil(FScrollbarSlider);

  if Assigned(FList) then
    FreeAndNil(FList);

  inherited;
end;

procedure TCastleListBoxBase.Update(const SecondsPassed: Single;
                                var HandleInput: boolean);
const
  Epsilon = 0.5;
var
  Speed: Single;
begin
  inherited;
  CalcRectangles;


  { move cursor to target }
  if (CursorSpeed > 0.0) then
  begin
    Speed:= SecondsPassed * CursorSpeed;
    if (System.Abs(FCursorRect.Bottom - FCursorTargetBottom) > Epsilon) then
      FCursorRect.Bottom:= Lerp(Speed, FCursorRect.Bottom,
                                       FCursorTargetBottom)
    else
    begin
      if FIndexChanged then
      begin
        FIndexChanged:= False;
        DoCursorArrive;
      end;
    end;
  end
  else
    FCursorRect.Bottom:= FCursorTargetBottom;

  { move area to target }
  if (AreaSpeed > 0.0) then
  begin
    Speed:= SecondsPassed * AreaSpeed;
    if (System.Abs(FAreaPosY - FAreaTargetPosY) > Epsilon) then
      FAreaPosY:= Lerp(Speed, FAreaPosY, FAreaTargetPosY);
  end
  else
    FAreaPosY:= FAreaTargetPosY;
end;

function TCastleListBoxBase.Press(const Event: TInputPressRelease): boolean;
var
  LinesInPage, NewPos: Integer;
begin
  Result:= inherited;
  if Result then Exit;

  if (Event.EventType = itMouseButton) then
  begin
    if (FClickRect + FScrollSliderRect).Contains(Event.Position) then
      Result:= True;

    { set FClickStarted, to be able to reach OnClick }
    FClickStarted:= True;
    FMoveStarted:= False;
    FClickStartedFinger:= Event.FingerIndex;

    FMoveMain:= FMoveRect.Contains(Event.Position);
    FMoveSlider:= FScrollSliderRect.Contains(Event.Position);
  end
  else
  if (Event.EventType = itMouseWheel) then
  begin
    AreaPosY:= AreaPosY + FLineHeight * Event.MouseWheelScroll;
  end
  else
  if (Event.EventType = itKey) then
  begin
    if (Event.IsKey(keyArrowUp) AND (Index > 0)) then
      Index:= Index - 1
    else if (Event.IsKey(keyArrowDown) AND (Index < (FList.Count - 1))) then
      Index:= Index + 1
    else if (Event.IsKey(keyPageUp) AND (Index > 0)) then
    begin
      LinesInPage:= Trunc(FMoveRect.Height / FLineHeight);
      NewPos:= Index - LinesInPage;
      if (NewPos < 0) then
        Index:= 0
      else
        Index:= NewPos;
    end
    else if (Event.IsKey(keyPageDown) AND (Index < (FList.Count - 1))) then
    begin
      LinesInPage:= Trunc(FMoveRect.Height / FLineHeight);
      NewPos:= Index + LinesInPage;
      if (NewPos > (FList.Count - 1)) then
        Index:= FList.Count - 1
      else
        Index:= NewPos;
    end;
  end;
end;

function TCastleListBoxBase.Release(const Event: TInputPressRelease): boolean;
var
  h: Single;
  i: Integer;
begin
  Result:= inherited;
  if Result or (Event.EventType <> itMouseButton) then Exit;

  if (FClickStarted AND (FClickStartedFinger = Event.FingerIndex)) then
  begin
    FClickStarted:= False;
    if NOT FMoveStarted then
    begin
      if FClickRect.Contains(Event.Position) then
      begin
        Result:= True;
        h:= FAreaRect.Height - (Event.Position.Y - FAreaRect.Bottom);
        i:= Trunc(h / FLineHeight);
        if (i < FList.Count) then
        begin
          if (Index = i) then
            DoClickSecond
          else
            FIndexChanged:= True;

          Index:= i;
          DoClick;
        end;
      end
      else if FScrollFrameRect.Contains(Event.Position) then
      begin
        if (Event.Position.Y < FScrollSliderRect.Bottom) then
          SliderPosY:= SliderPosY - FScrollSliderRect.Height
        else if (Event.Position.Y > FScrollSliderRect.top) then
          SliderPosY:= SliderPosY + FScrollSliderRect.Height;
      end;
    end;
  end;
end;

function TCastleListBoxBase.Motion(const Event: TInputMotion): boolean;
var
  shiftY: Single;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle event

  if (FClickStarted AND (FClickStartedFinger = Event.FingerIndex)) then
  begin
    Result:= True;
    if FMoveMain then
    begin
      shiftY:= Event.OldPosition.Y - Event.Position.Y;
      AreaPosY:= FAreaTargetPosY + shiftY;
      if NOT TVector2.Equals(Event.OldPosition, Event.Position, 1.0) then
        FMoveStarted:= True;
    end
    else
    if FMoveSlider then
    begin
      shiftY:= Event.OldPosition.Y - Event.Position.Y;
      SliderPosY:= SliderPosY - shiftY;
      if NOT TVector2.Equals(Event.OldPosition, Event.Position, 1.0) then
        FMoveStarted:= True;
    end;
  end;
end;

procedure TCastleListBoxBase.Render;
const
  CurWidth = 2;
var
  i: Integer;
  FinalFrame, FinalSlider, FinalLine: TCastleImagePersistent;
  LineRect: TFloatRectangle;
begin
  inherited;

  {$if defined(CASTLE_DESIGN_MODE)}
  DrawRectangleOutline(FAreaRect, Yellow, 1);
  {$endif}

  { List }
  LineRect.Left:= FAreaRect.Left;
  LineRect.Width:= FAreaRect.Width;
  LineRect.Height:= FLineHeight;

  for i:= 0 to (FList.Count - 1) do
  begin
    LineRect.Bottom:= FAreaRect.Top - FLineHeight * Single(i + 1);

    { line background }
    if FLineFrame.Empty then
      FinalLine:= Theme.ImagesPersistent[tiButtonNormal]
    else
      FinalLine:= FLineFrame;

    FinalLine.DrawUiBegin(UIScale);
    FinalLine.Color:= FLineFrame.Color;
    FinalLine.Draw(LineRect);
    FinalLine.DrawUiEnd;

    RenderLine(LineRect, i);
  end;

  { line cursor }
  if FLineCursor.Empty then
    DrawRectangleOutline(FCursorRect.Grow(-CurWidth / 2), FLineCursor.Color, CurWidth)
  else
  begin
    FLineCursor.DrawUiBegin(UIScale);
    FLineCursor.Color:= FLineCursor.Color;
    FLineCursor.Draw(FCursorRect);
    FLineCursor.DrawUiEnd;
  end;

  { Scrollbar Frame }
  if FScrollbarFrame.Empty then
    FinalFrame:= Theme.ImagesPersistent[tiScrollbarFrame]
  else
    FinalFrame:= FScrollbarFrame;

  FinalFrame.DrawUiBegin(UIScale);
  FinalFrame.Color:= FScrollbarFrame.Color;
  FinalFrame.Draw(FScrollFrameRect);
  FinalFrame.DrawUiEnd;

  { Scrollbar Slider }
  if FScrollbarSlider.Empty then
    FinalSlider:= Theme.ImagesPersistent[tiScrollbarSlider]
  else
    FinalSlider:= FScrollbarSlider;

  FinalSlider.DrawUiBegin(UIScale);
  FinalSlider.Color:= FScrollbarSlider.Color;
  FinalSlider.Draw(FScrollSliderRect);
  FinalSlider.DrawUiEnd;
end;

procedure TCastleListBoxBase.RenderLine(const ARect: TFloatRectangle; const AIndex: Integer);
begin
end;

procedure TCastleListBoxBase.ListChange(Sender: TObject);
begin
  UpdateListPosition;
end;

procedure TCastleListBoxBase.SetList(const AValue: TStrings);
begin
  FList.Assign(AValue);
end;

procedure TCastleListBoxBase.Resize;
begin
  inherited;
  UpdateListPosition;
end;

procedure TCastleListBoxBase.FontChanged;
begin
  inherited;
  UpdateListPosition;
end;

procedure TCastleListBoxBase.SetPadding(const AValue: Single);
begin
  if (FLinePadding = AValue) then Exit;
  FLinePadding:= AValue;
  CalcLineHeight;
end;

procedure TCastleListBoxBase.SetAreaPosY(const AValue: Single);
var
  MinPosY, MaxPosY, SlideFactor, Value: Single;
begin
  Value:= AValue;
  MaxPosY:= 0.0;
  MinPosY:= RenderRect.Height - FAreaRect.Height;
  ClampVar(Value, MinPosY, MaxPosY);
  FAreaTargetPosY:= Value;

  if (MaxPosY = MinPosY) then
    FSliderPosY:= 0.0
  else
  begin
    SlideFactor:= 1.0 - (FAreaTargetPosY - MinPosY) / (MaxPosY - MinPosY);
    FSliderPosY:= (FScrollSliderRect.Height - RenderRect.Height) * SlideFactor;
  end;
end;

procedure TCastleListBoxBase.SetSliderPosY(const AValue: Single);
var
  MinPosY, MaxPosY, AreaFactor, Value: Single;
begin
  Value:= AValue;
  MaxPosY:= 0.0;
  MinPosY:= FScrollSliderRect.Height - RenderRect.Height;
  ClampVar(Value, MinPosY, MaxPosY);
  FSliderPosY:= Value;

  if (MaxPosY = MinPosY) then
    FAreaTargetPosY:= 0.0
  else
  begin
    AreaFactor:= 1.0 - (FSliderPosY - MinPosY) / (MaxPosY - MinPosY);
    FAreaTargetPosY:= (RenderRect.Height - FAreaRect.Height) * AreaFactor;
  end;
end;

procedure TCastleListBoxBase.SetIndex(const AValue: Integer);
var
  CursorBottom: Single;
begin
  if (FIndex = AValue) then Exit;
  FIndex:= AValue;

  CursorBottom:= FAreaRect.Top - FLineHeight * (Single(FIndex) + 1.0);

  if (CursorBottom < FMoveRect.Bottom) then
    AreaPosY:= AreaPosY - (FMoveRect.Bottom - CursorBottom)
  else if ((CursorBottom + FLineHeight) > FMoveRect.Top) then
    AreaPosY:= AreaPosY + ((CursorBottom + FLineHeight) - FMoveRect.Top);

  DoChange;
end;

procedure TCastleListBoxBase.UpdateListPosition;
var
  MinPosY, MaxPosY, Value: Single;
begin
  CalcLineHeight;
  CalcRectangles;
  FCursorRect.Bottom:= FCursorTargetBottom;
  Value:= AreaPosY;
  MaxPosY:= 0.0;
  MinPosY:= RenderRect.Height - FAreaRect.Height;
  ClampVar(Value, MinPosY, MaxPosY);
  AreaPosY:= Value;
end;

procedure TCastleListBoxBase.CalcLineHeight;
begin
  FLineHeight:= Font.Height + FLinePadding * 2.0 * UIScale;
end;

procedure TCastleListBoxBase.CalcRectangles;
var
  h, sb: Single;
begin
  h:= FLineHeight * FList.Count;

  if (h < RenderRect.Height) then
  begin
    h:= RenderRect.Height;
    sb:= 0.0;
  end
  else
    sb:= ScrollBarWidth * UIScale;

  { main area }

  if FScrollBarLeft then
    FAreaRect:= RenderRect.RightPart(RenderRect.Width - sb)
  else
    FAreaRect:= RenderRect.LeftPart(RenderRect.Width - sb);

  FAreaRect.Height:= h;
  FAreaRect.Bottom:= RenderRect.Top - FAreaRect.Height - AreaPosY;

  { move area }
  FMoveRect.Width:= FAreaRect.Width;
  FMoveRect.Left:= FAreaRect.Left;
  FMoveRect.Bottom:= RenderRect.Bottom;
  FMoveRect.Height:= RenderRect.Height;

  { click area }
  FClickRect:= FMoveRect;

  { cursor area }
  FCursorTargetBottom:= FAreaRect.Top - FLineHeight * (Single(FIndex) + 1.0);
  FCursorRect.Left:= FAreaRect.Left;
  FCursorRect.Width:= FAreaRect.Width;
  FCursorRect.Height:= FLineHeight;

  { scroll area Frame }
  if FScrollBarLeft then
    FScrollFrameRect:= RenderRect.LeftPart(sb)
  else
    FScrollFrameRect:= RenderRect.RightPart(sb);

  { scroll area Slider }
  h:= RenderRect.Height * RenderRect.Height / FAreaRect.Height;
  if (h > RenderRect.Height) then
    h:= RenderRect.Height;

  if FScrollBarLeft then
    FScrollSliderRect:= RenderRect.LeftPart(sb)
  else
    FScrollSliderRect:= RenderRect.RightPart(sb);

  FScrollSliderRect.Height:= h;
  FScrollSliderRect.Bottom:= RenderRect.Top - FScrollSliderRect.Height + SliderPosY;
end;

function TCastleListBoxBase.GetColorForPersistent: TCastleColor;
begin
  Result:= Color;
end;

procedure TCastleListBoxBase.SetColorForPersistent(const AValue: TCastleColor);
begin
  Color:= AValue;
end;

procedure TCastleListBoxBase.DoClick;
begin
  if Assigned(OnClick) then
    OnClick(Self);
end;

procedure TCastleListBoxBase.DoClickSecond;
begin
  if Assigned(OnClickSecond) then
    OnClickSecond(Self);
end;

procedure TCastleListBoxBase.DoChange;
begin
  if Assigned(OnChange) then
    OnChange(Self);
end;

procedure TCastleListBoxBase.DoCursorArrive;
begin
  if Assigned(OnCursorArrive) then
    OnCursorArrive(Self);
end;

function TCastleListBoxBase.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'TextMargin', 'ColorPersistent', 'LinePadding', 'ScrollBarWidth',
       'LineFrame', 'LineCursor', 'ScrollbarFrame', 'ScrollbarSlider', 'Index',
       'CursorSpeed', 'AreaSpeed', 'ClipChildren', 'List',
       'ScrollBarLeft'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

end.

