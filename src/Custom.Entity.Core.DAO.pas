unit Custom.Entity.Core.DAO;

interface

uses Custom.Entity.Core.Model, System.Generics.Collections, Custom.Entity.Core.Types, Data.DB, Custom.Entity.Core.DBContext,
  System.Rtti, Custom.Entity.Core.Enum;

type
  IEntityCoreDAO = interface
    ['{65B27532-ACA4-44FB-A594-06FE7714A039}']
  end;

  TEntityCoreDAO = class(TInterfacedObject, IEntityCoreDAO)

  end;

  IEntityCoreDAO<T: TEntityCoreModel> = interface(IEntityCoreDAO)
    ['{F99936DF-A9A5-43D1-9C4F-EAB2496E92B3}']
    function Get: TObjectList<T>; overload;
    function Get(const AParams: TArray<TPair<String, String>>): TObjectList<T>; overload;
    procedure Post(const AEntityModel: T);
    procedure Put(const AEntityModel: T);
    procedure Delete(const AEntityModel: T);
  end;

  TEntityCoreDAO<T: TEntityCoreModel> = class(TEntityCoreDAO, IEntityCoreDAO<T>)
  strict private
    FDBSet: IEntityCoreDBSet<T>;
    function GetParams(const AParams: TArray<TPair<String, String>>): TParams;
  private
    procedure ValidateDBSet;
  public
    function Get: TObjectList<T>; overload;
    function Get(const AParams: TArray<TPair<String, String>>): TObjectList<T>; overload;
    procedure Post(const AEntityModel: T);
    function GetSequencePrimaryKey(const AField: TRttiProperty): Int64;

    procedure Put(const AEntityModel: T);
    procedure Delete(const AEntityModel: T);

    class function ModelClass: TClass;
    constructor Create; virtual;
  end;

implementation

uses Custom.Entity.Core.Linq, Custom.Entity.Core.Mapper, System.SysUtils, Custom.Entity.Core.Constant,
     Horse;

{ TEntityCoreDAO<T, I> }

function TEntityCoreDAO<T>.Get: TObjectList<T>;
begin
  try
    Result := From(T)
                  .All
                  .List<T>;
  except
    on E: EHorseException do
    begin
      raise;
    end;
    on E: Exception do
    begin
      raise EHorseException
                       .New
                       .Title('Erro ao efetuar o Get!')
                       .Status(THTTPStatus.BadRequest)
                       .Error(E.Message)
                       .&Type(TMessageType.Error)
                       .Detail('Erro ao retorno o json com os registros do get')
                       .&Unit(UnitName)
                       .Code(004)
                       .Hint('método Get');
    end;
  end;
end;

constructor TEntityCoreDAO<T>.Create;
begin
  inherited;
  if DBContext <> nil then
  begin
    FDBSet := DBContext
                   .GetDBSetByModel(T)
                   .AsType<IEntityCoreDBSet<T>>;

  end;
end;

procedure TEntityCoreDAO<T>.Delete(const AEntityModel: T);
begin

end;

function TEntityCoreDAO<T>.Get(const AParams: TArray<TPair<String, String>>): TObjectList<T>;
begin
  var LQueryAble := From(T);
  var LQueryAbleWhere: IQueryAbleWhere;

  try
    for var LParam in AParams do
    begin
      if LQueryAbleWhere = nil then
        LQueryAbleWhere := LQueryAble.Where(LParam.Key +'=:' + LParam.Key)
      else
        LQueryAbleWhere.&And(LParam.Key +'=:' + LParam.Key);
    end;
    Result := LQueryAbleWhere
                         .First(GetParams(AParams))
                         .List<T>;
  except
    on E: Exception do
    begin
      raise EHorseException
                       .New
                       .Title('Erro ao efetuar o Get!')
                       .Status(THTTPStatus.BadRequest)
                       .Error(E.Message)
                       .&Type(TMessageType.Error)
                       .Detail('Erro ao retorno o json com os registros do get')
                       .&Unit(UnitName)
                       .Code(009)
                       .Hint('método Get');
    end;
  end;
end;

function TEntityCoreDAO<T>.GetParams(const AParams: TArray<TPair<String, String>>): TParams;
begin
  Result := TParams.Create(nil);

  for var LParam in AParams do
  begin
    var LAddParam := Result.AddParameter;
    LAddParam.Value := LParam.Value;
    LAddParam.Name := LParam.Key;
  end;
end;

function TEntityCoreDAO<T>.GetSequencePrimaryKey(const AField: TRttiProperty): Int64;
begin
  Result := DBContext
                 .Connection
                 .ExecSQLScalar(Format(TEntityCoreConstant.cSelectMax,
                                       [AField.Name,
                                        TEntityCoreMapper.GetTableName(T)]));
end;

class function TEntityCoreDAO<T>.ModelClass: TClass;
begin
  Result := T;
end;

procedure TEntityCoreDAO<T>.Post(const AEntityModel: T);
begin
  FDBSet.Add(AEntityModel);
  DBContext.SaveChanges;
end;

procedure TEntityCoreDAO<T>.Put(const AEntityModel: T);
begin
  ValidateDBSet;
  FDBSet.Update(AEntityModel);
  DBContext.SaveChanges;
end;

procedure TEntityCoreDAO<T>.ValidateDBSet;
begin
  if FDBSet = nil then
  begin
    raise EHorseException
                      .New
                      .Title('DBSet não existe')
                      .Error('O DBSet para a classe ' + T.ClassName + ' não está declarada.')
                      .&Type(TMessageType.Error)
                      .Status(THTTPStatus.NotAcceptable)
                      .Code(010)
                      .Detail('Para resolver o problema faça da declaração da propriedade ' + T.ClassName + ' no seu DBContext')
                      .&Unit(Self.UnitName);
  end;
end;

end.
