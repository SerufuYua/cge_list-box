unit CastleGridGroup;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleControls, CastleClassUtils, CastleRectangles;

type
  TChildrenLayout = (LeftToRightThenTopToBottom,
                     TopToBottomThenLeftToRight);

  TCastleGridGroup = class(TCastlePackedGroup)
  protected
    FAlignmentVertical: TVerticalPosition;
    FAlignmentHorizontal: THorizontalPosition;
    FControlsPerLine: Integer;
    FLayout: TChildrenLayout;
    FPaddingVertical, FPaddingHorizontal: Single;
    FSpacingVertical, FSpacingHorizontal: Single;
    procedure DoPackChildren(out W, H: Single); override;
    procedure SetAlignmentVertical(AValue: TVerticalPosition);
    procedure SetAlignmentHorizontal(AValue: THorizontalPosition);
    procedure SetControlsPerLine(AValue: Integer);
    procedure SetLayout(AValue: TChildrenLayout);
    procedure SetPaddingVertical(AValue: Single);
    procedure SetPaddingHorizontal(AValue: Single);
    procedure SetSpacingVertical(AValue: Single);
    procedure SetSpacingHorizontal(AValue: Single);
  public
  const
    DefaultAlignmentVertical = vpTop;
    DefaultAlignmentHorizontal = hpLeft;
    DefaultControlsPerLine = 3;
    DefaultLayout = LeftToRightThenTopToBottom;
    DefaultPaddingVertical = 0.0;
    DefaultPaddingHorizontal = 0.0;
    DefaultSpacingVertical = 0.0;
    DefaultSpacingHorizontal = 0.0;

    constructor Create(AOwner: TComponent); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
  published
    property AlignmentVertical: TVerticalPosition read FAlignmentVertical write SetAlignmentVertical
             {$ifdef FPC}default DefaultAlignmentVertical{$endif};
    property AlignmentHorizontal: THorizontalPosition read FAlignmentHorizontal write SetAlignmentHorizontal
             {$ifdef FPC}default DefaultAlignmentHorizontal{$endif};
    property ControlsPerLine: Integer read FControlsPerLine write SetControlsPerLine
             {$ifdef FPC}default DefaultControlsPerLine{$endif};
    property Layout: TChildrenLayout read FLayout write SetLayout
             {$ifdef FPC}default DefaultLayout{$endif};
    property PaddingVertical: Single read FPaddingVertical write SetPaddingVertical
             {$ifdef FPC}default DefaultPaddingVertical{$endif};
    property PaddingHorizontal: Single read FPaddingHorizontal write SetPaddingHorizontal
             {$ifdef FPC}default DefaultPaddingHorizontal{$endif};
    property SpacingVertical: Single read FSpacingVertical write SetSpacingVertical
             {$ifdef FPC}default DefaultSpacingVertical{$endif};
    property SpacingHorizontal: Single read FSpacingHorizontal write SetSpacingHorizontal
             {$ifdef FPC}default DefaultSpacingHorizontal{$endif};
end;

implementation

uses
  CastleComponentSerialize, CastleUtils, CastleUIControls;

constructor TCastleGridGroup.Create(AOwner: TComponent);
begin
  inherited;

  FAlignmentVertical:= DefaultAlignmentVertical;
  FAlignmentHorizontal:= DefaultAlignmentHorizontal;
  FControlsPerLine:= DefaultControlsPerLine;
  FLayout:= DefaultLayout;
  FPaddingVertical:= DefaultPaddingVertical;
  FPaddingHorizontal:= DefaultPaddingHorizontal
end;

procedure TCastleGridGroup.SetAlignmentVertical(AValue: TVerticalPosition);
begin
  if FAlignmentVertical <> AValue then
  begin
    FAlignmentVertical:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetAlignmentHorizontal(AValue: THorizontalPosition);
begin
  if FAlignmentHorizontal <> AValue then
  begin
    FAlignmentHorizontal:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetControlsPerLine(AValue: Integer);
begin
  if (AValue < 1) then
    AValue:= 1;

  if FControlsPerLine <> AValue then
  begin
    FControlsPerLine:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetLayout(AValue: TChildrenLayout);
begin
  if FLayout <> AValue then
  begin
    FLayout:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetPaddingVertical(AValue: Single);
begin
  if FPaddingVertical <> AValue then
  begin
    FPaddingVertical:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetPaddingHorizontal(AValue: Single);
begin
  if FPaddingHorizontal <> AValue then
  begin
    FPaddingHorizontal:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetSpacingVertical(AValue: Single);
begin
  if FSpacingVertical <> AValue then
  begin
    FSpacingVertical:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.SetSpacingHorizontal(AValue: Single);
begin
  if FSpacingHorizontal <> AValue then
  begin
    FSpacingHorizontal:= AValue;
    FPackingValid:= False;
  end;
end;

procedure TCastleGridGroup.DoPackChildren(out W, H: Single);
var
  i, j, idx, LinesCount: Integer;
  Control: TCastleUserInterface;
  Size, Shift, HHalf, WHalf: Single;
begin
  W:= PaddingHorizontal;
  H:= PaddingVertical;

  LinesCount:= ControlsCount div ControlsPerLine;
  if ((ControlsCount mod ControlsPerLine) > 0) then
    LinesCount:= LinesCount + 1;

  case Layout of
    LeftToRightThenTopToBottom:
      begin
        { Set vertical posotion for rows }
        case AlignmentVertical of
        vpTop:
          begin
            for i:= 0 to (LinesCount - 1) do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, -H);
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;

              H:= H + Size + SpacingVertical;
            end;
          end;
        vpBottom:
          begin
            for i:= (LinesCount - 1) downto 0 do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, H);
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;

              H:= H + Size + SpacingVertical;
            end;
          end;
        vpMiddle:
          begin
            Shift:= (PaddingVertical + SpacingVertical) / 2.0;
            for i:= 0 to (LinesCount - 1) do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;
              Size:= Size / 2.0;
              H:= H + Size + SpacingVertical;

              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, -H + Shift);
                end;
              end;
              H:= H + Size;
            end;

            { shift all controls to center }
            HHalf:= H / 2.0;
            for i:= 0 to (ControlsCount - 1) do
            begin
              Control:= Controls[i];
              Control.Anchor(AlignmentVertical, Control.Translation.Y + HHalf);
            end;
          end;
        end;

        { Set horizontal posotion for columns }
        case AlignmentHorizontal of
        hpLeft:
          begin
            for j:= 0 to (ControlsPerLine - 1) do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, W);
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;

              W:= W + Size + SpacingHorizontal;
            end;
          end;
        hpRight:
          begin
            for j:= (ControlsPerLine - 1) downto 0 do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, -W);
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;

              W:= W + Size + SpacingHorizontal;
            end;
          end;
        hpMiddle:
          begin
            Shift:= (PaddingHorizontal + SpacingHorizontal) / 2.0;
            for j:= 0 to (ControlsPerLine - 1) do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;
              Size:= Size / 2.0;
              W:= W + Size + SpacingHorizontal;

              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, W - Shift);
                end;
              end;
              W:= W + Size;
            end;

            { shift all controls to center }
            WHalf:= W / 2.0;
            for i:= 0 to (ControlsCount - 1) do
            begin
              Control:= Controls[i];
              Control.Anchor(AlignmentHorizontal, Control.Translation.X - WHalf);
            end;
          end;
        end;
      end;
    TopToBottomThenLeftToRight:
      begin
        { Set vertical posotion for rows }
        case AlignmentVertical of
        vpTop:
          begin
            for j:= 0 to (ControlsPerLine - 1) do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, -H);
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;

              H:= H + Size + SpacingVertical;
            end;
          end;
        vpBottom:
          begin
            for j:= (ControlsPerLine - 1) downto 0 do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, H);
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;

              H:= H + Size + SpacingVertical;
            end;
          end;
        vpMiddle:
          begin
            Shift:= (PaddingVertical + SpacingVertical) / 2.0;
            for j:= 0 to (ControlsPerLine - 1) do
            begin
              Size:= 0.0;
              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  MaxVar(Size, Control.EffectiveHeight);
                end;
              end;
              Size:= Size / 2.0;
              H:= H + Size + SpacingVertical;

              for i:= 0 to (LinesCount - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentVertical, -H + Shift);
                end;
              end;
              H:= H + Size;
            end;

            { shift all controls to center }
            HHalf:= H / 2.0;
            for i:= 0 to (ControlsCount - 1) do
            begin
              Control:= Controls[i];
              Control.Anchor(AlignmentVertical, Control.Translation.Y + HHalf);
            end;
          end;
        end;

        { Set horizontal posotion for columns }
        case AlignmentHorizontal of
        hpLeft:
          begin
            for i:= 0 to (LinesCount - 1) do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, W);
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;

              W:= W + Size + SpacingHorizontal;
            end;
          end;
        hpRight:
          begin
            for i:= (LinesCount - 1) downto 0 do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, -W);
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;

              W:= W + Size + SpacingHorizontal;
            end;
          end;
        hpMiddle:
          begin
            Shift:= (PaddingHorizontal + SpacingHorizontal) / 2.0;
            for i:= 0 to (LinesCount - 1) do
            begin
              Size:= 0.0;
              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  MaxVar(Size, Control.EffectiveWidth);
                end;
              end;
              Size:= Size / 2.0;
              W:= W + Size + SpacingHorizontal;

              for j:= 0 to (ControlsPerLine - 1) do
              begin
                idx:= i * ControlsPerLine + j;
                if (idx < ControlsCount) then
                begin
                  Control:= Controls[idx];
                  Control.Anchor(AlignmentHorizontal, W - Shift);
                end;
              end;
              W:= W + Size;
            end;

            { shift all controls to center }
            WHalf:= W / 2.0;
            for i:= 0 to (ControlsCount - 1) do
            begin
              Control:= Controls[i];
              Control.Anchor(AlignmentHorizontal, Control.Translation.X - WHalf);
            end;
          end;
        end;
      end;
  end;

  W:= W - SpacingHorizontal + PaddingHorizontal;
  H:= H - SpacingVertical + PaddingVertical;
end;

function TCastleGridGroup.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Layout', 'ControlsPerLine',
       'AlignmentVertical', 'AlignmentHorizontal',
       'PaddingVertical', 'PaddingHorizontal',
       'SpacingVertical', 'SpacingHorizontal'
     ]) then
    Result:= [psBasic]
  else if ArrayContainsString(PropertyName, [
       'Padding', 'Spacing'
     ]) then
    Result:= Result * []
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TCastleGridGroup, 'Grid Group');
end.

