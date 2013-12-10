object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Settings'
  ClientHeight = 276
  ClientWidth = 329
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
  OnClose = FormClose
  OnShow = FormShow
  DesignSize = (
    329
    276)
  PixelsPerInch = 120
  TextHeight = 16
  object panToolbar: TPanel
    Left = 125
    Top = 13
    Width = 196
    Height = 218
    Anchors = [akLeft, akTop, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 3
    Visible = False
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 107
      Height = 16
      Caption = 'Destination toolbar'
    end
    object Label2: TLabel
      Left = 8
      Top = 64
      Width = 70
      Height = 16
      Caption = 'Button index'
    end
    object cbDestToolbar: TComboBox
      Left = 8
      Top = 24
      Width = 177
      Height = 24
      Style = csDropDownList
      TabOrder = 0
    end
    object udBtnIndex: TUpDown
      Left = 113
      Top = 80
      Width = 20
      Height = 24
      Associate = eBtnIndex
      TabOrder = 1
    end
    object eBtnIndex: TEdit
      Left = 8
      Top = 80
      Width = 105
      Height = 24
      NumbersOnly = True
      ReadOnly = True
      TabOrder = 2
      Text = '0'
    end
  end
  object panMainMenu: TPanel
    Left = 125
    Top = 13
    Width = 196
    Height = 218
    Anchors = [akLeft, akTop, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 4
    Visible = False
    object Label3: TLabel
      Left = 8
      Top = 8
      Width = 64
      Height = 16
      Caption = 'Insert after'
    end
    object cbMainMenuInsertAfter: TComboBox
      Left = 8
      Top = 24
      Width = 177
      Height = 24
      Style = csDropDownList
      TabOrder = 0
    end
  end
  object panSubMenu: TPanel
    Left = 125
    Top = 13
    Width = 196
    Height = 218
    Anchors = [akLeft, akTop, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 5
    Visible = False
    object Label4: TLabel
      Left = 8
      Top = 8
      Width = 58
      Height = 16
      Caption = 'Insert into'
    end
    object submenu: TLabel
      Left = 8
      Top = 56
      Width = 64
      Height = 16
      Caption = 'Insert after'
    end
    object Label5: TLabel
      Left = 8
      Top = 104
      Width = 180
      Height = 21
      Caption = 'Under construction...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -17
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cbSubMenuInsertInto: TComboBox
      Left = 8
      Top = 24
      Width = 177
      Height = 24
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbSubMenuInsertIntoChange
    end
    object cbSubMenuInsertAfter: TComboBox
      Left = 8
      Top = 72
      Width = 177
      Height = 24
      Style = csDropDownList
      TabOrder = 1
    end
  end
  object btnOk: TButton
    Left = 167
    Top = 236
    Width = 75
    Height = 33
    Anchors = [akRight, akBottom]
    Caption = 'Ok'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 245
    Top = 236
    Width = 75
    Height = 33
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object rgPlacement: TRadioGroup
    Left = 5
    Top = 5
    Width = 116
    Height = 100
    Caption = ' Placement '
    Items.Strings = (
      'Toolbar'
      'Main menu'
      'Submenu')
    TabOrder = 2
    OnClick = rgPlacementClick
  end
end
