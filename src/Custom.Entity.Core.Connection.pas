unit Custom.Entity.Core.Connection;

interface

uses
  Data.DB, Horse, System.StrUtils, System.SysUtils,
  System.Generics.Collections, System.Rtti, Custom.Entity.Core.Model,
  Custom.Entity.Core.Types;

type
  IEntityCoreConnectionBase = interface(IInterface)
    ['{2F668401-B336-4A0A-B18D-A745A3E442AB}']
    function SupportedJson: Boolean;
    function TableExists(const ATableName: String): Boolean;
    function FieldExists(const ATableName, AFieldName: String): Boolean;
    function DatabaseExists(const ADatabaseName: String): Boolean;

    procedure InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
    procedure UpdateRecord(const AModel: TEntityCoreModel);
    procedure Close;
  end;

  IEntityCoreConnection = interface(IEntityCoreConnectionBase)
    ['{694B3615-98C3-47B8-BA64-6DB045791FDA}']
    function ExecSQL(const ASQL: String; const AParams: TParams; var ADataSet: TDataSet): Integer; overload;
    function ExecSQL(const ASQL: String; var ADataSet: TDataSet): Integer; overload;
    function ExecSQL(const ASQL: String): Integer; overload;
    function ExecSQL(const ASQL: String; const AParams: TArray<Variant>): Integer; overload;
    function ExecSQLScalar(const ASQL: String; const AParams: TArray<Variant>): Integer; overload;
    function ExecSQLScalar(const ASQL: String): Integer; overload;
    function IsFirebird: Boolean;
    function IsSQLite: Boolean;
    function IsSQLServer: Boolean;
    function BeginTransaction: Integer;
    function GetDefaultConfiguration: String;

    procedure CommitTransaction;
    procedure RollbackTransaction;
    procedure SetConfiguration(const ADatabaseName: String); overload;
    procedure SetConfiguration(const ADriverID, AServer: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure LoadFromFile(const AFileName: String);
    procedure Open;
  end;

  TEntityCoreConnection = class(TInterfacedObject)
  end;

  TEntityCoreConnection<T: TCustomConnection> = class(TEntityCoreConnection, IEntityCoreConnectionBase)
  strict private
    FConnection: T;
    FEntityConnection: IEntityCoreConnection;
  private
    function SupportedJson: Boolean;
    function GetConnection: T;
    function TableExists(const ATableName: String): Boolean;
    function DatabaseExists(const ADatabaseName: String): Boolean;
    function FieldExists(const ATableName, AFieldName: String): Boolean;

    procedure InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
    procedure UpdateRecord(const AModel: TEntityCoreModel);
    procedure Close;
  protected
    property Connection: T read GetConnection;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses Custom.Entity.Core.Mapper, Custom.Entity.Core.Server.Helper, Custom.Entity.Core.Constant,
  Custom.Entity.Core.Factory, System.TypInfo;

{ TEntityCoreConnection<T> }

procedure TEntityCoreConnection<T>.Close;
begin
  TEntityCoreMapper
         .GetMethod<T>('Close')
         .Invoke(TObject(Connection), []);
end;

constructor TEntityCoreConnection<T>.Create;
begin
  inherited;
  FEntityConnection := Self as IEntityCoreConnection;
end;

function TEntityCoreConnection<T>.DatabaseExists(const ADatabaseName: String): Boolean;
begin
  var LDatabaseExists := '';

  if FEntityConnection.IsSQLServer then
  begin
    LDatabaseExists := TEntityCoreConstant.cDatabaseExistsSQLServer;
  end;

  Result := FEntityConnection.ExecSQLScalar(LDatabaseExists, [ADatabaseName]) <> 0;
end;

destructor TEntityCoreConnection<T>.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TEntityCoreConnection<T>.FieldExists(const ATableName, AFieldName: String): Boolean;
begin
  var LFieldExists := '';

  try
    if FEntityConnection.IsFirebird then
    begin
      LFieldExists := TEntityCoreConstant.cFieldExistsFirebird;
    end
    else if FEntityConnection.IsSQLServer then
    begin
      LFieldExists := TEntityCoreConstant.cFieldExistsSQLServer;
    end;

    Result := FEntityConnection.ExecSQLScalar(LFieldExists, [ATableName.ToUpper, AFieldName.ToUpper]) <> 0;

  except
    on E: Exception do
    begin
      raise EHorseException
                         .New
                         .Error(E.Message)
                         .Title('Erro ao verificar campo')
                         .Status(THTTPStatus.InternalServerError)
                         .&Detail('Falha na execução do sql')
                         .&Unit(Self.UnitName)
                         .&Type(TMessageType.Error)
                         .Code(020);
    end;
  end;
end;

function TEntityCoreConnection<T>.GetConnection: T;
begin
  if FConnection = nil then
  begin
    FConnection := TEntityCoreMapper
                            .GetMethod<T>('Create')
                            .Invoke(T, [nil])
                            .AsType<T>;
  end;

  Result := FConnection;
end;

procedure TEntityCoreConnection<T>.InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
var
  LDataSet: TDataSet;
begin
  try
    try
      var LRecordInsert := TEntityCoreFactory.RecordInsert(AModel);

      FEntityConnection.ExecSQL(LRecordInsert.Insert, LRecordInsert.Params, LDataSet);

      AIdKey := LDataSet.Fields[0].AsVariant;
    except
      on E: Exception do
      begin
        raise EHorseException
                          .New
                          .Title('Ops... Algo de errado')
                          .Error('Erro ao gerar o script do registro da tabela ' + TEntityCoreMapper.GetTableName(AModel.ClassType))
                          .Detail(E.Message)
                          .Status(THTTPStatus.InternalServerError)
                          .&Type(TMessageType.Error)
                          .&Unit(Self.UnitName)
                          .Hint('Method InsertRecord')
                          .Code(022)
      end;
    end;
  finally
    LDataSet.Free;
  end;
end;

function TEntityCoreConnection<T>.SupportedJson: Boolean;
begin
  Result := False;
end;

function TEntityCoreConnection<T>.TableExists(const ATableName: String): Boolean;
begin

  var LTableExists := '';

  try
    if FEntityConnection.IsFirebird then
    begin
      LTableExists := TEntityCoreConstant.cTableExistsFirebird;
    end
    else if FEntityConnection.IsSQLServer then
    begin
       LTableExists := TEntityCoreConstant.cTableExistsSQLServer;
    end;

    Result := FEntityConnection.ExecSQLScalar(LTableExists,
                                                [ATableName.ToUpper]) <> 0;

  except 
    on E: Exception do
    begin
      raise EHorseException
                         .New
                         .Error(E.Message)
                         .Title('Erro ao verificar tabela')
                         .Status(THTTPStatus.InternalServerError)
                         .&Detail('Falha na execução do sql')
                         .&Unit(Self.UnitName)
                         .&Type(TMessageType.Error)
                         .Code(017);
    end;
  end;
end;

procedure TEntityCoreConnection<T>.UpdateRecord(const AModel: TEntityCoreModel);
begin
  try
    var LRecordUpdate := TEntityCoreFactory.RecordUpdate(AModel);

    if not LRecordUpdate.Update.Trim.IsEmpty then
    begin
      FEntityConnection.ExecSQL(LRecordUpdate.Update, LRecordUpdate.ArrayParams);
    end;
  except
    on E: Exception do
    begin
      raise EHorseException
                        .New
                        .Title('Ops... Algo de errado')
                        .Error('Erro ao gerar o script do registro da tabela ' + TEntityCoreMapper.GetTableName(AModel.ClassType))
                        .Detail(E.Message)
                        .Status(THTTPStatus.InternalServerError)
                        .&Type(TMessageType.Error)
                        .&Unit(Self.UnitName)
                        .Hint('Method UpdateRecord')
                        .Code(028)
    end;
  end;
end;

end.
