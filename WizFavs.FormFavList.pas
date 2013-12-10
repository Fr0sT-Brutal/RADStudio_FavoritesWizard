//* Favs expert/wizard for RAD studio *\\
//*         List editor form          *\\
//*             © Fr0sT               *\\

unit WizFavs.FormFavList;

interface

uses
  Windows, Graphics, Controls, Forms, StdCtrls, SysUtils, Classes, ExtCtrls;

type
  TfrmFavsManager = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    lbFavsList: TListBox;
    btnRemoveInvalid: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    procedure btnRemoveInvalidClick(Sender: TObject);
    procedure lbFavsListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure lbFavsListDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure lbFavsListKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

function Execute(FavList: TStringList): TModalResult;

implementation

{$R *.dfm}

function Execute(FavList: TStringList): TModalResult;
begin
  with TfrmFavsManager.Create(Application) do
  begin
    lbFavsList.Items.Assign(FavList);

    Result := ShowModal;

    if Result = mrOk then
      FavList.Assign(lbFavsList.Items);
    Free;
  end;
end;

// delete items corresponding to not-existing files
procedure TfrmFavsManager.btnRemoveInvalidClick(Sender: TObject);
var i: Integer;
begin
  for i := lbFavsList.Count - 1 downto 0 do
    if not FileExists(lbFavsList.Items[i]) then
      lbFavsList.Items.Delete(i);
end;

var
  DraggedItem: Integer = -1;

procedure TfrmFavsManager.lbFavsListDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
var idx: Integer;
begin
  Accept := False;
  if Sender <> Source then Exit;

  case State of
    // started dragging - save the index of the item being dragged
    dsDragEnter:
      begin
        DraggedItem := TListBox(Sender).ItemAtPos(Point(X, Y), True);
        if DraggedItem = -1 then Exit;
      end;
    // dragging in progress - swap the dragged item with the item it is dragged over
    dsDragMove:
      begin
        if DraggedItem = -1 then Exit;
        idx := TListBox(Sender).ItemAtPos(Point(X, Y), True);
        if idx = -1 then Exit;
        TListBox(Sender).Items.Exchange(DraggedItem, idx);
        DraggedItem := idx;
      end;
    // dragging finished - clear the DraggedItem
    dsDragLeave:
      begin
        DraggedItem := -1;
      end;
  end;
  Accept := True;
end;

// draw the item grayed if corresponding file not exists
procedure TfrmFavsManager.lbFavsListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var color: TColor;
    exist: Boolean;
    item: string;
    canv: TCanvas;
begin
  canv := TListBox(Control).Canvas;

  // draw background
  if odSelected in State then
    color := clHighlight
  else
    color := clWindow;
  canv.Brush.Color := color;
  canv.FillRect(rect);

  // draw foreground text, grayed if file not exists
  item := TListBox(Control).Items[Index];
  exist := FileExists(item);
  if exist or (odSelected in State) then
    color := clWindowText
  else
    color := clGrayText;
  canv.Font.Color := color;
  canv.TextRect(Rect, item);
end;

// Remove focused item on Del
procedure TfrmFavsManager.lbFavsListKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var itemIdx: Integer;
begin
  if (Shift = []) and (Key = VK_DELETE) then
  begin
    itemIdx := TListBox(Sender).ItemIndex;
    if itemIdx = -1 then Exit;
    TListBox(Sender).Items.Delete(itemIdx);
    if itemIdx >= TListBox(Sender).Items.Count then
      itemIdx := TListBox(Sender).Items.Count - 1;
    TListBox(Sender).ItemIndex := itemIdx;
  end;
end;

end.
