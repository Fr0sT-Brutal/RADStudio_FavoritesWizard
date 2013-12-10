//* Favs expert/wizard for RAD studio *\\
//*          Settings form            *\\
//*             © Fr0sT               *\\

unit WizFavs.FormSettings;

interface

uses
  SysUtils, Classes, Controls, Forms, StdCtrls, ExtCtrls, ComCtrls, Menus, Windows,
  WizFavs.BaseWiz, WizFavs.Main;

type
  TfrmSettings = class(TForm)
    btnCancel: TButton;
    btnOk: TButton;
    cbDestToolbar: TComboBox;
    cbMainMenuInsertAfter: TComboBox;
    cbSubMenuInsertInto: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    panMainMenu: TPanel;
    panSubMenu: TPanel;
    panToolbar: TPanel;
    rgPlacement: TRadioGroup;
    submenu: TLabel;
    cbSubMenuInsertAfter: TComboBox;
    udBtnIndex: TUpDown;
    eBtnIndex: TEdit;
    Label5: TLabel;
    procedure rgPlacementClick(Sender: TObject);
    procedure cbSubMenuInsertIntoChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    FCurrPanel: TPanel;
    FConfig: TConfig;
  end;

function Execute(var Config: TConfig): TModalResult;

implementation

{$R *.dfm}

function Execute(var Config: TConfig): TModalResult;
begin
  with TfrmSettings.Create(Application) do
  begin
    FConfig := Config;
    Result := ShowModal;
    if Result = mrOk then
      Config := FConfig;
    Free;
  end;
end;

procedure TfrmSettings.FormShow(Sender: TObject);
var tb: TIDEToolbar;
    mi: TMenuItem;
begin
  // placement
  rgPlacement.ItemIndex := Integer(Config.ShowPlacement);
  // placement on toolbar
  for tb := Low(TIDEToolbar) to High(TIDEToolbar) do
    cbDestToolbar.Items.Add(SToolbarLabels[tb]);
  cbDestToolbar.ItemIndex := Integer(Config.ToolbarOptions.Toolbar);
  udBtnIndex.Position := Config.ToolbarOptions.ButtonIdx;
  // placement in main menu
  for mi in MainMenu.Items do
    if StripHotkey(mi.Caption) <> SMenuCaption then
      cbMainMenuInsertAfter.Items.Add(StripHotkey(mi.Caption));
  cbMainMenuInsertAfter.ItemIndex :=
    cbMainMenuInsertAfter.Items.IndexOf(Config.MainMenuOptions.InsertAfter);
  // placement in sub menu
  for mi in MainMenu.Items do
    if StripHotkey(mi.Caption) <> SMenuCaption then
      cbSubMenuInsertInto.Items.Add(StripHotkey(mi.Caption));
  cbSubMenuInsertInto.ItemIndex :=
    cbSubMenuInsertInto.Items.IndexOf(Config.SubMenuOptions.InsertInto);
  cbSubMenuInsertIntoChange(cbSubMenuInsertInto);
  cbSubMenuInsertAfter.ItemIndex :=
    cbSubMenuInsertAfter.Items.IndexOf(Config.SubMenuOptions.InsertAfter);
end;

procedure TfrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
var
  ToolbarObj: TToolBar;
begin
  if ModalResult = mrOk then
  begin
    // placement
    Config.ShowPlacement := TShowPlacement(rgPlacement.ItemIndex);
    // save only current placement options
    case Config.ShowPlacement of
      spToolbar:
        with FConfig.ToolbarOptions do
        begin
          Toolbar := TIDEToolbar(cbDestToolbar.ItemIndex);
          ButtonIdx := udBtnIndex.Position;
          // check that destination toolbar is visible
          ToolbarObj := INSrv.ToolBar[SToolbarNames[FConfig.ToolbarOptions.Toolbar]];
          if ToolbarObj <> nil then
            if not ToolbarObj.Visible then
              if MessageBox(Application.Handle,
                            PChar(Format(SMsgWarnToolbarInvisible, [SToolbarLabels[FConfig.ToolbarOptions.Toolbar]])),
                            PChar(SWizardName), MB_YESNO or MB_ICONWARNING) = ID_YES then
                ToolbarObj.Visible := True;
        end;
      spMainMenu:
        with FConfig.MainMenuOptions do
        begin
          InsertAfter := cbMainMenuInsertAfter.Items[cbMainMenuInsertAfter.ItemIndex];
        end;
      spSubMenu:
        with FConfig.SubMenuOptions do
        begin
          InsertInto := cbSubMenuInsertInto.Items[cbSubMenuInsertInto.ItemIndex];
          InsertAfter := cbSubMenuInsertAfter.Items[cbSubMenuInsertAfter.ItemIndex];
        end;
    end; // case
  end; // if
end;

procedure TfrmSettings.cbSubMenuInsertIntoChange(Sender: TObject);
var mi: TMenuItem;
    i: Integer;
begin
  mi := MainMenu.Items.Find(TComboBox(Sender).Items[TComboBox(Sender).ItemIndex]);
  if mi = nil then Exit;
  cbSubMenuInsertAfter.Clear;
  for i := 0 to mi.Count - 1 do
    if StripHotkey(mi.Items[i].Caption) <> SMenuCaption then
      cbSubMenuInsertAfter.Items.Add(StripHotkey(mi.Items[i].Caption));
end;

procedure TfrmSettings.rgPlacementClick(Sender: TObject);
var NextPanel: TPanel;
begin
  case TRadioGroup(Sender).ItemIndex of
    0 : NextPanel := panToolbar;
    1 : NextPanel := panMainMenu;
    2 : NextPanel := panSubMenu;
    else Exit;
  end;
  if NextPanel = FCurrPanel then Exit;

  NextPanel.Visible := True;
  if FCurrPanel <> nil then
    FCurrPanel.Visible := False;
  FCurrPanel := NextPanel;
end;

end.
