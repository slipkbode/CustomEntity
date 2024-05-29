unit Custom.Entity.Core.Linq;

interface

uses
  System.TypInfo,
  Custom.Entity.Core.Types,
  Custom.Entity.Core.Linq.Constant,
  Data.DB,
  System.Generics.Collections,
  System.Variants,
  System.Rtti,
  Custom.Entity.Core.Attributes,
  Custom.Entity.Core.Model,
  Custom.Entity.Core.Connection;

type
  IQueryableResult = interface
    ['{FD117AF6-E5EC-4E27-ABDA-6A2AB78E6525}']
  end;

  TQueryableResult = class(TInterfacedObject, IQueryableResult)
  private
    FContext: String;
    FDataSet: TDataSet;
    FParams : TParams;
    function GetDataSet: TDataSet;

    property DataSet: TDataSet read GetDataSet;

    function Bind<T: class>: T; overload;
    procedure Execute(const ASQLJson: Boolean); overload;
  public
    function &To<T: class>: T; overload;
    function &To: Variant; overload;
    function List<T: class>: TObjectList<T>; overload;
    function List: TList<Variant>; overload;
    function IsEmpty: Boolean;

    constructor Create(const AContext: String; const AParams: TParams); reintroduce;
    destructor Destroy; override;
  end;

  IQueryAbleOrder = interface
    ['{74CD22F7-6B77-45E1-9FA5-A42E8A79DC1F}']
    function OrderBy(const AArgs: TArray<String>): IQueryableOrder; overload;
    function OrderBy(const AArgs: String): IQueryableOrder; overload;
    function GroupBy(const AArgs: TArray<String>): IQueryableOrder; overload;
    function GroupBy(const AArgs: String): IQueryableOrder; overload;
    function GetContext: String;
    function First: TQueryableResult; overload;
    function First(const AParams: TParams): TQueryableResult; overload;
    function FirstOrDefault: TQueryableResult;
    function All: TQueryableResult;
  end;

  IQueryAbleSelect = interface(IQueryableOrder)
    ['{27AA8864-39C9-4E4F-B7D2-3EB1225440DE}']
    function Select: IQueryAbleSelect; overload;
    function Select(const AArgs: TArray<String>): IQueryAbleSelect; overload;
    function Select(const AArgs: String): IQueryAbleSelect; overload;
  end;

  IQueryAbleWhere = interface(IQueryAbleSelect)
    ['{5AFFD435-87F8-491F-A525-78337A1747A7}']
    function &And(const AArgs: Nullable<Boolean>): IQueryAbleSelect; overload;
    function &And(const AArgs: String): IQueryAbleSelect; overload;
    function &Or(const AArgs: Nullable<Boolean>): IQueryAbleSelect; overload;
    function &Or(const AArgs: String): IQueryAbleSelect; overload;
  end;

  IQueryAble = interface(IQueryAbleSelect)
    ['{E9DE560D-76F6-4656-897F-D30DCCE7A858}']
    function Where(const AArgs: Nullable<Boolean>): IQueryAbleWhere; overload;
    function Where(const AArgs: String): IQueryAbleWhere; overload;
    function Join(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble; overload;
    function Join(const AArgs: String): IQueryAble; overload;
    function LeftJoin(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble; overload;
    function LeftJoin(const AArgs: String): IQueryAble; overload;
    function All: TQueryableResult;
  end;

  TQueryAble = class(TInterfacedObject, IQueryAble, IQueryAbleSelect, IQueryableOrder, IQueryAbleWhere)
  private
    FWhere  : String;
    FFrom   : String;
    FJoin   : String;
    FSelect : String;
    FOrderBy: String;
    FGroupBy: String;
    FClass  : TClass;
    FResult : IQueryableResult;
  public
    function Where(const AArgs: Nullable<Boolean>): IQueryAbleWhere; overload;
    function Where(const AArgs: String): IQueryAbleWhere; overload;
    function &And(const AArgs: Nullable<Boolean>): IQueryAbleSelect; overload;
    function &And(const AArgs: String): IQueryAbleSelect; overload;
    function &Or(const AArgs: Nullable<Boolean>): IQueryAbleSelect; overload;
    function &Or(const AArgs: String): IQueryAbleSelect; overload;
    function Join(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble; overload;
    function Join(const AArgs: String): IQueryAble; overload;
    function LeftJoin(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble; overload;
    function LeftJoin(const AArgs: String): IQueryAble; overload;
    function Select: IQueryAbleSelect; overload;
    function Select(const AArgs: TArray<String>): IQueryAbleSelect; overload;
    function Select(const AArgs: String): IQueryAbleSelect; overload;
    function OrderBy(const AArgs: TArray<String>): IQueryableOrder; overload;
    function OrderBy(const AArgs: String): IQueryableOrder; overload;
    function GroupBy(const AArgs: TArray<String>): IQueryableOrder; overload;
    function GroupBy(const AArgs: String): IQueryableOrder; overload;
    function GetContext: String;
    function GetFields(const AArgs: Tarray<String>): String;
    function First: TQueryableResult; overload;
    function First(const AParams: TParams): TQueryableResult; overload;
    function FirstOrDefault: TQueryableResult;
    function All: TQueryableResult;
  public
    constructor Create(const AClass: TClass); virtual;
  end;

  function From(const AClass: TEntityCoreModelClass): IQueryAble; overload;

implementation

uses
  System.SysUtils,
  Custom.Entity.Core.Mapper,
  Custom.Entity.Core.Linq.Helper,
  Custom.Entity.Core;

function From(const AClass: TEntityCoreModelClass): IQueryAble; overload;
begin
  Result := TQueryAble.Create(AClass);
end;

{ TIQueryAble<T> }

function TQueryAble.&And(const AArgs: Nullable<Boolean>): IQueryAbleSelect;
begin
  Result := &And(AArgs.Expression);
end;

constructor TQueryAble.Create(const AClass: TClass);
begin
  inherited Create;
  FClass  := AClass;
  FFrom   := Format(TEntityLinqConstat.cFrom,
                    [TEntityCoreMapper
                                 .GetAttribute<TableName>(AClass)
                                 .Value
                                 .AsString]);

  FSelect := TEntityLinqConstat.cSelectAll;
end;

function TQueryAble.All: TQueryableResult;
begin
  FResult := TQueryableResult.Create(GetContext, nil);
  Result := TQueryableResult(FResult);
end;

function TQueryAble.&And(const AArgs: String): IQueryAbleSelect;
begin
  Result := Self;
  FWhere := FWhere + Format(TEntityLinqConstat.cAnd, [AArgs]);
end;

function TQueryAble.&Or(const AArgs: Nullable<Boolean>): IQueryAbleSelect;
begin

end;

function TQueryAble.&Or(const AArgs: String): IQueryAbleSelect;
begin

end;

function TQueryAble.GetContext: String;
begin
  Result := FSelect + FFrom + FJoin + FWhere + FGroupBy + FOrderBy;
end;


function TQueryAble.First: TQueryableResult;
begin
  Result := Self.All;
end;

function TQueryAble.First(const AParams: TParams): TQueryableResult;
begin
  FResult := TQueryableResult.Create(GetContext, AParams);
  Result := TQueryableResult(FResult);
end;

function TQueryAble.FirstOrDefault: TQueryableResult;
begin
  Result := First;
end;

function TQueryAble.Where(const AArgs: Nullable<Boolean>): IQueryAbleWhere;
begin
  Result := Where(AArgs.Expression);
end;

function TQueryAble.Join(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble;
begin
  Result := Join(Format(TEntityLinqConstat.cJoin,
                        [TEntityCoreMapper
                                     .GetAttribute<TableName>(AClass)
                                     .Value
                                     .AsString,
                        AArgs.Expression]));
end;

function TQueryAble.Join(const AArgs: String): IQueryAble;
begin
  Result := Self;
  FJoin := FJoin + AArgs;
end;

function TQueryAble.LeftJoin(const AArgs: String): IQueryAble;
begin
  Result := Self;
  FJoin := FJoin + AArgs;
end;

function TQueryAble.OrderBy(const AArgs: String): IQueryableOrder;
begin
  Result := Self;
  FOrderBy := Format(TEntityLinqConstat.cOrderBy, [AArgs]);
end;

function TQueryAble.OrderBy(const AArgs: TArray<String>): IQueryableOrder;
begin
  Result := OrderBy(GetFields(AArgs));
end;

function TQueryAble.Select(const AArgs: Tarray<String>): IQueryAbleSelect;
begin
  Result := Select(GetFields(AArgs));
end;

function TQueryAble.GetFields(const AArgs: Tarray<String>): String;
begin
  if AArgs = nil then
  begin
    raise Exception.Create('Informe o campos para executar o comando.');
  end;

  for var LField in AArgs do
  begin
    Result := Result + LField + ', ';
  end;

  Result := Result.Remove(Result.LastIndexOf(','));
end;

function TQueryAble.GroupBy(const AArgs: String): IQueryableOrder;
begin
  Result   := Self;
  FGroupBy := Format(TEntityLinqConstat.cOrderBy, [AArgs]);
end;

function TQueryAble.GroupBy(const AArgs: TArray<String>): IQueryableOrder;
begin
  Result := GroupBy(GetFields(AArgs));
end;

function TQueryAble.Select: IQueryAbleSelect;
begin
  Result  := Self;
  FSelect := TEntityLinqConstat.cSelectAll;
end;

function TQueryAble.LeftJoin(const AClass: TClass; const AArgs: Nullable<Boolean>): IQueryAble;
begin
  Result := LeftJoin(Format(TEntityLinqConstat.cLeftJoin,
                            [TEntityCoreMapper
                                        .GetAttribute<TableName>(AClass)
                                        .Value
                                        .AsString,
                             AArgs.Expression]));
end;

function TQueryAble.Where(const AArgs: String): IQueryAbleWhere;
begin
  Result := Self;
  FWhere := Format(TEntityLinqConstat.cWhere, [AArgs]);
end;

function TQueryAble.Select(const AArgs: String): IQueryAbleSelect;
begin
  Result  := Self;
  FSelect := Format(TEntityLinqConstat.cSelect, [AArgs]);
end;

{ TQueryableResult }

function TQueryableResult.&To: Variant;
begin
  Result := Null;

  try
    Result := FDataSet.CurrentRec;
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
end;

function TQueryableResult.Bind<T>: T;
begin
  Result := TEntityCoreMapper
                       .GetMethod<T>('Create')
                       .Invoke(T, [])
                       .AsType<T>;

  for var LField in FDataSet.Fields do
  begin
    if LField.IsNull then
    begin
      Continue;
    end;

    var LProperty := TEntityCoreMapper.GetProperty<T>(LField.FieldName);

    if LProperty <> nil then
    begin
      LProperty.SetValue(TObject(Result), LField.ToValue);
    end;
  end;
end;

constructor TQueryableResult.Create(const AContext: String; const AParams: TParams);
begin
  inherited Create;
  FContext := AContext;
  FParams  := AParams;
end;

destructor TQueryableResult.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

procedure TQueryableResult.Execute(const ASQLJson: Boolean);
begin
  if ASQLJson and TEntity.Connection.SupportedJson then
  begin
    FContext := Format(TEntityLinqConstat.cSelectJson, [FContext]);
  end;

  TEntity.Connection.ExecSQL(FContext, FParams, FDataSet);

  FDataSet.DisableControls;
end;

function TQueryableResult.GetDataSet: TDataSet;
begin
  if FDataSet = nil then
  begin
    Execute(False);
  end;

  Result := FDataSet;
end;

function TQueryableResult.IsEmpty: Boolean;
begin
  Result := DataSet.IsEmpty;
end;

function TQueryableResult.List: TList<Variant>;
begin
  try
    if DataSet.IsEmpty then
    begin
      Exit(nil);
    end;

    Result := TList<Variant>.Create;
    Result.Add(FDataSet.GetEnumerator.Current);
    while not DataSet.GetEnumerator.MoveNext do
    begin
      Result.Add(FDataSet.GetEnumerator.Current);
    end;
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
end;

function TQueryableResult.List<T>: TObjectList<T>;
begin
  Result := nil;

  if not DataSet.IsEmpty then
  begin
    Result := TObjectList<T>.Create;
    try
      while not FDataSet.Eof do
      begin
        Result.Add(Bind<T>);
        FDataSet.Next;
      end;
    except
      on E: Exception do
      begin
        Result.Free;
        raise;
      end;
    end;
  end;
end;

function TQueryableResult.&To<T>: T;
begin
  Result := nil;

  try
    if not DataSet.IsEmpty then
    begin
      Result := Bind<T>;
    end;
  except
    raise;
  end;
end;

end.
