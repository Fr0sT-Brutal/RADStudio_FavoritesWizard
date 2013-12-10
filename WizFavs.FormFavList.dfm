object frmFavsManager: TfrmFavsManager
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Favorites list manager'
  ClientHeight = 284
  ClientWidth = 354
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  Padding.Left = 5
  Padding.Top = 5
  Padding.Right = 5
  Padding.Bottom = 5
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 120
  TextHeight = 16
  object lbFavsList: TListBox
    Left = 5
    Top = 46
    Width = 344
    Height = 188
    Style = lbOwnerDrawFixed
    Align = alClient
    DragMode = dmAutomatic
    TabOrder = 0
    OnDragOver = lbFavsListDragOver
    OnDrawItem = lbFavsListDrawItem
    OnKeyUp = lbFavsListKeyUp
  end
  object Panel1: TPanel
    Left = 5
    Top = 234
    Width = 344
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      344
      45)
    object btnRemoveInvalid: TButton
      Left = 0
      Top = 8
      Width = 113
      Height = 33
      Caption = 'Remove invalid'
      TabOrder = 0
      OnClick = btnRemoveInvalidClick
    end
    object btnOk: TButton
      Left = 192
      Top = 8
      Width = 75
      Height = 33
      Anchors = [akRight, akBottom]
      Caption = 'Ok'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
    object btnCancel: TButton
      Left = 270
      Top = 8
      Width = 75
      Height = 33
      Anchors = [akRight, akBottom]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 2
    end
  end
  object Panel2: TPanel
    Left = 5
    Top = 5
    Width = 344
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 310
      Height = 32
      Align = alClient
      Caption = 
        'Drag-and-drop item to change the order, press Del to remove focu' +
        'sed item'
      Layout = tlCenter
      WordWrap = True
    end
  end
end
