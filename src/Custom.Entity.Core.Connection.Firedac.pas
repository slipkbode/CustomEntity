unit Custom.Entity.Core.Connection.Firedac;

interface

uses Custom.Entity.Core.Connection, Firedac.Comp.Client, System.Generics.Collections, Data.DB,
  FireDAC.Stan.Param, System.Classes, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Phys.SQLite,
  FireDAC.Phys.MSSQL, FireDAC.Phys.FB, FireDAC.Phys.Oracle, FireDAC.Phys.PG,
  Horse;

type
  TEntityCoreConnectionFiredac = class(TEntityCoreConnection<TFDConnection>, IEntityCoreConnection)
  private
    function ExecSQL(const ASQL: String; const AParams: TParams; var ADataSet: TDataSet): Integer; overload;
    function ExecSQL(const ASQL: String; var ADataSet: TDataSet): Integer; overload;
    function ExecSQL(const ASQL: String): Integer; overload;
    function ExecSQL(const ASQL: String; const AParams: TArray<Variant>): Integer; overload;
    function ExecSQLScalar(const ASQL: String; const AParams: TArray<Variant>): Integer; overload;
    function ExecSQLScalar(const ASQL: String): Integer; overload;
    function BeginTransaction: Integer;
    function GetDefaultConfiguration: String;
    function IsFirebird: Boolean;
    function IsSQLite: Boolean;
    function IsSQLServer: Boolean;

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

  public
    constructor Create;
  end;

implementation

uses
  System.Variants, System.SysUtils;

{ TEntityConnectionFiredac }

function TEntityCoreConnectionFiredac.BeginTransaction: Integer;
begin
  if not Connection.InTransaction then
  begin
    Connection.StartTransaction;
  end;

  Result := Connection.InTransaction.ToInteger;
end;

procedure TEntityCoreConnectionFiredac.CommitTransaction;
begin
  if Connection.InTransaction then
  begin
    Connection.Commit;
  end;
end;

constructor TEntityCoreConnectionFiredac.Create;
begin
  inherited;
  Connection.LoginPrompt                 := False;
  Connection.UpdateOptions.FastUpdates   := True;
  Connection.FetchOptions.Unidirectional := True;
  Connection.FetchOptions.AutoClose      := True;
  Connection.FetchOptions.RowsetSize     := 50;
  Connection.ConnectedStoredUsage        := [];
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: string): Integer;
begin
  Result := Connection
                  .ExecSQL(ASQL);
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: String; var ADataSet: TDataSet): Integer;
begin
  Result := Connection
                  .ExecSQL(ASQL, ADataSet);
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: String; const AParams: TParams; var ADataSet: TDataSet): Integer;
begin
  try
    Result := Connection.ExecSQL(ASQL,
                                 TFDParams(AParams),
                                 ADataSet);
  except
    raise;
  end;
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: String; const AParams: TArray<Variant>): Integer;
begin
  Result := Connection.
                   ExecSQL(ASQL, AParams);
end;

function TEntityCoreConnectionFiredac.ExecSQLScalar(const ASQL: String): Integer;
begin
  Result := Connection.ExecSQLScalar(ASQL);
end;

function TEntityCoreConnectionFiredac.ExecSQLScalar(const ASQL: String;
  const AParams: TArray<Variant>): Integer;
begin
  Result := Connection.ExecSQLScalar(ASQL, AParams);
end;

function TEntityCoreConnectionFiredac.GetDefaultConfiguration: String;
begin
  Result := Concat('DriverID=%s', #13,
                   'Server=%s', #13,
                   'User_Name=%s', #13,
                   'Password=%s', #13);
end;

function TEntityCoreConnectionFiredac.IsFirebird: Boolean;
begin
  Result := Connection
                 .DriverName
                 .Equals('FB');
end;

function TEntityCoreConnectionFiredac.IsSQLite: Boolean;
begin
  Result := Connection
                 .DriverName
                 .Equals('SQLite');
end;

function TEntityCoreConnectionFiredac.IsSQLServer: Boolean;
begin
  Result := Connection
                 .DriverName
                 .Equals('MSSQL');
end;

procedure TEntityCoreConnectionFiredac.LoadFromFile(const AFileName: String);
begin
  Connection
        .Params
        .LoadFromFile(AFileName);
end;

procedure TEntityCoreConnectionFiredac.Open;
begin
  Connection.Open;
end;

procedure TEntityCoreConnectionFiredac.RollbackTransaction;
begin
  if Connection.InTransaction then
  begin
    Connection.Rollback;
  end;
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer: String);
begin
  SetConfiguration(ADriverID, AServer, '', '');
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName: String);
begin
  try
    Connection.Close;
    Connection.Params.Database := ADatabaseName;
    Connection.Open;
    Connection.Close;
  except
    on E: Exception do
    begin
      raise EHorseException
                      .New
                      .Title('Nome do banco de dados')
                      .Error(E.Message)
                      .Status(THTTPStatus.InternalServerError)
                      .&Type(TMessageType.Error)
                      .Code(006)
                      .&Unit(UnitName)
                      .Hint('Line 116')
                      .Detail('Verificar com o suporte técnico sobre a mensagem de erro apresentada');
    end;
  end;
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer, AUserName, APassword: String);
begin
  SetConfiguration(ADriverID, AServer, AUserName, APassword, 0);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer, AUserName, APassword: String; APort: Integer);
begin
  SetConfiguration('', ADriverID, AServer, AUserName, APassword, APort);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String);
begin
  SetConfiguration(ADatabaseName, ADriverID, AServer, AUserName, APassword, 0);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String;
  APort: Integer);
begin
  try
    Connection.Close;
    Connection.Params.Database := ADatabaseName;
    Connection.Params.UserName := AUserName;
    Connection.Params.Password := APassword;
    Connection.DriverName      := ADriverID;
    Connection.Params.AddPair('Server', AServer);

    if APort > 0 then
    begin
      Connection.Params.AddPair('Port', APort.ToString);
    end;

    Connection.Open;
    Connection.Close;
  except
    on E: Exception do
    begin
      raise EHorseException
                      .New
                      .Title('Erro ao tentar configurar o banco de dados')
                      .Error(E.Message)
                      .Status(THTTPStatus.InternalServerError)
                      .&Type(TMessageType.Error)
                      .Code(007)
                      .&Unit(UnitName)
                      .Hint('Line 116')
                      .Detail('Verificar com o suporte técnico sobre a mensagem de erro apresentada');
    end;
  end;
end;

//function TEntityCoreConnectionFiredac.ExecSQLScalar(const ASQL: string; const AParams: TArray<Variant>; const AFieldType: TArray<TFieldType>): Variant;
//begin
//  Result := Connection
//                  .ExecSQLScalar(ASQL, AParams, AFieldType);
//end;

end.
