//* Favs expert/wizard for RAD studio *\\
//*            Main unit              *\\
//*             © Fr0sT               *\\

unit WizFavs.Main;

interface

uses Windows, Classes, Menus, SysUtils, ComCtrls, Registry, TypInfo, Controls,
     Graphics, ExtCtrls, Forms, StrUtils,
     ToolsApi,
     WizFavs.BaseWiz;

type
  TShowPlacement = (spToolbar, spMainMenu, spSubMenu);

  TIDEToolbar =
    (tbAlign, tbBrowser, tbCustom, tbDebug, tbDesktop, tbHTMLDesign,
     tbHTMLFormat, tbHTMLTable, tbPersonality, tbPosition, tbSpacing,
     tbStandard, tbView, tbPersonal);

  TFavsWizard = class(TBaseWizard)
  private
    type
      TExpertIcon = (icoMain, icoAdd, icoManage, icoOptions);
      TMainActions = (actAddProj, actAddProjGroup, actManageList, actOptions, actDivider);
      // Toolbar event listener
      TToolbarNotifier = class(TNotifierObject, INTAToolbarStreamNotifier)
      private
        FOwner: TFavsWizard;
        FCurrToolbar: TToolBar;
      public
        // useless stuff
        procedure AfterSave; overload;
        procedure BeforeSave; overload;
        procedure AfterSave(AToolbar: TWinControl); overload;
        // toolbar event handlers
        procedure BeforeSave(AToolbar: TWinControl); overload;
        procedure ToolbarLoaded(AToolbar: TWinControl);
      end;
    const
      IconNames: array[TExpertIcon] of string = ('Main', 'Add', 'Manage', 'Options');
    var
      FControlsInstalled: Boolean;
      FMenuItem: TMenuItem; // to show in main menu or submenu
      FConstSubMenuItems: array[TMainActions] of TMenuItem; // main actions
      FPopupMenu: TPopupMenu;
      FToolBtn: TToolButton;    // to show in toolbar
      FFavList: TStringList;    // the favs list itself
      FIconIndexes: array[TExpertIcon] of Integer;
      FToolbarNotifier: TToolbarNotifier;
      FNotifierIdx: Integer;
    // methods
    function  GetCurrMenu: TMenuItem;
    procedure ReadSettings;
    procedure SaveSettings;
    procedure Fill;
    procedure Remove;
    procedure FillFavItems(miParent: TMenuItem);
    procedure AddNewFavItem(miParent: TMenuItem; ItemIdx: Integer);
    // event handlers
    procedure PopupMenuPopup(Sender: TObject);
    procedure MenuItemAddProjectClick(Sender: TObject);
    procedure MenuItemAddPrGroupClick(Sender: TObject);
    procedure MenuItemManageListClick(Sender: TObject);
    procedure MenuItemOptionsClick(Sender: TObject);
    procedure MenuItemOpenItemClick(Sender: TObject);
  public
    constructor Create;

    function CheckReady: Boolean; override;
    procedure Startup; override;
    procedure Cleanup; override;
  end;

  // It's better make config instance a field of the wizard class but when placing
  // this definition before class defnition, IDE's error insight goes crazy.
  // So we use dumb global variable instead.
  TConfig = record
    ShowPlacement: TShowPlacement;
    ToolbarOptions:
      record
        Toolbar: TIDEToolbar;
        ButtonIdx: Integer;
      end;
    MainMenuOptions:
      record
        InsertAfter: string;  // name of Main menu item
      end;
    SubMenuOptions:
      record
        InsertInto: string;   // name of Main menu item
        InsertAfter: string;  // name of submenu item
      end;

    procedure CorrectValues;
  end;

var
  MainMenu: TMainMenu;
//  SubMenu: TMenuItem;
  Config: TConfig;

resourcestring
  SMenuCaption = 'Favorites';
  SToolbarName = 'Favs wizard separate';
  SMenuAddProjectEmpty = 'No current project';
  SMenuAddProjectPatt = 'Add project %s';
  SMenuAddProjectAlready = 'Project %s already added';
  SMenuAddProjGroupEmpty = 'No current project group';
  SMenuAddProjGroupPatt = 'Add project group %s';
  SMenuAddProjGroupAlready = 'Project group %s already added';
  SMenuManageList = 'Manage Favorites list...';
  SMenuOptions = 'Options...';
  SMsgUnsupportedIDE = 'Necessary IDE service not found';
  SMsgRegKeyFail = 'Cannot open/create registry key ';
  SMsgErrRegistering = 'Error registering expert %s.'#13#10'%s';
  SMsgErrToolbarCreate = 'Could not create personal toolbar';
  SMsgErrToolbarNotFound = 'Toolbar %s not found';
  SMsgWarnToolbarInvisible = 'You placed FavsManager button to toolbar %s which is currently invisible.'#13#10'Show it?';
  SMsgErrFileNotExist = 'File %s not exist.'#13#10'Please save the project before adding it to favorites.';

const // not localizable
  SWizardName = 'Favorites manager';
  SWizardID = 'Fr0sT.FavoritesWizard';
  SMenuTools = 'Tools';
  SFavsWizToolBar = 'FavsWizToolBar';
  SKeyFavPrefix = 'Fav_';
  SKeyShowOptsPrefix = 'ShowOpts_';
  SKeyShowPlace = 'ShowPlace';
  // IDE constants
  SToolbarNames: array[TIDEToolbar] of string =
    (sAlignToolbar, sBrowserToolbar, sCustomToolBar, sDebugToolBar, sDesktopToolBar,
     sHTMLDesignToolbar, sHTMLFormatToolbar, sHTMLTableToolbar, sPersonalityToolBar,
     sPositionToolbar, sSpacingToolbar, sStandardToolBar, sViewToolBar, SFavsWizToolBar);
var
  // Displayable toolbar names, generated from SToolbarNames by removing 'Toolbar' part
  SToolbarLabels: array[TIDEToolbar] of string;

implementation

uses WizFavs.FormFavList, WizFavs.FormSettings;

const
  ShowPlacementOptionCount: array[TShowPlacement] of Cardinal =
    (2, 1, 2);
  ConstMenuCaptions: array[TFavsWizard.TMainActions] of string =
    (SMenuAddProjectEmpty, SMenuAddProjGroupEmpty, SMenuManageList, SMenuOptions, '-');

{$REGION 'Utils'}

type
  TStrArray = TArray<string>;

// String with separators => array of strings
function Split(const Str: string; Delim: string; AllowEmpty: Boolean): TStrArray;
var CurrDelim, NextDelim, CurrIdx: Integer;
begin
  if Str = '' then begin SetLength(Result, 0); Exit; end;
  CurrDelim := 1; CurrIdx := 0; SetLength(Result, 16);
  repeat
    if CurrIdx = Length(Result) then
      SetLength(Result, CurrIdx + 16);
    NextDelim := PosEx(Delim, Str, CurrDelim);
    if NextDelim = 0 then NextDelim := Length(Str)+1;
    Result[CurrIdx] := Copy(Str, CurrDelim, NextDelim - CurrDelim);
    CurrDelim := NextDelim + Length(Delim);
    if (Result[CurrIdx] <> '') or AllowEmpty
      then Inc(CurrIdx)
      else Continue;
  until CurrDelim > Length(Str);
  SetLength(Result, CurrIdx);
end;

// Array of strings => one string with separators
function Join(const Arr: array of string; Delim: string; AllowEmpty: Boolean): string;
var
  i: Integer;
  WasAdded: Boolean;
begin
  Result := ''; WasAdded := False;
  for i := Low(Arr) to High(Arr) do
  begin
    if (Arr[i] = '') and not AllowEmpty then Continue;
    if not WasAdded
      then Result := Arr[i]
      else Result := Result + Delim + Arr[i];
    WasAdded := True;
  end;
end;

// Create new toolbutton and insert it to the given index in the toolbar
//   InsertAfter is the desired index of a new button
//   Pass any value >= Tb.ButtonCount (i.e. MaxInt) to add new button to the toolbar end
function InsertToolButton(var Tb: TToolBar; InsertIndex: Integer = 0; Button: TToolButton = nil): TToolButton;
begin
  if Button = nil then
    Result := TToolButton.Create(Tb)
  else
    Result := Button;
  // Some range checks
  if InsertIndex > Tb.ButtonCount then
    InsertIndex := Tb.ButtonCount;
  if InsertIndex < 0 then
    InsertIndex := 0;
  // Set button position
  if InsertIndex = 0
    then Result.Left := 0
    else Result.Left := Tb.Buttons[InsertIndex - 1].Left + Tb.Buttons[InsertIndex - 1].Width;
  // Add to toolbar. This MUST be done strictly after position setting, otherwise
  // terrible bugs occur
  Result.Parent := Tb;
end;

{$ENDREGION}

function CreateInstFunc: TBaseWizard;
begin
  Result := TFavsWizard.Create;
end;

{$REGION 'TConfig'}

// checks field values and sets default if needed
procedure TConfig.CorrectValues;
begin
  if ShowPlacement = TShowPlacement(-1) then
    ShowPlacement := spToolbar;

  if ToolbarOptions.Toolbar = TIDEToolbar(-1) then
    ToolbarOptions.Toolbar := tbPersonal;
  if ToolbarOptions.ButtonIdx = -1 then
    ToolbarOptions.ButtonIdx := 0;

  if SubMenuOptions.InsertInto = '' then
    SubMenuOptions.InsertInto := SMenuTools;
end;

{$ENDREGION}

{$REGION 'TToolbarNotifier'}

procedure TFavsWizard.TToolbarNotifier.AfterSave; begin end;

procedure TFavsWizard.TToolbarNotifier.BeforeSave; begin end;

procedure TFavsWizard.TToolbarNotifier.AfterSave(AToolbar: TWinControl); begin end;

// toolbar is about to be saved - remove our button from it
procedure TFavsWizard.TToolbarNotifier.BeforeSave(AToolbar: TWinControl);
begin
  // toolbar is ours?
  if (AToolbar = FCurrToolbar) and (Config.ShowPlacement = spToolbar) then
    FOwner.Remove;
end;

// toolbar has been read from registry - add our button to it
procedure TFavsWizard.TToolbarNotifier.ToolbarLoaded(AToolbar: TWinControl);
begin
  if not FOwner.Started then Exit; // Wizard hasn't started yet (no settings etc)

  // current show place is toolbar?
  if Config.ShowPlacement = spToolbar then
    // names of toolbars are equal?
    if TToolBar(AToolbar).Name = SToolbarNames[Config.ToolbarOptions.Toolbar] then
      // our cached toolbar has gone, there's new one.
      // !!! when destroying, a toolbar destroys our button too. So we must
      // nil it here. Then save new toolbar reference and install the button to it
      if AToolbar <> FCurrToolbar then
      begin
        FOwner.FToolBtn := nil;
        FOwner.Remove;
        FCurrToolbar := TToolBar(AToolbar);
        FOwner.Fill;
      end;
end;

{$ENDREGION}

{$REGION 'TEFavManager'}

// *** life cycle ***

constructor TFavsWizard.Create;
var bmp: TBitmap;
    icon: TExpertIcon;
begin
  inherited Create([optUseConfig, optUseDelayed]);

  FFavList := TStringList.Create;

  // create and fill icon list
  bmp := TBitmap.Create;
  bmp.Transparent := True;
  bmp.TransparentColor := clFuchsia;
  for icon := Low(TExpertIcon) to High(TExpertIcon) do
  begin
    bmp.LoadFromResourceName(HInstance, 'Bitmap_'+IconNames[icon]);
    FIconIndexes[icon] := INSrv.AddMasked(bmp, bmp.TransparentColor, SWizardName + '.' + IconNames[icon]);
  end;
  bmp.Free;

  // we'll create other controls and read settings later, in Startup
end;

procedure TFavsWizard.ReadSettings;
var i: Integer;
    place: TShowPlacement;
    s: string;
    arr: TStrArray;
    tmp: TStringList;
begin
  // read show placement
  s := ConfigKey.ReadString(SKeyShowPlace);
  Config.ShowPlacement := TShowPlacement(GetEnumValue(TypeInfo(TShowPlacement), s));
  // read show placements' options
  for place := Low(TShowPlacement) to High(TShowPlacement) do
  begin
    s := ConfigKey.ReadString(SKeyShowOptsPrefix + GetEnumName(TypeInfo(TShowPlacement), Integer(place)));
    arr := Split(s, ';', False);
    if Length(arr) < ShowPlacementOptionCount[place] then
      SetLength(arr, ShowPlacementOptionCount[place]);
    case place of
      spToolbar:
        begin
          Config.ToolbarOptions.Toolbar := TIDEToolbar(StrToIntDef(arr[0], -1));
          Config.ToolbarOptions.ButtonIdx := StrToIntDef(arr[1], -1);
        end;
      spMainMenu:
        begin
          Config.MainMenuOptions.InsertAfter := arr[0];
        end;
      spSubMenu:
        begin
          Config.SubMenuOptions.InsertInto := arr[0];
          Config.SubMenuOptions.InsertAfter := arr[1];
        end;
    end;
  end;
  Config.CorrectValues;

  // read favs list - values with names "Fav_##"
  tmp := TStringList.Create;
  ConfigKey.GetValueNames(tmp);
  for i := 0 to tmp.Count - 1 do
    if Pos(SKeyFavPrefix, tmp[i]) = 1 then
      FFavList.Add(ConfigKey.ReadString(tmp[i]));
  FreeAndNil(tmp);
end;

procedure TFavsWizard.SaveSettings;
var tmp: TStringList;
    i: Integer;
    place: TShowPlacement;
    s: string;
begin
  // write general options
  ConfigKey.WriteString(SKeyShowPlace,
                         GetEnumName(TypeInfo(TShowPlacement), Integer(Config.ShowPlacement)));

  // write show placement options
  for place := Low(TShowPlacement) to High(TShowPlacement) do
  begin
    case place of
      spToolbar:
        s := Join([IntToStr(Integer(Config.ToolbarOptions.Toolbar)),
                   IntToStr(Config.ToolbarOptions.ButtonIdx)], ';', False);
      spMainMenu:
        s := Join([Config.MainMenuOptions.InsertAfter], ';', False);
      spSubMenu:
        s := Join([Config.SubMenuOptions.InsertInto,
                   Config.SubMenuOptions.InsertAfter], ';', False);
    end;
    ConfigKey.WriteString(SKeyShowOptsPrefix + GetEnumName(TypeInfo(TShowPlacement), Integer(place)), s);
  end;

  // write fav list
  if (FFavList <> nil) and (FFavList.Count > 0) then
  begin
    // remove old fav list - values with decimal number names
    tmp := TStringList.Create;
    ConfigKey.GetValueNames(tmp);
    for i := 0 to tmp.Count - 1 do
      if Pos(SKeyFavPrefix, tmp[i]) = 1 then
        ConfigKey.DeleteValue(tmp[i]);
    FreeAndNil(tmp);
    // write new values
    for i := 0 to FFavList.Count - 1 do
      ConfigKey.WriteString( Format(SKeyFavPrefix + '%.2d', [i]), FFavList[i]);
  end;
end;

procedure TFavsWizard.Cleanup;
var act: TMainActions;
begin
  SaveSettings;

  // remove inserted controls
  Remove;

  // dispose all objects
  INSrv.UnregisterToolbarNotifier(FNotifierIdx); // this will delete the object also
  for act := Low(TMainActions) to High(TMainActions) do
    FreeAndNil(FConstSubMenuItems[act]);
  FreeAndNil(FFavList);
  FreeAndNil(FPopupMenu);
  FreeAndNil(FToolBtn);
  FreeAndNil(FMenuItem);
  inherited;
end;

procedure TFavsWizard.Startup;
var act: TMainActions;
begin
  // ** create constant menu items **

  for act := Low(TMainActions) to High(TMainActions) do
  begin
    FConstSubMenuItems[act] := TMenuItem.Create(nil);
    FConstSubMenuItems[act].Caption := ConstMenuCaptions[act];
    FConstSubMenuItems[act].Tag := -1; // !
  end;

  FConstSubMenuItems[actAddProj].OnClick := MenuItemAddProjectClick;
  FConstSubMenuItems[actAddProj].ImageIndex := FIconIndexes[icoAdd];
  FConstSubMenuItems[actAddProjGroup].OnClick := MenuItemAddPrGroupClick;
  FConstSubMenuItems[actAddProjGroup].ImageIndex := FIconIndexes[icoAdd];
  FConstSubMenuItems[actManageList].OnClick := MenuItemManageListClick;
  FConstSubMenuItems[actManageList].ImageIndex := FIconIndexes[icoManage];
  FConstSubMenuItems[actOptions].OnClick := MenuItemOptionsClick;
  FConstSubMenuItems[actOptions].ImageIndex := FIconIndexes[icoOptions];

  // create toolbar button popup menu
  FPopupMenu := TPopupMenu.Create(nil);
  FPopupMenu.Images := INSrv.ImageList;
  FPopupMenu.OnPopup := PopupMenuPopup;

  // create object for main or sub menu
  FMenuItem := TMenuItem.Create(nil);
  FMenuItem.Caption := SMenuCaption;

  // create and install the toolbar notifier to catch when it's modified or streamed from registry
  FToolbarNotifier := TToolbarNotifier.Create;
  FToolbarNotifier.FOwner := Self;
  FNotifierIdx := INSrv.RegisterToolbarNotifier(FToolbarNotifier as INTAToolbarStreamNotifier);

  ReadSettings;
  Fill;                          // insert our control into IDE
end;

function TFavsWizard.CheckReady: Boolean;
begin
  MainMenu := INSrv.MainMenu;
  Result := (MainMenu <> nil); // get IDE menu - could be NULL if IDE hasn't been loaded yet
end;

// *** methods ***

// returns current menu depending on current FShowPlaces value
function TFavsWizard.GetCurrMenu: TMenuItem;
begin
  case Config.ShowPlacement of
    spMainMenu, spSubMenu:
      Result := FMenuItem;
    spToolbar:
      Result := FPopupMenu.Items;
    else // shouldn't happen
      Result := nil;
  end;
end;

// fills show place (based on current FShowPlaces value)
procedure TFavsWizard.Fill;
var mi, miParent: TMenuItem;
    s: string;
    Toolbar: TToolBar;
    ToolBtn: TToolButton;
begin
  if FControlsInstalled then Exit; // Controls are installed currently

  try
    miParent := GetCurrMenu;
    if miParent = nil then Exit;

    // add constant items
    for mi in FConstSubMenuItems do
      miParent.Add(mi);
    // add favs list
    FillFavItems(miParent);

    // insert the control to IDE
    case Config.ShowPlacement of
      spMainMenu:
        begin
          // check if the item exists already and remove it if yes
          // this might happen accidently due to weird wizard load/unload cycle
          mi := MainMenu.Items.Find(SMenuCaption);
          if mi <> nil then
            MainMenu.Items.Remove(mi);
          mi := MainMenu.Items.Find(Config.MainMenuOptions.InsertAfter);
          if mi = nil
            then MainMenu.Items.Insert(MainMenu.Items.Count - 1, miParent)
            else MainMenu.Items.Insert(MainMenu.Items.IndexOf(mi) + 1, miParent);
        end;
      spSubMenu:
        begin
          {}
        end;
      spToolbar:
        begin
          s := SToolbarNames[Config.ToolbarOptions.Toolbar];
          Toolbar := INSrv.ToolBar[s];
          // Whether the toolbar exist?
          if Toolbar = nil then
            // The wizard's personal toolbar - try to create
            if Config.ToolbarOptions.Toolbar = tbPersonal then
            begin
              Toolbar := INSrv.NewToolbar(s, s);
              if Toolbar = nil then
                raise Exception.Create(SMsgErrToolbarCreate);
              Toolbar.Visible := True;
            end
            // Standard toolbar - shit happened, raise error
            else
              raise Exception.Create(Format(SMsgErrToolbarNotFound, [s]));
          // check if button exists and remove if yes
          for ToolBtn in Toolbar do
            if ToolBtn.Caption = SWizardID then
              ToolBtn.Parent := nil;
          // create toolbar button
          if FToolBtn = nil then
          begin
            FToolBtn := TToolButton.Create(nil);
            with FToolBtn do
            begin
              Style := tbsDropDown;
              Caption := SWizardID; // for search only; shouldn't be shown
              ShowHint := True;
              Hint := SWizardName;
              DropdownMenu := FPopupMenu;
              ImageIndex := FIconIndexes[icoMain];
            end;
          end;
          InsertToolButton(Toolbar, Config.ToolbarOptions.ButtonIdx, FToolBtn);
        end;
    end;

    // if personal toolbar appear empty, hide it (will be removed after IDE reload)
    Toolbar := INSrv.ToolBar[SToolbarNames[tbPersonal]];
    if (Toolbar <> nil) and (Toolbar.ButtonCount = 0) then
      Toolbar.Visible := False;

    FControlsInstalled := True;
  except on E: Exception do
    Log(E.Message);
  end;
end;

// clears show place (based on current Config.ShowPlacement value)
procedure TFavsWizard.Remove;
var mi: TMenuItem;
begin
  if not FControlsInstalled then Exit; // controls aren't installed currently

  // remove constant items - just remove, not free!
  for mi in FConstSubMenuItems do
    GetCurrMenu.Remove(mi);
  GetCurrMenu.Clear; // remove all remaininig subitems (favs list)

  // remove the control from IDE
  case Config.ShowPlacement of
    spMainMenu:
      MainMenu.Items.Remove(FMenuItem);
    spSubMenu:
      ;
    spToolbar:
      // button could have been destroyed already on toolbar destroy so we must
      // check its value
      if FToolBtn <> nil then
        FToolBtn.Parent := nil;
  end;

  FControlsInstalled := False;
end;

// Add one fav item to the menu
procedure TFavsWizard.AddNewFavItem(miParent: TMenuItem; ItemIdx: Integer);
var mi: TMenuItem;
begin
  if miParent = nil then
    miParent := GetCurrMenu;
  if miParent = nil then Exit;

  mi := TMenuItem.Create(miParent);
  mi.Caption := FFavList[ItemIdx];
  mi.Tag := ItemIdx;
  mi.OnClick := MenuItemOpenItemClick;
  if not FileExists(FFavList[ItemIdx]) then
    mi.Enabled := False;
  miParent.Add(mi);
end;

// Re-fill all the fav list
procedure TFavsWizard.FillFavItems(miParent: TMenuItem);
var i: Integer;
begin
  if miParent = nil then
    miParent := GetCurrMenu;
  if miParent = nil then Exit;

  // remove all previous fav items - they have Tag <> -1
  i := 0;
  while i < miParent.Count do
    if miParent.Items[i].Tag <> -1 then
      miParent.Delete(i)
    else
      Inc(i);
  // add new items according to FFavList
  for i := 0 to FFavList.Count - 1 do
    AddNewFavItem(miParent, i);
end;

// *** event handlers ***

procedure TFavsWizard.MenuItemAddProjectClick(Sender: TObject);
var proj: string;
begin
  if ModuleSrv.GetActiveProject <> nil
    then proj := ModuleSrv.GetActiveProject.FileName
    else proj := '';
  if proj = '' then Exit; // project not exist or something else
  if FFavList.IndexOf(proj) <> -1 then Exit; // in the list already
  if not FileExists(proj) then
    raise Exception.Create(Format(SMsgErrFileNotExist, [proj]));
  FFavList.Add(proj);
  AddNewFavItem(nil, FFavList.Count - 1);
end;

procedure TFavsWizard.MenuItemAddPrGroupClick(Sender: TObject);
var proj: string;
begin
  if ModuleSrv.MainProjectGroup <> nil
    then proj := ModuleSrv.MainProjectGroup.FileName
    else proj := '';
  if proj = '' then Exit; // project not exist or something else
  if FFavList.IndexOf(proj) <> -1 then Exit; // in the list already
  if not FileExists(proj) then
    raise Exception.Create(Format(SMsgErrFileNotExist, [proj]));
  FFavList.Add(proj);
  AddNewFavItem(nil, FFavList.Count - 1);
end;

procedure TFavsWizard.MenuItemManageListClick(Sender: TObject);
begin
  if WizFavs.FormFavList.Execute(FFavList) <> mrOk then Exit;
  FillFavItems(nil);
  SaveSettings;
end;

procedure TFavsWizard.MenuItemOptionsClick(Sender: TObject);
var tmpConfig: TConfig;
begin
  tmpConfig := Config;
  if WizFavs.FormSettings.Execute(tmpConfig) <> mrOk then Exit;
  Remove; // ! uses old Config values
  Config := tmpConfig;
  Fill;
  SaveSettings;
end;

procedure TFavsWizard.MenuItemOpenItemClick(Sender: TObject);
begin
  ActionSrv.OpenProject(FFavList[TMenuItem(Sender).Tag], True);
end;

// Init menu items
procedure TFavsWizard.PopupMenuPopup(Sender: TObject);
var
  mi: TMenuItem;
  PrPath, PrGrPath: string;
  CurPrIdx, CurPrGrIdx: Integer;
begin
  if ModuleSrv.GetActiveProject <> nil
    then PrPath := ModuleSrv.GetActiveProject.FileName
    else PrPath := '';
  if ModuleSrv.MainProjectGroup <> nil
    then PrGrPath := ModuleSrv.MainProjectGroup.FileName
    else PrGrPath := '';
  CurPrIdx := FFavList.IndexOf(PrPath);
  CurPrGrIdx := FFavList.IndexOf(PrGrPath);

  // Mark the fav items correspondent to current project/project group
  for mi in GetCurrMenu do
    if mi.Tag >= 0 then
      mi.Checked := (mi.Tag = CurPrIdx) or (mi.Tag = CurPrGrIdx);

  // Change "Add project/project group" items' captions to include project/project group names
  // Set enabled state of these items if there's no project/group opened
  FConstSubMenuItems[actAddProj].Enabled := (PrPath <> '') and (CurPrIdx = -1);
  if PrPath = '' then
    FConstSubMenuItems[actAddProj].Caption := SMenuAddProjectEmpty
  else if CurPrIdx <> -1 then
    FConstSubMenuItems[actAddProj].Caption := Format(SMenuAddProjectAlready, [ChangeFileExt(ExtractFileName(PrPath), '')])
  else
    FConstSubMenuItems[actAddProj].Caption := Format(SMenuAddProjectPatt, [ChangeFileExt(ExtractFileName(PrPath), '')]);

  FConstSubMenuItems[actAddProjGroup].Enabled := (PrGrPath <> '') and (CurPrGrIdx = -1);;
  if PrGrPath = '' then
    FConstSubMenuItems[actAddProjGroup].Caption := SMenuAddProjGroupEmpty
  else if CurPrGrIdx <> -1 then
    FConstSubMenuItems[actAddProjGroup].Caption := Format(SMenuAddProjGroupAlready, [ChangeFileExt(ExtractFileName(PrGrPath), '')])
  else
    FConstSubMenuItems[actAddProjGroup].Caption := Format(SMenuAddProjGroupPatt, [ChangeFileExt(ExtractFileName(PrGrPath), '')]);
end;

{$ENDREGION}

var
  tb: TIDEToolbar;

initialization
  WizFavs.BaseWiz.SWizardName := SWizardName;
  WizFavs.BaseWiz.SWizardID := SWizardID;
  WizFavs.BaseWiz.CreateInstFunc := CreateInstFunc;
  for tb := Low(TIDEToolbar) to High(TIDEToolbar) do
    SToolbarLabels[tb] := ReplaceText(SToolbarNames[tb], 'Toolbar', '');

end.