unit Custom.Entity.Core.JSON;

interface

uses
  System.JSON, Custom.Entity.Core.Model, System.SysUtils, System.Rtti,
  System.TypInfo, Custom.Entity.Core.Types, Custom.Entity.Core.Attributes,
  System.Variants, System.Generics.Collections;

type
  TEntityCoreJSON = class
  private
    class procedure CreateObject(var AResult: TObject; const AClass: TEntityCoreModelClass);
  public
    class function JsonToObject<T: TEntityCoreModel>(const AJSONValue: TJSONValue): T; overload;
    class procedure JsonToObject(const AClass: TEntityCoreModelClass; const AJSONValue: TJSONObject; const APropertyName: String; var AResult: TObject); overload;
    class procedure JsonToObject(const AClass: TEntityCoreModelClass; const AJSONValue: TJSONArray; const APropertyName: String; var AResult: TObject); overload;
    class function ToJsonObject(AObject: TObject): TJsonObject;
    class function ToJsonArray(const AObjectList: TObjectList<TObject>): TJsonArray; overload; static;
    class function ToJsonArray<T: class>(const AObjectList: TObjectList<T>): TJsonArray; overload; static;
  end;

implementation


{ TEntityJSON }

uses Custom.Entity.Core.Mapper, System.StrUtils, Custom.Entity.Core.Server.Helper;

class procedure TEntityCoreJSON.CreateObject(var AResult: TObject; const AClass: TEntityCoreModelClass);
begin
  if AResult = nil then
    AResult := TEntityCoreMapper
                         .GetMethod(AClass, 'Create')
                         .Invoke(AClass, [])
                         .AsObject;
end;

class procedure TEntityCoreJSON.JsonToObject(const AClass: TEntityCoreModelClass; const AJSONValue: TJSONObject; const APropertyName: String; var AResult: TObject);
begin
  if AJSONValue.Null then
  begin
    Exit;
  end;

  CreateObject(AResult, AClass);

  for var LJSONPair in AJSONValue do
  begin
    var LProperty := TEntityCoreMapper.GetProperty(AClass,
                                                   LJSONPair.JsonString.Value);

    if LProperty = nil then
      raise Exception.Create('Não foi encontrado o field ' + LJsonPair.JsonString.Value + ' na classe ' +
                             AClass.ClassName);

    if not LJSONPair.JsonValue.Null then
    begin
      if LProperty.PropertyType.IsInstance then
      begin
        var LObject := LProperty.GetValue(AResult).AsObject;

        if LJSONPair.JsonValue is TJSONObject then
        begin
          JsonToObject(TEntityCoreModelClass(LProperty.PropertyType.AsInstance.MetaclassType),
                       LJSONPair.JsonValue.AsType<TJSONObject>,
                       LProperty.Name,
                       LObject);
        end
        else if LJSONPair.JsonValue is TJSONArray then
        begin
          JsonToObject(TEntityCoreModelClass(LProperty.PropertyType.AsInstance.MetaclassType),
                       LJSONPair.JsonValue.AsType<TJSONArray>,
                       LProperty.Name,
                       LObject);
        end;
      end
      else if LProperty.IsWritable then
      begin
         try
           LProperty.FromJSON(AResult, LJSONPair.JsonValue);
         except
           on E: Exception do
           begin
             var LType := LProperty.TypeKindName(AResult);

             raise Exception.Create('O atributo ' + LProperty.Name + ' do objeto ' + APropertyName +
               ' é do tipo ' + LType + ' e o valor ' + LJSONPair.JsonValue.ToJSON + ' não é do tipo ' + LType);
           end;
         end;
      end;
    end;
  end;
end;

class procedure TEntityCoreJSON.JsonToObject(const AClass: TEntityCoreModelClass; const AJSONValue: TJSONArray; const APropertyName: String;
  var AResult: TObject);
begin
  var LMethod: TRttiMethod           := nil;
  var LClass : TEntityCoreModelClass := nil;

  if AJSONValue = nil then
  begin
    Exit;
  end;

  CreateObject(AResult, AClass);

  if AResult.ClassName.Contains('TObjectList') then
  begin
    LMethod := TEntityCoreMapper
                         .GetType(AResult.ClassType)
                         .GetMethod('Add');

    LClass := TEntityCoreModelClass(LMethod.GetParameters[0].ParamType.AsInstance.MetaclassType);
  end;

  for var LJsonObject in AJSONValue do
  begin
    var LItem := TEntityCoreMapper
                             .GetType(LClass)
                             .GetMethod('Create')
                             .Invoke(LClass, [])
                             .AsObject;

    JsonToObject(LClass, LJsonObject.AsType<TJSONObject>, APropertyName, LItem);

    LMethod.Invoke(AResult, [LItem]);
  end;
end;

class function TEntityCoreJSON.JsonToObject<T>(const AJSONValue: TJSONValue): T;
begin
  var LObject: TObject := nil;

  if AJSONValue is TJSONObject then
  begin
    JsonToObject(T, AJSONValue.AsType<TJSONObject>, '', LObject);
  end
  else
  begin
    JsonToObject(T, AJSONValue.AsType<TJSONArray>, '', LObject);
  end;

  Result := LObject as T;
end;

class function TEntityCoreJSON.ToJsonObject(AObject: TObject): TJsonObject;
begin
  if (AObject = nil) then
  begin
    Exit(TJSONObject(TJSONNull.Create));
  end;

  Result := TJSONObject.Create;

  var LProperties := TEntityCoreMapper.GetProperties(AObject.ClassType);

  for var LProperty in LProperties do
  begin
    if not LProperty.IsIgnore then
    begin
      Result.AddPair(LProperty.ToPair(AObject));
    end;
  end;
end;

class function TEntityCoreJSON.ToJsonArray(const AObjectList: TObjectList<TObject>): TJsonArray;
begin
  Result := ToJsonArray<TObject>(AObjectList);
end;

class function TEntityCoreJSON.ToJsonArray<T>(const AObjectList: TObjectList<T>): TJsonArray;
begin
  if AObjectList = nil then
  begin
    Exit(nil);
  end;

  Result := TJSONArray.Create;

  for var LObject in AObjectList do
  begin
    Result.Add(ToJsonObject(LObject));
  end;

  AObjectList.Free
end;

end.
