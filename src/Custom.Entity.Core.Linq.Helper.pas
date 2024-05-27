unit Custom.Entity.Core.Linq.Helper;

interface

{
  TDataSet helper classes to simplify access to TDataSet fields and make TDataSet
  work with a for-in-loop.

  Author: Uwe Raabe - ur@ipteam.de

  Techniques used:
  - class helpers
  - enumerators
  - invokable custom variants

  This unit implements some "Delphi Magic" to simplify the use of TDataSets and
  its fields. Just by USING this unit you can access the individual fields of a
  TDataSet like they were properties of a class. For example let's say a DataSet
  has fields First_Name and Last_Name. The normal approach to access the field
  value would be to write something like this:

  DataSet.FieldValues['First_Name']

  or

  DataSet.FieldByName('First_Name'].Value

  With this unit you can simply write

  DataSet.CurrentRec.First_Name

  You can even assign DataSet.CurrentRec to a local variable of type variant to
  shorten the needed typing and clarify the meaning (let PersonDataSet be a
  TDataSet descendant with fields as stated above).

  var
  Person: Variant;
  FullName: string;
  begin
  Person := PersonDataSet.CurrentRec;
  ...
  FullName := Trim(Format('%s %s', [Person.First_Name, Person.Last_Name]));
  ...
  end;

  If you write to such a property, the underlying DatsSet is automatically set
  into Edit mode.

  Obviously you still have to know the field names of the dataset, but this is
  just the same as if you are using FieldByName.

  The second benefit of this unit shows up when you try to iterate over a
  DataSet. This reduces to simply write the following (let Lines be a TStrings
  decendant taking the full names of all persons):

  var
  Person: Variant;
  begin
  ...
  // Active state of PersonDataSet is saved during the for loop.
  // If PersonDataSet supports bookmarks, the position is also saved.
  for Person in PersonDataSet do begin
  Lines.Add(Trim(Format('%s %s', [Person.First_Name, Person.Last_Name])));
  end;
  ...
  end;

  You can even set these "variant-field-properties" during the for loop as the
  DataSet will automatically Post your changes within the Next method.

  How it works:
  We use a class helper to add the CurrentRec property and the enumerator to the
  TDataSet class. The CurrentRec property is also used by the enumerator to
  return the current record when iterating. The TDataSetEnumerator does some
  housekeeping to restore the active state and position of the DataSet after
  the iteration, thus your code hasn't to do this each time.

  The tricky thing is making the variant to access the dataset fields as if they
  were properties. This is accomplished by introducing a custom variant type
  descending from TInvokeableVariantType. Besides the obligatory overwriting of
  Clear and Copy, which turn out to be quite simple, we implement the GetProperty
  and SetProperty methods to map the property names to field names. That's all!

  CAUTION! Don't do stupid things with the DataSet while there is some of these
  variants connected to it. Especially don't destroy it!

  The variant stuff is completely hidden in the implementation section, as for
  now I can see no need to expose it.
}

uses
  Data.DB, Winapi.Windows, System.Generics.Collections, System.Rtti,
  Custom.Entity.Core.Types;

type
  TDataSetEnumerator = class
  private
    FBookmark   : TBookmark;
    FDataSet    : TDataSet;
    FMoveToFirst: Boolean;
    FWasActive  : Boolean;
    function GetCurrent: Variant;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function MoveNext: Boolean;
    property Current: Variant read GetCurrent;
  end;

type
  TDataSetHelper = class Helper for TDataSet
  private
    function GetCurrentRec: Variant;
  public
    function GetEnumerator: TDataSetEnumerator;
    property CurrentRec: Variant read GetCurrentRec;
  end;

  TFieldTypeHelper = class Helper for TField
  public
    function ToValue: TValue;
  end;

implementation

uses
  System.Sysutils, System.Variants;

type
  { A custom variant type that implements the mapping from the property names
    to the DataSet fields. }
  TVarDataRecordType = class(TInvokeableVariantType)
  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    function GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean; override;
    function SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean; override;
  end;

type
  { Our layout of the variants record data.
    We only hold a pointer to the DataSet. }
  TVarDataRecordData = record helper for TVarData
  private
    class var FDataSet: TDataSet;
    class var FReserved4: LongInt;
  public
    class property DataSet: TDataSet read FDataSet write FDataSet;
    class property Reserved4: LongInt  read FReserved4;
  end;


var
  { The global instance of the custom variant type. The data of the custom
    variant is stored in a TVarData record, but the methods and properties
    are implemented in this class instance. }
  VarDataRecordType: TVarDataRecordType = nil;

  { A global function the get our custom VarType value. This may vary and thus
    is determined at runtime. }
function VarDataRecord: TVarType;
begin
  Result := VarDataRecordType.VarType;
end;

{ A global function that fills the VarData fields with the correct values. }
function VarDataRecordCreate(ADataSet: TDataSet): Variant;
begin
  VarClear(Result);
  TVarData(Result).VType   := VarDataRecord;
  TVarData(Result).DataSet := ADataSet;
end;

procedure TVarDataRecordType.Clear(var V: TVarData);
begin
  { No fancy things to do here, we are only holding a pointer to a TDataSet and
    we are not supposed to destroy it here. }
  SimplisticClear(V);
end;

procedure TVarDataRecordType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  { No fancy things to do here, we are only holding a pointer to a TDataSet and
    that can simply be copied here. }
  SimplisticCopy(Dest, Source, Indirect);
end;

function TVarDataRecordType.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
begin
  { Find a field with the property's name. If there is one, return its current value. }
  var
  LField := TVarData(V).DataSet.FindField(Name);
  Result := (LField <> nil);
  if Result then
    Variant(Dest) := LField.Value;
end;

function TVarDataRecordType.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
var
  fld: TField;
begin
  { Find a field with the property's name. If there is one, set its value. }
  fld    := TVarData(V).DataSet.FindField(Name);
  Result := (fld <> nil);
  if Result then
  begin
    { Well, we have to be in Edit mode to do this, don't we? }
    TVarData(V).DataSet.Edit;
    fld.Value := Variant(Value);
  end;
end;

constructor TDataSetEnumerator.Create(ADataSet: TDataSet);
{ The enumerator is automatically created and destroyed in the for-in loop.
  So we remember the active state and set a flag that the first MoveNext will
  not move to the next record, but stays on the first one instead. }
begin
  inherited Create;
  FDataSet := ADataSet;
  Assert(FDataSet <> nil);
  { save the Active state }
  FWasActive := FDataSet.Active;
  { avoid flickering }
  FDataSet.DisableControls;
  if FWasActive then
  begin
    { get a bookmark of the current position - even if it is invalid }
    FBookmark := FDataSet.GetBookmark;
    FDataSet.First;
  end
  else
  begin
    { FBookmark is initialized to nil anyway, so no need to set it here }
    FDataSet.Active := true;
  end;
  FMoveToFirst := true;
end;

destructor TDataSetEnumerator.Destroy;
{ Restore the DataSet to its previous state. }
begin
  if FWasActive then
  begin
    { if we have a valid bookmark, use it }
    if FDataSet.BookmarkValid(FBookmark) then
      FDataSet.GotoBookmark(FBookmark);
    { I'm not sure, if FreeBokmark can handle nil pointers - so to be safe }
    if FBookmark <> nil then
      FDataSet.FreeBookmark(FBookmark);
  end
  else
    FDataSet.Active := false;
  { don't forget this one! }
  FDataSet.EnableControls;
  inherited;
end;

function TDataSetEnumerator.GetCurrent: Variant;
begin
  { We simply return the CurrentRec property of the DataSet, which is exposed
    due to the class helper. }
  Result := FDataSet.CurrentRec;
end;

function TDataSetEnumerator.MoveNext: Boolean;
begin
  { Check if we have to move to the first record, which has been done already
    during Create. }
  if FMoveToFirst then
    FMoveToFirst := false
  else
    FDataSet.Next;
  Result := not FDataSet.EoF;
end;

function TDataSetHelper.GetCurrentRec: Variant;
begin
  { return one of our custom variants }
  Result := VarDataRecordCreate(Self);
end;

function TDataSetHelper.GetEnumerator: TDataSetEnumerator;
begin
  { return a new enumerator }
  Result := TDataSetEnumerator.Create(Self);
end;

{ TFieldTypeHelper }

function TFieldTypeHelper.ToValue: TValue;
begin
  case Self.DataType of
    ftUnknown:
      ;
    ftString:
      begin
        Result := TValue.From < Nullable < String >> (Self.AsString);
      end;
    ftSmallint:
      begin
        Result := TValue.From < Nullable < SmallInt >> (Self.AsInteger);
      end;
    ftInteger:
      begin
        Result := TValue.From < Nullable < Integer >> (Self.AsInteger);
      end;
    ftDate:
      begin
        Result := TValue.From<Nullable<TDate>>(Self.AsDateTime);
      end;
    ftWord:
      ;
    ftBoolean:
      ;
    ftFloat:
      ;
    ftCurrency:
      ;
    ftBCD:
      ;
    ftTime:
      begin
        Result := TValue.From<Nullable<TTime>>(Self.AsDateTime);
      end;
    ftDateTime, ftTimeStamp, ftTimeStampOffset:
      begin
        Result := TValue.From<Nullable<TDateTime>>(Self.AsDateTime);
      end;
    ftBytes, ftBlob:
      begin
        Result := TValue.From<Nullable<TBytes>>(Self.AsBytes);
      end;
    ftVarBytes:
      ;
    ftAutoInc:
      ;
    ftMemo:
      ;
    ftGraphic:
      ;
    ftFmtMemo:
      ;
    ftParadoxOle:
      ;
    ftDBaseOle:
      ;
    ftTypedBinary:
      ;
    ftCursor:
      ;
    ftFixedChar:
      ;
    ftWideString:
      ;
    ftLargeint:
      ;
    ftADT:
      ;
    ftArray:
      ;
    ftReference:
      ;
    ftDataSet:
      ;
    ftOraBlob:
      ;
    ftOraClob:
      ;
    ftVariant:
      ;
    ftInterface:
      ;
    ftIDispatch:
      ;
    ftGuid:
      ;
    ftFMTBcd:
      ;
    ftFixedWideChar:
      ;
    ftWideMemo:
      ;
    ftOraTimeStamp:
      ;
    ftOraInterval:
      ;
    ftLongWord:
      ;
    ftShortint:
      ;
    ftByte:
      ;
    ftExtended:
      ;
    ftConnection:
      ;
    ftParams:
      ;
    ftStream:
      ;
    ftObject:
      ;
    ftSingle:
      ;
  end;
end;

initialization

{ Create our custom variant type, which will be registered automatically. }
VarDataRecordType := TVarDataRecordType.Create;

finalization

{ Free our custom variant type. }
FreeAndNil(VarDataRecordType);

end.

