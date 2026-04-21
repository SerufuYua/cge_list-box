{ Main view, where most of the application logic takes place.

  Feel free to use this code as a starting point for your own projects.
  This template code is in public domain, unlike most other CGE code which
  is covered by BSD or LGPL (see https://castle-engine.io/license). }
unit GameViewMain;

interface

uses Classes,
  CastleVectors, CastleComponentSerialize,
  CastleUIControls, CastleControls, CastleKeysMouse, CastleNotifications,
  CastleListBox, CastleCheckListBox, CastleColorListBox,
  CastleCheckColorListBox;

type
  { Main view, where most of the application logic takes place. }
  TViewMain = class(TCastleView)
  protected
    procedure ClickList(Sender: TObject);
    procedure ClickSecond(Sender: TObject);
    procedure ClickColorList(Sender: TObject);
    procedure ClickCheckColorList(Sender: TObject);
    procedure CheckList(Sender: TObject; AIndex: Integer; ACheck: Boolean);
    procedure ClickShowHex(Sender: TObject);
    procedure CursorArrive(Sender: TObject);
    procedure CursorHover(Sender: TObject; AIndex: Integer);
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    ListBox: TCastleListBox;
    CheckListBox: TCastleCheckListBox;
    ColorListBox: TCastleColorListBox;
    CheckColorListBox: TCastleCheckColorListBox;
    ShowHex: TCastleCheckbox;
    RectangleBG: TCastleRectangleControl;
    Notifications: TCastleNotifications;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewMain: TViewMain;

implementation

uses
  SysUtils, CastleColors, CastleListBoxBase;

{ TViewMain ----------------------------------------------------------------- }

constructor TViewMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl:= 'castle-data:/gameviewmain.castle-user-interface';
end;

procedure TViewMain.Start;
begin
  inherited;

  ListBox.OnChange:= {$ifdef FPC}@{$endif}ClickList;
  ListBox.OnClickSecond:= {$ifdef FPC}@{$endif}ClickSecond;
  ListBox.OnCursorArrive:= {$ifdef FPC}@{$endif}CursorArrive;
  ListBox.OnLineHover:= {$ifdef FPC}@{$endif}CursorHover;
  CheckListBox.OnChange:= {$ifdef FPC}@{$endif}ClickList;
  CheckListBox.OnCheck:= {$ifdef FPC}@{$endif}CheckList;
  CheckListBox.OnClickSecond:= {$ifdef FPC}@{$endif}ClickSecond;
  CheckListBox.OnCursorArrive:= {$ifdef FPC}@{$endif}CursorArrive;
  ColorListBox.OnClick:= {$ifdef FPC}@{$endif}ClickColorList;
  CheckColorListBox.OnClick:= {$ifdef FPC}@{$endif}ClickCheckColorList;
  ShowHex.OnChange:= {$ifdef FPC}@{$endif}ClickShowHex;

  CheckListBox.SetCheck(1, True);
  CheckListBox.SetCheck(2, True);
  CheckListBox.SetCheck(3, True);
  CheckColorListBox.SetCheck(2, True);
  CheckColorListBox.SetCheck(3, True);
  CheckColorListBox.SetCheck(4, True);
end;

procedure TViewMain.ClickList(Sender: TObject);
begin
  Notifications.Show((Sender as TComponent).Name + ': selected line ' +
                     IntToStr((Sender as TCastleListBoxBase).Index));
end;

procedure TViewMain.ClickSecond(Sender: TObject);
begin
  Notifications.Show((Sender as TComponent).Name + ': second click to line ' +
                     IntToStr((Sender as TCastleListBoxBase).Index));
end;

procedure TViewMain.ClickColorList(Sender: TObject);
var
  ColorBox: TCastleColorListBox;
begin
  ColorBox:= Sender as TCastleColorListBox;

  if CheckColorListBox.GetCheck(CheckColorListBox.Index) then
  begin
    CheckColorListBox.SetColor(CheckColorListBox.Index, ColorBox.GetColor(ColorBox.Index));
    Notifications.Show('set color: ' +
                       ColorListBox.GetColor(ColorListBox.Index).ToRawString('%2.3F') +
                       ' to line ' + IntToStr(CheckColorListBox.Index));
  end
  else
    Notifications.Show('line: ' + IntToStr(CheckColorListBox.Index) + ' is blocked');
end;

procedure TViewMain.ClickCheckColorList(Sender: TObject);
var
  ColorChkBox: TCastleCheckColorListBox;
begin
  ColorChkBox:= Sender as TCastleCheckColorListBox;

  if ColorChkBox.GetCheck(ColorChkBox.Index) then
  begin
    RectangleBG.Color:= ColorChkBox.GetColor(ColorChkBox.Index);
    Notifications.Show('set color: ' +
                       ColorChkBox.GetColor(ColorChkBox.Index).ToRawString('%2.3F'));
  end
  else
    Notifications.Show('line: ' + IntToStr(ColorChkBox.Index) + ' is blocked');

end;

procedure TViewMain.CheckList(Sender: TObject; AIndex: Integer; ACheck: Boolean);
begin
  Notifications.Show((Sender as TComponent).Name + ': checked line ' +
                     IntToStr(AIndex) + ' to ' +
                     BoolToStr(ACheck, True));
end;

procedure TViewMain.ClickShowHex(Sender: TObject);
begin
  ColorListBox.ShowText:= (Sender as TCastleCheckbox).Checked;
end;

procedure TViewMain.CursorArrive(Sender: TObject);
begin
  Notifications.Show('Cursor arrive to Target');
end;

procedure TViewMain.CursorHover(Sender: TObject; AIndex: Integer);
begin
  Notifications.Show('Hover to ' + IntToStr(AIndex));
end;

procedure TViewMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  { This virtual method is executed every frame (many times per second). }
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption:= 'FPS: ' + Container.Fps.ToString;
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;
begin
  Result:= inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { This virtual method is executed when user presses
    a key, a mouse button, or touches a touch-screen.

    Note that each UI control has also events like OnPress and OnClick.
    These events can be used to handle the "press", if it should do something
    specific when used in that UI control.
    The TViewMain.Press method should be used to handle keys
    not handled in children controls.
  }

  // Use this to handle keys:
  {
  if Event.IsKey(keyXxx) then
  begin
    // DoSomething;
    Exit(true); // key was handled
  end;
  }
end;

end.
