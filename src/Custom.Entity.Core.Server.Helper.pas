unit Custom.Entity.Core.Server.Helper;

interface

uses System.Rtti, Custom.Entity.Core.Attributes, System.Variants, REST.Json, System.JSON,
  System.Generics.Collections, System.TypInfo, System.StrUtils, Custom.Entity.Core.Types,
  System.SysUtils, System.Generics.Defaults, Data.DB;

type
  THelperTRttiProperty = class helper for TRttiProperty
  public
    function IsPrimaryKey: Boolean;
    function IsUniqueKey: Boolean;
    function IsForeingKey: Boolean;
    function IsNotNull: Boolean;
    function IsAutoIncrement: Boolean;
    function IsIdentity: Boolean;
    function IsNull(const AObject: TObject): Boolean;
    function IsEnum: Boolean;
    function IsReadOnly: Boolean;
    function IsClass: Boolean;
    function IsIgnore: Boolean;
    function IsNullable: Boolean;
    function HasForeignKey: Boolean;
    function ToPair(const AObject: TObject): TJSONPair;
    function ToJSON(const AObject: TObject): TJSONValue;
    function GetParameterEndpoint: String;
    function TypeKindName(const AObject: TObject): String;
    function TypeInfo(const AObject: TObject): PTypeInfo;
    function Value(const AObject: TObject): TValue;

    procedure FromJSON(const AObject: TObject; const AJSONValue: TJSONValue);
  end;

  THelperTArrayProperties = record helper for TArrayProperties
  public
    function ToString: String;
  end;

  THelperTArrayTValue = record helper for TArrayValue
  public
    function Field(const AFieldName: String): TValue;
  end;

  THelperTParam = class helper for TParam
  public
    procedure SetNameValue(const AName: String; const AValue: Variant);
  end;
implementation

uses Custom.Entity.Core.Mapper;

{ THelperTRttiProperty }

function THelperTRttiProperty.HasForeignKey: Boolean;
begin
  Result := HasAttribute<ForeignKey>;
end;

function THelperTRttiProperty.IsAutoIncrement: Boolean;
begin
  Result := HasAttribute<AutoIncremental>;
end;

function THelperTRttiProperty.IsClass: Boolean;
begin
  Result := Self.PropertyType.TypeKind = TTypeKind.tkClass;
end;

function THelperTRttiProperty.IsEnum: Boolean;
begin
  Result := HasAttribute<Custom.Entity.Core.Attributes.IsEnum> or (Self.PropertyType.Handle.Kind = tkEnumeration);
end;

function THelperTRttiProperty.IsForeingKey: Boolean;
begin
  Result := HasAttribute<ForeignKey>;
end;

function THelperTRttiProperty.IsIdentity: Boolean;
begin
  Result := HasAttribute<Identity>;
end;

function THelperTRttiProperty.IsIgnore: Boolean;
begin
  Result := HasAttribute<Ignore>;
end;

function THelperTRttiProperty.IsNotNull: Boolean;
begin
  Result := HasAttribute<NotNull>;
end;

function THelperTRttiProperty.IsNull(const AObject: TObject): Boolean;
begin
  var LMethod := PropertyType.GetMethod('IsNull');

  if LMethod <> nil then
  begin
    Result := LMethod.Invoke(GetValue(AObject), []).AsBoolean;
  end
  else
  begin
    Result := VarIsNull(GetValue(AObject).AsVariant);
  end;

end;

function THelperTRttiProperty.IsNullable: Boolean;
begin
  Result := Self.PropertyType.Name.ToLower.Contains('nullable<');
end;

function THelperTRttiProperty.IsPrimaryKey: Boolean;
begin
  Result := HasAttribute<PrimaryKey>;
end;

function THelperTRttiProperty.IsReadOnly: Boolean;
begin
  Result := HasAttribute<ReadOnly> or not Self.IsWritable;
end;

function THelperTRttiProperty.IsUniqueKey: Boolean;
begin
  Result := HasAttribute<UniqueKey>;
end;

function THelperTRttiProperty.ToPair(const AObject: TObject): TJsonPair;
begin
  Result := TJSONPair.Create(Name, ToJSON(AObject));
end;

function THelperTRttiProperty.TypeInfo(const AObject: TObject): PTypeInfo;
begin
  var LMethod   := PropertyType.GetMethod('GetDataType');

  Result := PropertyType.Handle;

  if LMethod <> nil then
  begin
    Result := LMethod
                  .Invoke(AObject, [])
                  .AsType<PTypeInfo>;
  end;
end;

function THelperTRttiProperty.TypeKindName(const AObject: TObject): String;
begin
  var LMethod   := PropertyType.GetMethod('GetDataType');
  var LTypeInfo := PropertyType.Handle;

  if LMethod <> nil then
  begin
    LTypeInfo := LMethod
                    .Invoke(GetValue(AObject), [])
                    .AsType<PTypeInfo>;
  end;

  Result := String(LTypeInfo.Name).Replace('tk', '');
end;

function THelperTRttiProperty.Value(const AObject: TObject): TValue;
begin
  var LField := PropertyType.GetMethod('GetValue');

  if LField <> nil then
  begin
    Result := LField.Invoke(GetValue(AObject), []);
  end;
end;

function THelperTRttiProperty.ToJSON(const AObject: TObject): TJsonValue;
begin
  Result := nil;

  var LMethod := PropertyType.GetMethod('ToJSON');

  if (LMethod <> nil) then
  begin
    var LFormatDateTime := '';
    var LFormatField    := GetAttribute<FormatValue>;

    if LFormatField <> nil then
    begin
      LFormatDateTime := LFormatField.Value.AsString;
    end;

    Result := LMethod
                 .Invoke(GetValue(AObject), [LFormatDateTime])
                 .AsType<TJSONValue>;
  end;
end;

procedure THelperTRttiProperty.FromJSON(const AObject: TObject; const AJSONValue: TJSONValue);
var
  LValue: TValue;
begin
  var LMethod := PropertyType.GetMethod('FromJSON');

  if LMethod <> nil then
  begin
    LValue := LMethod.Invoke(GetValue(AObject),
                             [AJSONValue]);

    SetValue(AObject, LValue);
  end
  else if Self.IsEnum then
  begin
    TValue.Make(GetEnumValue(PropertyType.Handle, AJSONValue.Value), Self.PropertyType.Handle, LValue);
    SetValue(AObject, LValue);
  end;
end;

function THelperTRttiProperty.GetParameterEndpoint: String;
begin
  Result := Format('{%s}', [Self.Name]);
end;

{ ThelperTArrayProperties }

function ThelperTArrayProperties.ToString: String;
begin
  for var LProperty in Self do
  begin
    Result := Result + LProperty.Name + ',';
  end;

  Result := Result.Remove(Result.LastIndexOf(','));
end;

{ THelperTArrayTValue }

function THelperTArrayTValue.Field(const AFieldName: String): TValue;
begin
  for var LValue in Self do
  begin
    if LValue.AsString.ToLower.Contains(AFieldName.ToLower) then
    begin
      Exit(LValue);
    end;
  end;
end;

{ THelperTParam }

procedure THelperTParam.SetNameValue(const AName: String; const AValue: Variant);
begin
  Self.Name  := AName;
  Self.Value := AValue;
end;

end.
