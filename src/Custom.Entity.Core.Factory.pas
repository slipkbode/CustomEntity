unit Custom.Entity.Core.Factory;

interface

uses Custom.Entity.Core.Model,
     Custom.Entity.Core.Connection,
     Data.DB,
     Custom.Entity.Core.Attributes,
     System.SysUtils,
     System.Rtti,
     System.TypInfo,
     System.Generics.Collections;

type
  TEntityCoreFactory = class
  public
    type
      TRecordScript = packed record
      private
        FParams: TParams;
        function GetParams: TParams;
      public
        Insert         : String;
        Update         : String;
        ArrayParams    : TArray<Variant>;
        property Params: TParams read GetParams;
      end;
  strict private
    class var FTableName: String;
  private
    class function GetScriptTable(const AClass: TEntityCoreModelClass): String; static;
    class function GetScriptField(const ATableName: String; const AProperty: TRttiProperty): String; static;
    class function GetTableField(const AClass: TEntityCoreModelClass): String;
    class function GetIsNotNull(const AProperty: TRttiProperty): String; static;
    class function GetIndentity(const AProperty: TRttiProperty): String; static;
    class function GetFieldType(const AProperty: TRttiProperty; ATypeKind: TTypeKind = tkUnknown): String; static;
    class function GetTypeKindName(const AProperty: TRttiProperty): String; static;
    class function GetTypeInteger: String; static;
    class function GetTypeBoolean: String; static;
    class function GetTypeSmallInt: String; static;
    class function GetConnection: IEntityCoreConnection; static;
    class function GetPrimaryKeys(const AClass: TEntityCoreModelClass): String;
  public
    class procedure CreateTable(const AClass: TEntityCoreModelClass);
    class procedure CreateDatabase(const ADatabaseName: String);
    class procedure CreateUniqueKey(const AClass: TEntityCoreModelClass);

    class function RecordInsert(const AModel: TEntityCoreModel): TRecordScript; overload;
    class function RecordInsert(const AModel: TEntityCoreModelClass): String; overload;
    class function RecordUpdate(const AModel: TEntityCoreModel): TRecordScript;

    class property Connection: IEntityCoreConnection read GetConnection;
  end;

implementation

uses
  Custom.Entity.Core.Mapper,
  Custom.Entity.Core.Server.Helper,
  Custom.Entity.Core.Constant,
  Custom.Entity.Core;

{ TEntityCoreFactory }

class procedure TEntityCoreFactory.CreateDatabase(const ADatabaseName: String);
begin
  if not Connection.DatabaseExists(ADatabaseName) then
  begin
    try
      Connection.ExecSQL(Format(TEntityCoreConstant.cCreateDatabase,
                                [ADatabaseName]));
    except
      Connection.Close;
      raise;
    end;
  end;
end;

class procedure TEntityCoreFactory.CreateTable(const AClass: TEntityCoreModelClass);
begin
  try
    var LTableName := TEntityCoreMapper.GetTableName(AClass);

    if not Connection.TableExists(LTableName) then
    begin
      Connection.ExecSQL(GetScriptTable(AClass));
    end
    else
    begin
      var LProperties := TEntityCoreMapper.GetProperties(AClass);

      for var LProperty in LProperties do
      begin
        if not Connection.FieldExists(LTableName, LProperty.Name) then
        begin
          Connection.ExecSQL(GetScriptField(LTableName, LProperty));
        end;
      end;
    end;

    CreateUniqueKey(AClass);
  except
    Connection.Close;
    raise;
  end
end;

class procedure TEntityCoreFactory.CreateUniqueKey(const AClass: TEntityCoreModelClass);
begin
  var LUniqueKeyList := TEntityCoreMapper.GetUniqueKeys(AClass);
  var LTableName     := TEntityCoreMapper.GetTableName(AClass);
  var LScript        := '';

  for var LUniqueKey in LUniqueKeyList do
  begin
    var LFields := Connection.UniqueKeyExists(LTableName, LUniqueKey.Key);

    if not LFields.Trim.IsEmpty and not LFields.Equals(LUniqueKey.Value) then
    begin
      if not Connection.IsMySQL then
      begin
        LScript := Format(TEntityCoreConstant.cDropUniqueKey,
                          [LTableName,
                           LUniqueKey.Key]);
      end
      else
      begin
        LScript := Format(TEntityCoreConstant.cDropUniqueKeyMySQL,
                          [LTableName,
                           LUniqueKey.Key]);
      end;
    end;

    if LFields.Trim.IsEmpty or LScript.Contains('drop') then
    begin
      LScript := LScript +
                 #13 +
                 Format(TEntityCoreConstant.cCreateUniqueKey,
                        [LTableName,
                         LUniqueKey.Key,
                         LUniqueKey.Value]);
    end;

    Connection.ExecSQL(LScript);
  end;
end;

class function TEntityCoreFactory.GetScriptField(const ATableName: String; const AProperty: TRttiProperty): String;
begin
  Result := Format(TEntityCoreConstant.cCreateField,
                   [ATableName,
                   AProperty.Name,
                   GetFieldType(AProperty),
                   GetIsNotNull(AProperty)]);
end;

class function TEntityCoreFactory.GetScriptTable(const AClass: TEntityCoreModelClass): String;
begin
  FTableName := TEntityCoreMapper.GetTableName(AClass);
  Result     := Format(TEntityCoreConstant.cCreateTable,
                       [FTableName,
                        GetTableField(AClass) +
                        GetPrimaryKeys(AClass)]);
end;

class function TEntityCoreFactory.GetTableField(const AClass: TEntityCoreModelClass): String;
begin
  var LProperties := TEntityCoreMapper.GetProperties(AClass);

  for var LProperty in LProperties do
  begin
    Result := Concat(Result,
                     ',',
                     LProperty.Name,
                     GetFieldType(LProperty),
                     GetIsNotNull(LProperty),
                     GetIndentity(LProperty));
  end;

  Result := Result.Remove(0, 1);
end;

class function TEntityCoreFactory.GetIndentity(const AProperty: TRttiProperty): String;
begin
  Result := String.Empty;

  if AProperty.IsIdentity then
  begin
    if Connection.IsSQLite then
    begin
      Result := ' autoincrement ';
    end
    else if Connection.IsSQLServer then
    begin
      Result := ' identity(1, 1) ';
    end;
  end;
end;

class function TEntityCoreFactory.GetIsNotNull(const AProperty: TRttiProperty): String;
begin
  Result := String.Empty;

  if AProperty.IsNotNull or AProperty.IsPrimaryKey then
  begin
    Result := ' not null ';
  end;
end;

class function TEntityCoreFactory.GetPrimaryKeys(const AClass: TEntityCoreModelClass): String;
begin
  var LPrimaryKeys := TEntityCoreMapper.GetPrimaryKeys(AClass);

  if Length(LPrimaryKeys) > 0 then
  begin
    Result := Concat(',',
                    Format(TEntityCoreConstant.cConstraintPrymaryKey,
                          [TEntityCoreMapper.GetTableName(AClass),
                           LPrimaryKeys.ToString]
                           )
                    );
  end;
end;

class function TEntityCoreFactory.GetConnection: IEntityCoreConnection;
begin
  Result := TEntity.Connection;
end;

class function TEntityCoreFactory.GetFieldType(const AProperty: TRttiProperty; ATypeKind: TTypeKind = tkUnknown): String;
begin
  Result := String.Empty;

  if ATypeKind = tkUnknown then
  begin
    ATypeKind := AProperty.PropertyType.TypeKind;
  end;

  case ATypeKind of
    tkInteger:
      begin
        Result := GetTypeInteger;
      end;
    tkChar: ;
    tkEnumeration:
      begin
        Result := GetTypeSmallInt;
      end;
    tkFloat: ;
    tkString, tkUString:
      begin
        const cVarchar = ' varchar(%d) ';
        var LStringSize := AProperty.GetAttribute<StringSize>;

        Result := Format(cVarchar, [200]);
        if LStringSize <> nil then
        begin
          Result := Format(cVarchar, [LStringSize.MaxLength]);
        end;
      end;
    tkSet: ;
    tkClass: ;
    tkMethod: ;
    tkWChar: ;
    tkLString: ;
    tkWString: ;
    tkVariant: ;
    tkArray: ;
    tkInterface: ;
    tkInt64: ;
    tkDynArray: ;
    tkClassRef: ;
    tkPointer: ;
    tkMRecord, tkRecord:
      begin
        Result := GetFieldType(AProperty,
                               TTypeKind(GetEnumValue(TypeInfo(TTypeKind),
                                                      GetTypeKindName(AProperty))
                                         )
                               )
      end;
    else
      begin
        Result := GetTypeBoolean;
      end;
  end;
end;

class function TEntityCoreFactory.GetTypeBoolean: String;
begin
  if Connection.IsSQLite then
  begin
    Result := ' integer ';
  end
  else if Connection.IsFirebird then
  begin
    Result := ' boolean ';
  end
  else if Connection.IsSQLServer then
  begin
    Result := ' bit ';
  end;
end;

class function TEntityCoreFactory.GetTypeKindName(const AProperty: TRttiProperty): String;
begin
  Result := Concat('tk',
                     AProperty
                          .PropertyType
                          .Name
                          .ToLower
                          .Replace('nullable<system.', '')
                          .Replace('>', '')
                          .Trim);

  if (AProperty.IsEnum) or Result.Equals('smallint') then
  begin
    Result := 'tkEnumeration';
  end;
end;

class function TEntityCoreFactory.GetTypeSmallInt: String;
begin
  Result := ' smallint ';

  if Connection.IsSQLite then
  begin
    Result := ' integer ';
  end;
end;

class function TEntityCoreFactory.RecordInsert(const AModel: TEntityCoreModel): TRecordScript;
begin
  var LTypeInfo: TValue;
  var LParam   : TParam;

  var LProperties   := TEntityCoreMapper.GetProperties(AModel.ClassType);
  var LFields       := String.Empty;
  var LTableName    := TEntityCoreMapper.GetTableName(AModel.ClassType);
  var LPrimaryKey   := String.Empty;

  for var LProperty in LProperties do
  begin
    if LProperty.IsPrimaryKey then
    begin
      LPrimaryKey := LProperty.Name;
    end;

    if LProperty.IsIdentity or LProperty.IsNull(AModel) then
    begin
      LParam := Result
                   .Params
                   .AddParameter;

      LParam.Name := LProperty.Name;
      Continue;
    end;

    LFields := Concat(LFields,
                      LProperty.Name,
                      ',');

    LTypeInfo := LProperty.GetValue(AModel);

    LParam := Result
                 .Params
                 .AddParameter;

    LParam.Name  := LProperty.Name;
    LParam.Value := LProperty
                         .Value(AModel)
                         .AsVariant;
  end;

  LFields := LFields.Remove(LFields.LastIndexOf(','));

  Result.Insert := Format(TEntityCoreConstant.cInsert,
                          [LTableName,
                           LFields,
                           ':' + LFields.Replace(',', ',:'),
                           LPrimaryKey,
                           LPrimaryKey]);
end;


class function TEntityCoreFactory.RecordInsert(const AModel: TEntityCoreModelClass): String;
begin
  var LTableName    := TEntityCoreMapper.GetTableName(AModel);
  var LPropertyList := TEntityCoreMapper.GetProperties(AModel);
  var LFieldList    := '';
  var LParamList    := '';

  for var LProperty in LPropertyList do
  begin
    if LProperty.IsAutoIncrement or LProperty.IsIdentity then
    begin
      Continue;
    end;

    if LFieldList.Trim.IsEmpty then
    begin
      LFieldList := LProperty.Name;
      LParamList := ':' + LProperty.Name;
    end
    else
    begin
      LParamList := LParamList + ',:' + LProperty.Name;
      LFieldList := LFieldList + ',' + LProperty.Name;
    end;
  end;

  Result := Format(TEntityCoreConstant.cInsertSQLNoReturn,
                   [LTableName,
                    LFieldList,
                    LParamList]);
end;

class function TEntityCoreFactory.RecordUpdate(const AModel: TEntityCoreModel): TRecordScript;
begin
  var LPrimaryKey := TEntityCoreMapper.GetPrimaryKey(AModel.ClassType);
  var LProperties := TEntityCoreMapper.GetProperties(AModel.ClassType);
  var LFields     := String.Empty;

  if LProperties <> nil then
  begin
    for var LProperty in LProperties do
    begin
      if LProperty.IsPrimaryKey or LProperty.IsNull(AModel) then
        Continue;

      LFields := Concat(LFields,
                        ',',
                        LProperty.Name,
                        ' = :',
                        LProperty.Name);

      Insert(LProperty.Value(AModel).AsVariant,
             Result.ArrayParams,
             Length(Result.ArrayParams));
    end;

    LFields := LFields.Remove(0, 1);

    Insert(LPrimaryKey.Value(AModel).AsVariant,
           Result.ArrayParams,
           Length(Result.ArrayParams));

    Result.Update := Format(TEntityCoreConstant.cUpdate,
                          [TEntityCoreMapper.GetTableName(AModel.ClassType),
                           LFields,
                           Concat(LPrimaryKey.Name,
                                  ' = :',
                                  LPrimaryKey.Name)]);
  end;
end;

class function TEntityCoreFactory.GetTypeInteger: String;
begin
  if Connection.IsSQLite or Connection.IsFirebird then
  begin
    Result := ' integer ';
  end
  else if Connection.IsSQLServer then
  begin
    Result := ' Int ';
  end;
end;

{ TEntityCoreFactory.TRecordInsert }

function TEntityCoreFactory.TRecordScript.GetParams: TParams;
begin
  if FParams = nil then
    FParams := TParams.Create(nil);

  Result := FParams;
end;

end.
