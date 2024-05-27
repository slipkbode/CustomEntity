unit Custom.Entity.Core.Mapper;

interface

uses
  System.Rtti, System.Generics.Collections, System.TypInfo, System.SysUtils,
  Custom.Entity.Core.Types;

type
  TEntityCoreMapper = class
  private
    class var FContext: TRttiContext;
    class var FTableList: TDictionary<TClass, String>;
  public
    class constructor Create;
    class destructor Destroy;

    class function GetType<T>: TRttiType; overload;
    class function GetType(const AClass: TClass): TRttiType; overload;
    class function GetType(const AClass: PTypeInfo): TRttiType; overload;
    class function GetMethod<T: class>(const AMethodName: String): TRttiMethod; overload;
    class function GetMethod(const AClass: TClass; const AMethodName: String): TRttiMethod; overload;
    class function GetMethod<T: class>(const AMethodName: String; const AParams: TArray<String>): TRttiMethod; overload;
    class function GetAttribute<T: class; A: TCustomAttribute>: A; overload;
    class function GetAttribute<A: TCustomAttribute>(const AClass: TClass): A; overload;
    class function GetAttribute<A: TCustomAttribute; R>(const AClass: TClass; var AResult: R): Boolean; overload;
    class function GetProperty<T>(const AProperty: String): TRttiProperty; overload;
    class function GetProperty(const AClass: TClass; const AProperty: String): TRttiProperty; overload;
    class function GetProperty(const AClass: PTypeInfo; const AProperty: String): TRttiProperty; overload;
    class function GetProperties(const AClass: TClass): TArray<TRttiProperty>; overload;
    class function GetProperties<T: class>: TArray<TRttiProperty>; overload;
    class function GetField<T>(const AField: String): TRttiField;
    class function GetFields(const AClass: TClass): TArray<TRttiField>;
    class function GetPrimaryKey(const AClass: TClass): TRttiProperty;
    class function GetPrimaryKeys(const AClass: TClass): TArrayProperties;
    class function GetTableName(const AClass: TClass): String;
  end;

implementation

uses Custom.Entity.Core.Attributes, Custom.Entity.Core.Server.Helper;

{ TEntityCoreMapper }

class constructor TEntityCoreMapper.Create;
begin
  FContext   := TRttiContext.Create;
  FTableList := TDictionary<TClass, String>.Create;
end;

class destructor TEntityCoreMapper.Destroy;
begin
  FContext.Free;
  FreeAndNil(FTableList);
end;

class function TEntityCoreMapper.GetAttribute<A>(const AClass: TClass): A;
begin
  Result := FContext
                .GetType(AClass)
                .GetAttribute<A>;
end;

class function TEntityCoreMapper.GetAttribute<T; A>: A;
begin
  Result := GetType<T>.GetAttribute<A>;
end;

class function TEntityCoreMapper.GetAttribute<A, R>(const AClass: TClass; var AResult: R): Boolean;
begin
  Result := False;

  var LAttribute := GetAttribute<A>(AClass);

  if LAttribute <> nil then
  begin
    AResult := TEntityCoreAttibute(LAttribute)
                                          .Value
                                          .AsType<R>;
    Result  := True;
  end;
end;

class function TEntityCoreMapper.GetField<T>(const AField: String): TRttiField;
begin
  Result := GetType<T>.GetField(AField);
end;

class function TEntityCoreMapper.GetFields(const AClass: TClass): TArray<TRttiField>;
begin
  Result := GetType(AClass).GetDeclaredFields;
end;

class function TEntityCoreMapper.GetMethod(const AClass: TClass; const AMethodName: String): TRttiMethod;
begin
  Result := GetType(AClass).GetMethod(AMethodName);
end;

class function TEntityCoreMapper.GetMethod<T>(const AMethodName: String; const AParams: TArray<String>): TRttiMethod;
begin
  Result := nil;

  var LMethods := GetType<T>.GetMethods(AMethodName);

  for var LMethod in LMethods do
  begin
    var LCountParameter := 0;

    if Length(LMethod.GetParameters) = Length(AParams) then
    begin
      for var LParam in AParams do
      begin
        for var LParameter in LMethod.GetParameters do
        begin
          if LParameter.Name.ToLower.Equals(LParam.ToLower) then
          begin
            Inc(LCountParameter);
          end;
        end;
        if LCountParameter = 0 then
        begin
          Break;
        end;
      end;

      if LCountParameter = Length(AParams) then
      begin
        Exit(LMethod);
      end;
    end;
  end;
end;

class function TEntityCoreMapper.GetMethod<T>(const AMethodName: String): TRttiMethod;
begin
  Result := GetMethod(T, AMethodName);
end;

class function TEntityCoreMapper.GetPrimaryKey(const AClass: TClass): TRttiProperty;
begin
  Result := nil;

  var LProperties := GetProperties(AClass);

  for var LProperty in LProperties do
  begin
    if LProperty.IsPrimaryKey then
    begin
      Exit(LProperty);
    end;
  end;
end;

class function TEntityCoreMapper.GetPrimaryKeys(const AClass: TClass): TArrayProperties;
begin
  Result := nil;

  var LProperties := GetProperties(AClass);

  for var LProperty in LProperties do
  begin
    if LProperty.IsPrimaryKey then
    begin
      Insert(LProperty, Result, Length(Result));
    end;
  end;
end;

class function TEntityCoreMapper.GetProperties(const AClass: TClass): TArray<TRttiProperty>;
begin
  Result := FContext
                .GetType(AClass)
                .GetDeclaredProperties;
end;

class function TEntityCoreMapper.GetProperties<T>: TArray<TRttiProperty>;
begin
  Result := GetProperties(T);
end;

class function TEntityCoreMapper.GetProperty(const AClass: TClass; const AProperty: String): TRttiProperty;
begin
  Result := GetType(AClass).GetProperty(AProperty);
end;

class function TEntityCoreMapper.GetProperty(const AClass: PTypeInfo; const AProperty: String): TRttiProperty;
begin
  Result := GetType(AClass).GetProperty(AProperty);
end;

class function TEntityCoreMapper.GetProperty<T>(const AProperty: String): TRttiProperty;
begin
  Result := GetProperty(TypeInfo(T), AProperty);
end;

class function TEntityCoreMapper.GetType(const AClass: TClass): TRttiType;
begin
  Result := FContext.GetType(AClass);
end;

class function TEntityCoreMapper.GetTableName(const AClass: TClass): String;
begin
  if not FTableList.TryGetValue(AClass, Result) then
  begin
    var LTableNane := AClass.ClassName.Remove(0, 1);
    var LAttribute := GetAttribute<TableName>(AClass);

    if LAttribute <> nil then
    begin
      Result := LAttribute.Value.AsString;
    end
    else
    begin
      Result := LTableNane;
    end;

    FTableList.Add(AClass, Result);
  end;
end;

class function TEntityCoreMapper.GetType(const AClass: PTypeInfo): TRttiType;
begin
  Result := FContext.GetType(AClass);
end;

class function TEntityCoreMapper.GetType<T>: TRttiType;
begin
  Result := GetType(TypeInfo(T));
end;

end.
